library(haven)
library(dplyr)

df <- read_sav("C:/Users/UwAngelique/Downloads/survey.sav")

df_clean <- df |>
  mutate(
    across(c(gender, education, satisfaction), as_factor),
    income = na_if(as.numeric(income), -99)
  )

df_clean |>
  group_by(gender) |>
  summarise(n = n(),
            mean_age = mean(age),
            mean_income = mean(income, na.rm = TRUE))
head(df_clean)
table(df_clean$gender)
summary(df_clean$income)

library(DBI)
library(dplyr)
library(dbplyr)

con <- dbConnect(
  RMariaDB::MariaDB(),
  host     = "localhost",
  port     = 3306,
  dbname   = "rdemo",
  user     = "root",
  password = "yego"
)

dbListTables(con)
dbWriteTable(con, "survey", as.data.frame(df_clean), overwrite = TRUE)

dbListTables(con)        #  "survey"
dbListFields(con, "survey")

dbGetQuery(con, "SELECT gender, COUNT(*) AS n, AVG(income) AS avg_income
                 FROM survey
                 GROUP BY gender")

dbGetQuery(con, "SELECT gender, COUNT(*) AS n, AVG(income) AS avg_income
                 FROM survey where education='Bachelor'
                 GROUP BY gender")

resp <- request("https://api.worldbank.org/v2/country/RW/indicator/SP.POP.TOTL") |>
  req_url_query(format = "json", per_page = 100) |>
  req_perform()

resp_status(resp)

body <- resp_body_json(resp)

library(purrr)
library(dplyr)

df_pop <- body[[2]] |>
  map_df(~ tibble(year = .x$date, population = .x$value))

head(df_pop)

df_pop <- df_pop |>
  mutate(year = as.numeric(year)) |>
  arrange(year)

head(df_pop)    # now starts at 1960
tail(df_pop)    # ends at 2025
nrow(df_pop)

df_pop <- df_pop |>
  mutate(growth_pct = (population / lag(population) - 1) * 100)

plot(df_pop$year, df_pop$population / 1e6, type = "l",
     xlab = "Year", ylab = "Population (millions)",
     main = "Rwanda population, 1960 to 2025",
     las = 1, lwd = 2, col = "steelblue")
grid()

df_pop |> filter(year %in% 1992:1998)

par(mar = c(5, 5, 4, 2))   # bottom, left, top, right

plot(df_pop$year, df_pop$population / 1e6, type = "l",
     xlab = "Year", ylab = "Population (millions)",
     main = "Rwanda population, 1960 to 2025",
     las = 1, lwd = 2, col = "steelblue")
grid()

text(1995, 5.7, "1994 genocide\nagainst the Tutsi", pos = 4, cex = 0.8)

dbWriteTable(con, "rwanda_pop", as.data.frame(df_pop), overwrite = TRUE)

dbGetQuery(con, "SELECT year, population FROM rwanda_pop
                 WHERE year >= 2020 ORDER BY year")

dbDisconnect(con)


