#Import data from statistical package and from database management system,API 
# STEP 1: INSTALL AND LOAD PACKAGES


# List of all packages used in this assignment
packages <- c(
  "haven",     # import SPSS (.sav) files and keep variable/value labels
  "dplyr",     # clean, filter and summarise data (mutate, group_by, summarise)
  "DBI",       # general interface to connect R to databases
  "RMariaDB",  # driver that connects R to a MySQL/MariaDB database
  "httr2",     # send requests to web APIs and read the responses
  "purrr"    # loop over lists and flatten nested JSON (map_df)
)

#  packages which are not yet installed on this computer
to_install <- packages[!packages %in% rownames(installed.packages())]

# Installing the missing ones
if (length(to_install) > 0) install.packages(to_install, type = "binary")

# Load all packages into this work for example same as library(haven)

invisible(lapply(packages, library, character.only = TRUE))

# to Check if everything is installed
packages[!packages %in% rownames(installed.packages())]

#library(haven)
#library(dplyr)

# STEP 2: IMPORT FROM A STATISTICAL PACKAGE (SPSS) with haven

df <- read_sav("survey.sav")
head(df)
nrow(df)      # number of  respondents

# STEP 3: CLEAN AND SUMMARISE with dplyr

sum(is.na(df$income))

# Rows that are NA after the default import
df[is.na(df$income), c("id", "income")]

df_raw <- read_sav("survey.sav", user_na = TRUE)
df_raw[df_raw$income %in% -99, c("id", "income")]

df_clean <- df |>
  mutate(
    across(c(gender, education, satisfaction), as_factor),
    income = na_if(as.numeric(income), -99)
  )
sum(is.na(df_clean$income))

# The Summary by gender
df_clean |>
  group_by(gender) |>
  summarise(n = n(),
            mean_age = mean(age),
            mean_income = mean(income, na.rm = TRUE))
head(df_clean)
table(df_clean$gender)
summary(df_clean$income)

#library(DBI)
#library(dplyr)
#library(dbplyr)
#library(httr2)

# STEP 4: DATABASE MANAGEMENT SYSTEM (MySQL) with DBI + RMariaDB

con <- dbConnect(
  RMariaDB::MariaDB(),
  host     = "localhost",
  port     = 3306,
  dbname   = "rdemo",
  user     = "root",
  password = "yego" # my localdb password
)

dbListTables(con)
# Write the cleaned survey data into db
dbWriteTable(con, "survey", as.data.frame(df_clean), overwrite = TRUE)

dbListTables(con)       
dbListFields(con, "survey")

# SQL query 1: income by gender

dbGetQuery(con, "SELECT gender, COUNT(*) AS n, AVG(income) AS avg_income
                 FROM survey
                 GROUP BY gender")

# SQL query 2: Bachelor-level respondents only

dbGetQuery(con, "SELECT gender, COUNT(*) AS n, AVG(income) AS avg_income
                 FROM survey where education='Bachelor'
                 GROUP BY gender")

#  import the table back from the database into R
dbIsValid(con)
df_from_db <- dbReadTable(con, "survey")
head(df_from_db)
#Confirming that the database copy matches the R copy
nrow(df_from_db)                                   # 50
sum(is.na(df_from_db$income))                      # 3
all.equal(mean(df_from_db$income, na.rm = TRUE),
          mean(df_clean$income, na.rm = TRUE))     # TRUE

# STEP 5: WEB API (World Bank) with httr2 + purrr
#Connect to the World Bank API forpopulation, Indicator SP.POP.TOTL = total population, country code RW = Rwanda

resp <- request("https://api.worldbank.org/v2/country/RW/indicator/SP.POP.TOTL") |>
  req_url_query(format = "json", per_page = 100) |>
  req_perform()

resp_status(resp)

body <- resp_body_json(resp)

#library(purrr)
#library(dplyr)

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



