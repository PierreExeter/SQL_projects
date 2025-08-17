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

# Let's look at the data.
SELECT * 
FROM US_household_income;

#-----------------------
# AUTOMATED DATA CLEANER
#-----------------------

# First, we create a copy of the table US_household_income to have a back up
# in case a mistake is made during the data cleaning process.

# In the Schemas tab, right click on the table US_household_income
# Select 'Copy to Clipboard' then 'Create statement'
# Then paste it below and rename the table 'US_household_income_cleaned'
# Let's add a column TimeStamp to track the changes made over time
# during the automated cleaning process.

CREATE TABLE `US_household_income_cleaned` (
  `row_id` int NOT NULL,
  `id` int NOT NULL,
  `State_Code` int NOT NULL,
  `State_Name` varchar(20) NOT NULL,
  `State_ab` varchar(2) NOT NULL,
  `County` varchar(33) NOT NULL,
  `City` varchar(22) NOT NULL,
  `Place` varchar(36) DEFAULT NULL,
  `Type` varchar(12) NOT NULL,
  `Primary` varchar(5) NOT NULL,
  `Zip_Code` int NOT NULL,
  `Area_Code` varchar(3) NOT NULL,
  `ALand` bigint NOT NULL,
  `AWater` bigint NOT NULL,
  `Lat` decimal(10,7) NOT NULL,
  `Lon` decimal(12,7) NOT NULL,
  `TimeStamp` TIMESTAMP NOT NULL,
  PRIMARY KEY (`row_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


# We create a stored procedure (drop it if exists) and change the delimiter.

DELIMITER $$
DROP PROCEDURE IF EXISTS Copy_and_Clean_Data;
CREATE PROCEDURE Copy_and_Clean_Data()
BEGIN

	# Create table (if the table doesn't already exist).
	CREATE TABLE IF NOT EXISTS `US_household_income_cleaned` (
	  `row_id` int NOT NULL,
	  `id` int NOT NULL,
	  `State_Code` int NOT NULL,
	  `State_Name` varchar(20) NOT NULL,
	  `State_ab` varchar(2) NOT NULL,
	  `County` varchar(33) NOT NULL,
	  `City` varchar(22) NOT NULL,
	  `Place` varchar(36) DEFAULT NULL,
	  `Type` varchar(12) NOT NULL,
	  `Primary` varchar(5) NOT NULL,
	  `Zip_Code` int NOT NULL,
	  `Area_Code` varchar(3) NOT NULL,
	  `ALand` bigint NOT NULL,
	  `AWater` bigint NOT NULL,
	  `Lat` decimal(10,7) NOT NULL,
	  `Lon` decimal(12,7) NOT NULL,
	  `TimeStamp` TIMESTAMP NOT NULL
	  # PRIMARY KEY (`row_id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

	# Copy data to new table and add timestamp value in the column
	INSERT INTO `US_household_income_cleaned`
    SELECT *, CURRENT_TIMESTAMP()
	FROM US_household_income;
    
	# Remove Duplicates
    # Note: we need to partition by the id AND TimeStamp
    # because each time we run the procedure we create new duplicates
    # if we only partition by the id. The timestamp is unique to when the stored procedure
    # was called. So we will be removing the duplicates only for the data corresponding
    # to the current timestamp.
	DELETE FROM US_household_income_cleaned 
	WHERE 
		row_id IN (
		SELECT row_id
	FROM (
		SELECT row_id, id,
			ROW_NUMBER() OVER (
				PARTITION BY id, `TimeStamp`
				ORDER BY id, `TimeStamp`) AS row_num
		FROM 
			US_household_income_cleaned
	) duplicates
	WHERE 
		row_num > 1
	);

	# Fixing some data quality issues by fixing typos and general standardization
	UPDATE US_household_income_cleaned
	SET State_Name = 'Georgia'
	WHERE State_Name = 'georia';

	UPDATE US_household_income_cleaned
	SET County = UPPER(County);

	UPDATE US_household_income_cleaned
	SET City = UPPER(City);

	UPDATE US_household_income_cleaned
	SET Place = UPPER(Place);

	UPDATE US_household_income_cleaned
	SET State_Name = UPPER(State_Name);

	UPDATE US_household_income_cleaned
	SET `Type` = 'CDP'
	WHERE `Type` = 'CPD';

	UPDATE US_household_income_cleaned
	SET `Type` = 'Borough'
	WHERE `Type` = 'Boroughs';

END $$
DELIMITER ;

CALL Copy_and_Clean_Data();

# Create  event to run the stored procedure every minute
DROP EVENT run_data_cleaning;
CREATE EVENT run_data_cleaning
	ON SCHEDULE EVERY 30 DAY
    DO CALL Copy_and_Clean_Data();

# Check the unique timesptamps that are printed each time
# the stored procedure is called in the event.
SELECT DISTINCT TimeStamp 
FROM US_household_income_cleaned;

# Check cleaned and agregated table
SELECT * 
FROM US_household_income_cleaned;

