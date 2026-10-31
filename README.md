Assignment 1: Importing Data in R from a Statistical Package, a Database and a Web API

**Student Name:** Uwibambe Angelique  
**Registration number:** 20252MBI056  
**Programme:** MSc in Big Data Analytics  
**Course:** R for Data Science (MSDA9113)  
**Instructor:** Dr. Pacifique Nizeyimana  
**University:** Adventist University of Central Africa (AUCA)



This project shows how R packages can import and process data from three different sources:

| Source | Type | Packages |
|---|---|---|
| `survey.sav` | Statistical package (SPSS) | `haven`, `dplyr` |
| MySQL database `rdemo` | Database management system | `DBI`, `RMariaDB` |
| World Bank API | Web API (external, open, no key needed) | `httr2`, `purrr` |

## What the script does

1. **Packages:** installs any missing packages and loads them.
2. **SPSS import:** reads `survey.sav` (50 respondents, 6 variables) with `haven`, keeping variable and value labels.
3. **Data cleaning:** the survey codes refused answers as `-99` in `income` and `satisfaction`. The script inspects them (`read_sav(..., user_na = TRUE)`), converts them to `NA`, turns labelled variables into factors and summarises income and age by gender.
4. **MySQL:** writes the cleaned data to a table, runs SQL queries (by gender, and Bachelor-level only), reads the table back and checks that the copy matches the data in R.
5. **API:** requests Rwanda's total population (1960 to 2025) from the World Bank API, converts the JSON response into a data frame, computes annual growth, plots it and stores it in MySQL.

## Project files

```
.
├── HW1.R         # main R script
├── survey.sav    # SPSS survey data (50 rows)
├── .gitignore    # files Git should not track
└── README.md
```


## Requirements

- R  and RStudio
- MySQL or MariaDB running on `localhost:3306`, with an empty database called `rdemo`
- Internet connection (for the World Bank API)
- R packages: `haven`, `dplyr`, `DBI`, `RMariaDB`, `httr2`, `purrr` (the script installs them automatically)

## How to run

1. Clone or download this repository.
2. Open `HW1.Rproj` in RStudio (this sets the working directory so that `survey.sav` is found), then open `HW1.R`.
3. Make sure MySQL is running and the database `rdemo` exists, and set your local db password:
   ```sql
   CREATE DATABASE rdemo;
   ```
4. Run the script from top to bottom.

## Key results

| Check | Result |
|---|---|
| Survey rows | 50 |
| Refused incomes (`-99` converted to `NA`) | 3 |
| Mean income, Male / Female | 1021 / 1192 |
| Database copy matches R data | yes (row count, missing values, mean income) |
| World Bank API status | 200, 66 years returned (1960 to 2025) |

## Notes

- The sample is small (50 respondents)
- Population figures are World Bank estimates.

## Author

Angelique Uwibambe
