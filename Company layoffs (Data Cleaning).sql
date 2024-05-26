-- Data Cleaning


-- Create a replica of the data for backup
CREATE TABLE layoffs_staging LIKE layoffs;

INSERT layoffs_staging
SELECT *
FROM layoff;
 
 
 -- Clean duplicates 
 
 -- Create a replica of the original table and with a new column called row_num
 -- row_num represents the number of occurances of a record. It starts at 1 for each record and in case of a duplicate the value of row_num will increment for that duplicate.
 -- If a record has a value of 2 or more in the column row_num, it should be deleted because that means it's a duplicate.
 CREATE TABLE `layoffs_staging_2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL, 
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

Insert into layoffs_staging_2 
Select *, ROW_NUMBER() 
 OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_milLions
) row_num
from layoffs_staging;

DELETE FROM layoffs_staging_2 
WHERE row_num >= 2;


-- Standardize data for each column

-- Use trim() function to remove spaces before the company's name
UPDATE layoffs_staging_2 
SET company = TRIM(company);

-- Standardize the location column by fixing a few misspellings
SELECT DISTINCT location
FROM layoffs_staging_2 ORDER BY 1;
UPDATE layoffs_staging_2 Set location = 'Düsseldorf' WHERE location = 'DÃ¼sseldorf';
UPDATE layoffs_staging_2 Set location = 'Florianópolis' WHERE location = 'FlorianÃ³polis';
UPDATE layoffs_staging_2 Set location = 'Malmö' WHERE location = 'MalmÃ¶';
UPDATE layoffs_staging_2 Set location = 'Other' WHERE location = 'Non-U.S.';

-- Standardize the industry column
SELECT DISTINCT (industry)
FROM layoffs_staging_2
ORDER BY industry;
-- Standardize the crypto industry name
UPDATE layoffs_staging_2 
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Standardize the date column from a string to a date data type
UPDATE layoffs_staging_2 
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');
-- Change data type for the date column
ALTER TABLE layoffs_staging_2 Modify column `date` DATE;

-- Standardize the country column
SELECT DISTINCT country
FROM layoffs_staging_2 
ORDER BY 1;
-- Remove period at the end of some countries
UPDATE layoffs_staging_2 
SET country = TRIM(TRAILING '.' FROM country);


-- Populate Blank Variables if possible
SELECT *
FROM layoffs_staging_2
WHERE industry = '';
-- Set blank values to null
UPDATE layoffs_staging_2 
SET industry = NULL
WHERE industry = '';

SELECT *
FROM layoffs_staging_2 t1
        JOIN
    layoffs_staging_2 t2 
    ON t1.company = t2.company
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;

UPDATE layoffs_staging_2 t1
        JOIN
    layoffs_staging_2 t2 
    ON t1.company = t2.company 
SET t1.industry = t2.industry
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;

-- Remove the rows that have total_laid_off and percentage_laid off as null variables since they are not meaningful data.
DELETE FROM layoffs_staging_2 
WHERE percentage_laid_off IS NULL AND total_laid_off IS NULL;

-- Drop column row_num since we don't need it anymore
ALTER TABLE layoffs_staging_2 DROP COLUMN row_num ;
SELECT * FROM layoffs_staging_2;



