#-----------------------
# CREATE DATABASE
#-----------------------

DROP DATABASE IF EXISTS `World_Life_Expectancy`;
CREATE DATABASE `World_Life_Expectancy`;
USE `World_Life_Expectancy`;

#-----------------------
# IMPORT DATA
#-----------------------
# Go to Schemas tab > customers data base > Table > right click on World_Life_Expectancy 
# Select 'Table Data Importation Wizard'
# Select world_life_expectancy.csv

# Note that it's good practice to create a staging or back up table in case we make a mistake in the data cleaning process.

# Let's look at the data.
SELECT * 
FROM world_life_expectancy
;

#-----------------------
# DROP DUPLICATES
#-----------------------

# Let's find out if there are any duplicates. 
# Method 1: Let's concatenate the country and the year
# to create a unique identifyer, and count how many there are. They should be unique, 
# otherwise we have identified a duplicate
SELECT Country, Year, CONCAT(Country, Year), COUNT(CONCAT(Country, Year))
FROM world_life_expectancy
GROUP BY Country, Year, CONCAT(Country, Year)
HAVING COUNT(CONCAT(Country, Year)) > 1
;

# # Method 2: Let's identify what the duplicates are by using a window function.
# By partitioning on the CountryYear concatenation, we add a row number.
# If this row number is > 1, it means that we have found a duplicate.
SELECT *
FROM (
	SELECT Row_ID,
	CONCAT(Country, Year),
	ROW_NUMBER() OVER( PARTITION BY CONCAT(Country, Year) ORDER BY CONCAT(Country, Year)) as Row_Num
	FROM world_life_expectancy
	) AS Row_table
WHERE Row_Num > 1
;

# Delete the duplicates by filtering the row having row_num > 1 using a sub-query. 
DELETE FROM world_life_expectancy
WHERE 
	Row_ID IN (
    SELECT Row_ID
FROM (
	SELECT Row_ID,
	CONCAT(Country, Year),
	ROW_NUMBER() OVER( PARTITION BY CONCAT(Country, Year) ORDER BY CONCAT(Country, Year)) as Row_Num
	FROM world_life_expectancy
	) AS Row_table
WHERE Row_Num > 1
)
;

#-----------------------
# IMPUTE MISSING DATA
#-----------------------

# Identify the rows with a blank status.
SELECT * 
FROM world_life_expectancy
WHERE Status = ''
;

# Identify all the distinct statuses.
SELECT DISTINCT(Status)
FROM world_life_expectancy
;

# identify all the developing countries.
SELECT DISTINCT(Country)
FROM world_life_expectancy
WHERE Status = 'Developing';

# We want to replace these blank status by the status of the same country 
# but from another year. We assume that a country does change status from year to year.
# If it's a developing country, we want to update their status
# (if it's blank) by 'Developing'

# Update status to developing using a self-join
UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.Country = t2.Country
SET t1.Status = 'Developing'
WHERE t1.Status = ''
AND t2.Status != ''
AND t2.Status = 'Developing'
;

# Let's do the same for the Developed countries.
UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.Country = t2.Country
SET t1.Status = 'Developed'
WHERE t1.Status = ''
AND t2.Status != ''
AND t2.Status = 'Developed'
;

# Identify any blanks in the life expectancy column
SELECT * 
FROM world_life_expectancy
WHERE `Life expectancy` = ''
;

# Populate the missing life expectancy values with 
# the average of the life expectancy from the previous and following year.
SELECT t1.Country, t1.Year, t1.`Life expectancy`,
t2.Country, t2.Year, t2.`Life expectancy`,
t3.Country, t3.Year, t3.`Life expectancy`,
ROUND((t2.`Life expectancy` + t3. `Life expectancy`)/2,1)
FROM world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.Country = t2.Country
    AND t1.Year = t2.Year - 1
JOIN world_life_expectancy t3
	ON t1.Country = t3.Country
    AND t1.Year = t3.Year + 1
WHERE t1.`Life expectancy` = ''
;

# Update missing life expectancy values using the previous calculation
UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.Country = t2.Country
    AND t1.Year = t2.Year - 1
JOIN world_life_expectancy t3
	ON t1.Country = t3.Country
    AND t1.Year = t3.Year + 1
SET t1.`Life expectancy` = ROUND((t2.`Life expectancy` + t3. `Life expectancy`)/2,1)
WHERE t1.`Life expectancy` = ''
;

#-----------------------
# EXPLORATORY DATA ANALYSIS
#-----------------------

# Identify the countries that had the highest improvement in life expectancy
# in the last 15 years
SELECT Country, 
MIN(`Life expectancy`), 
MAX(`Life expectancy`),
ROUND(MAX(`Life expectancy`) - MIN(`Life expectancy`),1) AS Life_Increase_15_Years
FROM world_life_expectancy
GROUP BY Country
HAVING MIN(`Life expectancy`) != 0
AND MAX(`Life expectancy`) != 0
ORDER BY Life_Increase_15_Years DESC
;

# Haiti and Zimbabwe had the highest life expectancy increase in the last 15 years.

# Print the average life expectancy by year
SELECT Year, ROUND(AVG(`Life expectancy`),2)
FROM world_life_expectancy
WHERE `Life expectancy` != 0
AND `Life expectancy` != 0
GROUP BY Year
ORDER BY Year
;

# Life expectancy is increasing each year, which makes sense.

# Let's now look at correlation between average life expectancy and average GDP.
SELECT Country, ROUND(AVG(`Life expectancy`),1) AS Life_Exp, ROUND(AVG(GDP),1) AS GDP
FROM world_life_expectancy
GROUP BY Country
HAVING Life_Exp > 0
AND GDP > 0
ORDER BY GDP DESC
;

# It looks like a higher GDP is correlated with a higher life expectancy.
# In order to confirm this, let's group the countries by low and high GDP
# and calculate their average life expectancy.
SELECT 
SUM(CASE WHEN GDP >= 1500 THEN 1 ELSE 0 END) High_GDP_Count,
AVG(CASE WHEN GDP >= 1500 THEN `Life expectancy` ELSE NULL END) High_GDP_Life_Expectancy,
SUM(CASE WHEN GDP <= 1500 THEN 1 ELSE 0 END) Low_GDP_Count,
AVG(CASE WHEN GDP <= 1500 THEN `Life expectancy` ELSE NULL END) Low_GDP_Life_Expectancy
FROM world_life_expectancy
;
# Richer countries definitely have a higher life expectancy.


# Let's look at the correlation between the average life expectancy
# and country status
SELECT Status, COUNT(DISTINCT Country), ROUND(AVG(`Life expectancy`),1)
FROM world_life_expectancy
GROUP BY Status
;
# Developed countries have a higher life expectancy than developing countries.

# Let's look at the correlation between life expectancy and BMI by country
SELECT Country, ROUND(AVG(`Life expectancy`),1) AS Life_Exp, ROUND(AVG(BMI),1) AS BMI
FROM world_life_expectancy
GROUP BY Country
HAVING Life_Exp > 0
AND BMI > 0
ORDER BY BMI ASC
;

# A Higher BMI is positively correlated with a higher life expectancy.

# Let's look at the correlation between life expectancy and adult mortality.
# Using a rolling function, we can see how many adults have died in the last 15 years by countries.
SELECT Country,
Year,
`Life expectancy`,
`Adult Mortality`,
SUM(`Adult Mortality`) OVER(PARTITION BY Country ORDER BY Year) AS Rolling_Total
FROM world_life_expectancy
WHERE Country LIKE '%United%'
;

