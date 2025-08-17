# SQL Scripts for Data Analysis

These are SQL scripts to load, clean and explore dataset.

Using : 
- MySQL 8.0.43
- MySQL Workbench 8.0


## Customer Data Cleaning

```
1_customer_data_cleaning.sql
```

Data cleaning is the foundational step in any data analysis process. In this project, I cleaned customer data using SQL by removing duplicates, handling missing values, standardizing formats, and splitting columns for better usability.

#### BEFORE CLEANING
![Alt Text](img/customer_1.png)

#### AFTER CLEANING
![Alt Text](img/customer_2.png)

## World Life Expectancy

```
2_world_life_expectancy.sql
```

![Alt Text](img/world_life_expectancy.png)

This SQL script carries out data cleaning and Exploratory Data Analysis (EDA) on the world life expectancy data set. In the data cleaning process, duplicates are dropped and missing values are imputed from other entries. The findings from the EDA are :
- Haiti and Zimbabwe had the highest life expectancy increase in the last 15 years.
- The global average life expectancy is increasing each year.
- Richer countries have a higher life expectancy.
- Developed countries have a higher life expectancy than developing ones.
- A Higher BMI is positively correlated with a higher life expectancy.

## US Household Income
```
3_US_household_income.sql
```

In this project, I performed data cleaning on a dataset describing the household income in different US states and cities. I then analysed the data to find out that :
- Texas and California are the largest state by surface area.
- Michigan is the state with the largest water area.
- The 5 states with the lowest household income
- The top 10 states with the highest household income
- In the richer states, there are some very high earners in these states, the income is not distributed evenly.
- People living in municipalities tend to have a higher household income. 
- People living in urban or communities have a dramatically lower average income than the rest of the population.


