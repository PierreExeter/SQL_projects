#-----------------------
# CREATE DATABASE
#-----------------------

DROP DATABASE IF EXISTS `US_Household_Income`;
CREATE DATABASE `US_Household_Income`;
USE `US_Household_Income`;

#-----------------------
# IMPORT DATA
#-----------------------
# Go to Schemas tab > customers data base > Table > right click on World_Life_Expectancy 
# Select 'Table Data Importation Wizard'
# Select US_household_income.csv
# Repeat the steps to import US_household_income_statistics.csv

# Note that it's good practice to create a staging or back up table in case a mistake is made in the data cleaning process.

# Let's look at the data.
SELECT * 
FROM US_household_income;

SELECT * 
FROM US_household_income_statistics;


# Let's count how many records there are.
SELECT COUNT(id)
FROM US_household_income;

SELECT COUNT(id)
FROM US_household_income_statistics;

# About 200 records were lost in the importation
# of the US_household_income table. Let's ingnore this
# as most of the data was imported correctly (32,526 records in total).

#-----------------------
# DROP DUPLICATES
#-----------------------

# Let's find out if there are any duplicates. 
# Method 1: count how many id are repeated more than one
SELECT id, COUNT(id) 
FROM US_household_income
GROUP BY id
HAVING COUNT(id) > 1
;

# Method 2: Let's identify what the duplicates are by using a window function.
# Let's partition on concatenation and add a row number.
# Let's use a sub-query to filter records where this row number is > 1, 
# which identifies a duplicate.
SELECT *
FROM (
	SELECT row_id, id,
	ROW_NUMBER() OVER( PARTITION BY id ORDER BY id) as row_num
	FROM US_household_income
	) AS row_table
WHERE row_num > 1
;

# Delete the duplicates by filtering the row having row_num > 1 
DELETE FROM US_household_income
WHERE 
	row_id IN (
    SELECT row_id
FROM (
	SELECT row_id,
    id,
	ROW_NUMBER() OVER(PARTITION BY id ORDER BY id) as row_num
	FROM US_household_income
	) AS row_table
WHERE row_num > 1
)
;

# Let's find duplicates in the other table
SELECT id, COUNT(id) 
FROM US_household_income_statistics
GROUP BY id
HAVING COUNT(id) > 1
;

# There are no duplicates in the 2nd table.

#-----------------------
# DATA CLEANING
#-----------------------

# Let's look at the state name
SELECT DISTINCT State_name
FROM US_household_income
ORDER BY 1
;

# There is a spelling mistake : 'georia' should be spelt 'Georgia'

# Update the state name with the correct one.
UPDATE US_household_income
SET State_name = 'Georgia'
WHERE State_name = 'georia'
;

UPDATE US_household_income
SET State_name = 'Alabama'
WHERE State_name = 'alabama'
;

# Let's look at the Place column
SELECT *
FROM US_household_income
WHERE Place = ''
;

# There's only 1 missing Place : Autaugaville.
# Let's populate the missing place.
UPDATE US_household_income
SET Place = 'Autaugaville'
WHERE State_name = 'Autauga County'
AND City = 'Vinemont'
;

# Let's look at the Type column
SELECT Type, COUNT(Type) 
FROM US_household_income
GROUP BY Type
;

# There is a spelling mistake : 'Borough' should be 'Boroughs'. 
# Let's update this.
UPDATE US_household_income
SET Type = 'Borough'
WHERE Type = 'Boroughs'
;

# Check for blank, zeros or NULL values in the ALand and AWater columns
SELECT ALand, AWater 
FROM US_household_income
WHERE AWater = 0 OR AWater = '' OR AWater IS NULL
;
# Some counties are just land

SELECT ALand, AWater 
FROM US_household_income
WHERE ALand = 0 OR ALand = '' OR ALand IS NULL
;
# Some counties are just water

SELECT ALand, AWater 
FROM US_household_income
WHERE (AWater = 0 OR AWater = '' OR AWater IS NULL)
AND (ALand = 0 OR ALand = '' OR ALand IS NULL)
;
# But there are no counties without land and water at the same time
# This seems correct, so let's not do further cleaning on these columns

#-----------------------
# EXPLORATORY DATA ANALYSIS
#-----------------------

# Let's look at which state has the largest land area
# by adding the areas of all the records in each state
SELECT State_Name, SUM(ALand), SUM(AWater) 
FROM US_household_income
GROUP BY State_name
ORDER BY 2 DESC
;

# Alaska and Texas are the largest state, this makes sense.

# Let's order by area of water.
SELECT State_Name, SUM(ALand), SUM(AWater) 
FROM US_household_income
GROUP BY State_name
ORDER BY 3 DESC
;

# Michigan is the state that has the largest water area.
# Again, this makes sense since the great lakes are in Michigan.

# Let's find the top 10 largest states by land
SELECT State_Name, SUM(ALand), SUM(AWater) 
FROM US_household_income
GROUP BY State_name
ORDER BY 2 DESC
LIMIT 10
;

# Let's join the 2 tables together.
SELECT *
FROM US_household_income u
JOIN US_household_income_statistics us
	ON u.id = us.id
;

# Let's do a right join because
# the US_household_income table had missing values at the importation
# Let's filter on the NULL values from the US_household_income table. 
SELECT *
FROM US_household_income u
RIGHT JOIN US_household_income_statistics us
	ON u.id = us.id
WHERE u.id IS NULL
;

# There's quite a few records that are missing. I can either populate the missing data,
# or get rid of the incomplete records, using an INNER join

SELECT *
FROM US_household_income u
INNER JOIN US_household_income_statistics us
	ON u.id = us.id
;

# Let's filter out the missing data (reported as 0)
SELECT *
FROM US_household_income u
INNER JOIN US_household_income_statistics us
	ON u.id = us.id
WHERE Mean != 0
;

# Let's look at a subset of the data.
SELECT u.State_name, County, Type, Mean, Median
FROM US_household_income u
INNER JOIN US_household_income_statistics us
	ON u.id = us.id
WHERE Mean != 0
;

# Let's look at the mean and median household income for each state.
# Let's find the 5 states with the lowest household income.
SELECT u.State_name, ROUND(AVG(Mean), 1), ROUND(AVG(Median), 1)
FROM US_household_income u
INNER JOIN US_household_income_statistics us
	ON u.id = us.id
WHERE Mean != 0
GROUP BY u.State_name
ORDER BY 2
LIMIT 5
;

# Puerto Rico and Mississipi have the lowest household income.

# Let's find the 10 states with the highest household income.
SELECT u.State_name, ROUND(AVG(Mean), 1), ROUND(AVG(Median), 1)
FROM US_household_income u
INNER JOIN US_household_income_statistics us
	ON u.id = us.id
WHERE Mean != 0
GROUP BY u.State_name
ORDER BY 2 DESC
LIMIT 10
;

# In the richer states, the median is sometimes much higher than the mean,
# showing that there are some very high earners in these states, the income is
# not distributed evenly.

# Let's run the same query by grouping by Type.
SELECT Type, COUNT(Type), ROUND(AVG(Mean), 1), ROUND(AVG(Median), 1)
FROM US_household_income u
INNER JOIN US_household_income_statistics us
	ON u.id = us.id
WHERE Mean != 0
GROUP BY Type
ORDER BY 3 DESC
;

# People living in municipalities tend to have a higher
# household income. However, there's only 1 record for 
# municipality, which may not be representative of the whole
# municipality population.
# People living in urban or communities have a dramatically lower
# average income than the rest.

# Let's now order by the highest median income.
SELECT Type, COUNT(Type), ROUND(AVG(Mean), 1), ROUND(AVG(Median), 1)
FROM US_household_income u
INNER JOIN US_household_income_statistics us
	ON u.id = us.id
WHERE Mean != 0
GROUP BY Type
ORDER BY 4 DESC
;

# The median value for CPD is much higher than the average,
# showing that there are some large disparities in income
# for people living in this type of areas.

# Let's filter out the Types having a low number of records (outliers)
# because it's not possible to draw conclusions if there is not
# enough data
SELECT Type, COUNT(Type), ROUND(AVG(Mean), 1), ROUND(AVG(Median), 1)
FROM US_household_income u
INNER JOIN US_household_income_statistics us
	ON u.id = us.id
WHERE Mean != 0
GROUP BY Type
HAVING COUNT(Type) > 100
ORDER BY 4 DESC
;

# Let's look at the highest household income grouped by cities.
SELECT u.State_name, City, ROUND(AVG(Mean), 1) as average_income
FROM US_household_income u
INNER JOIN US_household_income_statistics us
	ON u.id = us.id
WHERE Mean != 0
GROUP BY u.State_name, City
ORDER BY average_income DESC
;

# People living in some cities have a much higher income than others.
