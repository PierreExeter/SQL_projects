#-----------------------
# CREATE DATABASE
#-----------------------

DROP DATABASE IF EXISTS `customers`;
CREATE DATABASE `customers`;
USE `customers`;

#-----------------------
# CREATE TABLE
#-----------------------
CREATE TABLE customer_data (
`id` int,
`customer_id` int,
`phone` text,
`birth_date` text,
`address` text,
`total_money_spent` int,
`income` text,
`Are you over 18?` text,
`favorite_color` text,
PRIMARY KEY (id)
);

#-----------------------
# IMPORT DATA
#-----------------------
# Go to Schemas tab > customers data base > Table > right click on customer_data 
# Select 'Table Data Importation Wizard'
# Select customer_data.csv


# Note that it's good practice to create a staging or back up table in case we make a mistake in the data cleaning process.

# Let's look at the data.
SELECT * 
FROM customer_data
;

#-----------------------
# 1. DROP DUPLICATES
#-----------------------

# METHOD 1 : using COUNT
# Check if there are any duplicates by counting the number of customer_id.
SELECT customer_id, COUNT(customer_id)
FROM customer_data
GROUP BY customer_id
;

# Identify the duplicates by filtering the entries having more than 1 customer_id.
SELECT customer_id, COUNT(customer_id)
FROM customer_data
GROUP BY customer_id
HAVING COUNT(customer_id) > 1
;

# METHOD 2 : using a window function
# Check if there are any duplicates by partitioning by customer_id and adding row number.
SELECT customer_id,
ROW_NUMBER() OVER(PARTITION BY customer_id) AS row_num
FROM customer_data
;

# Identify the duplicates by using the previous query
# as sub-query and filtering the row where the row_num > 1.
SELECT *
FROM (
	SELECT customer_id,
	ROW_NUMBER() OVER(PARTITION BY customer_id) AS row_num
	FROM customer_data) AS table_row
WHERE row_num > 1
;

# Identify the id number of the row having more than 1 customer_id.
SELECT id
FROM (
	SELECT id,
	ROW_NUMBER() OVER(PARTITION BY customer_id) AS row_num
	FROM customer_data) AS table_row
WHERE row_num > 1
;

# Delete the duplicates by using the filtered id previously identified.
DELETE FROM customer_data
WHERE id IN (
	SELECT id
	FROM (
		SELECT id,
		ROW_NUMBER() OVER(PARTITION BY customer_id) AS row_num
		FROM customer_data) AS table_row
	WHERE row_num > 1
)
;

# NOTE : if the deletion didn't work in MySQL Workbench, go to
# Edit > Preferences... > SQL editor
# At the bottom, uncheck the box 'Safe update'.

#-----------------------
# 2. STANDARDIZE DATA
#-----------------------

# Remove unwanted characters in phone numbers.
SELECT phone, REGEXP_REPLACE(phone, '[()-/+]', '') 
FROM customer_data
;

# Update the phone numbers.
UPDATE customer_data
SET phone = REGEXP_REPLACE(phone, '[()-/+]', '') 
;

# Format the phone numbers by adding a '-' at the right place
# except when the phone numbers are blank.
SELECT 
phone, 
CONCAT(
	SUBSTRING(phone, 1, 3), '-',
	SUBSTRING(phone, 4, 3), '-',
	SUBSTRING(phone, 7, 4)) 
FROM customer_data
WHERE phone != ''
;

# Update the phone numbers with the new format.
UPDATE customer_data
SET phone = CONCAT(
	SUBSTRING(phone, 1, 3), '-',
	SUBSTRING(phone, 4, 3), '-',
	SUBSTRING(phone, 7, 4))
WHERE phone != ''
;

# Format the birthdate from text to date format.
SELECT 
birth_date, 
STR_TO_DATE(birth_date, '%m/%d/%Y'),
STR_TO_DATE(birth_date, '%Y/%d/%m')  
FROM customer_data
;

# We notice that some dates are formatted in 2 different ways.
# We use a CASE statement to update the dates in their correct format order.
SELECT 
birth_date, 
CASE 
WHEN STR_TO_DATE(birth_date, '%m/%d/%Y') IS NOT NULL THEN STR_TO_DATE(birth_date, '%m/%d/%Y')
WHEN STR_TO_DATE(birth_date, '%m/%d/%Y') IS NULL THEN STR_TO_DATE(birth_date, '%Y/%d/%m')
END
FROM customer_data
;

# Note that we cannot use IF or CASE statements in the UPDATE function. 
# We will use substrings to format the date. 
# First, we format the dates that are in the incorrect 
# format (id 9 and 11) with the following format : m/d/Y.
SELECT 
birth_date, CONCAT(
SUBSTRING(birth_date, 9, 2), '/',
SUBSTRING(birth_date, 6, 2), '/',
SUBSTRING(birth_date, 1, 4))
FROM customer_data
;

# First, let's update the birthdate with id 9 and 11.
UPDATE customer_data
SET birth_date = CONCAT(
SUBSTRING(birth_date, 9, 2), '/',
SUBSTRING(birth_date, 6, 2), '/',
SUBSTRING(birth_date, 1, 4))
WHERE id IN (9, 11)
;

# Now, all the dates are in the same format. We just
# need to convert them from a text to a date format.
UPDATE customer_data
SET birth_date = STR_TO_DATE(birth_date, '%m/%d/%Y')
;

# Rename column name to get rid of space.
ALTER TABLE customer_data RENAME COLUMN `Are you over 18?` TO `over_18`;

# Format over_18 column to only show Y and N using a CASE statement.
SELECT 
over_18, 
CASE 
	WHEN over_18 = 'Yes' THEN 'Y'
	WHEN over_18 = 'NO' THEN 'N'
	ELSE over_18
END
FROM customer_data
;

# Update over_18 column with the correct format.
UPDATE customer_data
SET over_18 = CASE 
	WHEN over_18 = 'Yes' THEN 'Y'
	WHEN over_18 = 'NO' THEN 'N'
	ELSE over_18
END
;

# Break out the address column into multiple columns.
# This makes more sense if we want to group by street, city or state in the future.
# We use SUBTRING_INDEX to identify the index of the comma delimiter in the address.
SELECT address, 
SUBSTRING_INDEX(address,',',1) AS Street,
SUBSTRING_INDEX(SUBSTRING_INDEX(address,',',2),',',-1) AS City,
SUBSTRING_INDEX(address,',',-1) AS State
FROM customer_data
;

# Add the street, city and state column after the address column.
# They are strings data type of less than 50 characters.
ALTER TABLE customer_data
ADD COLUMN street VARCHAR(50) AFTER address,
ADD COLUMN city VARCHAR(50) AFTER street,
ADD COLUMN state VARCHAR(50) AFTER city
;

# Populate the empty street column with the correct data.
UPDATE customer_data
SET street = SUBSTRING_INDEX(address,',',1)
;

# Populate the empty city column with the correct data.
UPDATE customer_data
SET city = SUBSTRING_INDEX(SUBSTRING_INDEX(address,',',2),',',-1)
;

# Populate the empty state column with the correct data.
UPDATE customer_data
SET state = SUBSTRING_INDEX(address,',',-1)
;

# Trim the blank spaces around the state string.
UPDATE customer_data
SET state = TRIM(state)
;
# Trim the blank spaces around the city string.
UPDATE customer_data
SET city = TRIM(city)
;
# Capitalize the state string.
UPDATE customer_data
SET state = UPPER(state)
;

# Delete address column, as it is was broken down into other columns.
ALTER TABLE customer_data
DROP COLUMN address
;

# Delete the favorite color column, as the information is not relevant.
ALTER TABLE customer_data
DROP COLUMN favorite_color
;

# Replace the blank values in phone and income columns with NULL.
# This makes sure that the future aggregate function calculations
# are not corrupted by the blank values.
UPDATE customer_data
SET phone = NULL
WHERE phone = ''
;

UPDATE customer_data
SET income = NULL
WHERE income = ''
;

# Check if the customer declaring that they are over 18
# are really over 18, by filtering the entries where 18 years from
# now is higher than their birthdate.
SELECT birth_date, over_18
FROM customer_data
WHERE (YEAR(NOW()) - 18) > YEAR(birth_date)
;

# We saw that 2 customers declaring being over 18.
# Let's update these 2 entries with 'N' and the rest of the entries with 'Y'.
UPDATE customer_data
SET over_18 = 'N'
WHERE (YEAR(NOW()) - 18) < YEAR(birth_date)
;

UPDATE customer_data
SET over_18 = 'Y'
WHERE (YEAR(NOW()) - 18) > YEAR(birth_date)
;

# Let's look at the cleaned up data.
SELECT * 
FROM customer_data
;
