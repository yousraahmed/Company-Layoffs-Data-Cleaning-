-- Data Cleaning


-- Create a replica of the data for backup
CREATE TABLE layoffs_staging Like layoffs;
 Insert layoffs_staging Select * from layoff;
 
 
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

DELETE from layoffs_staging_2 where row_num >= 2;


-- Standardize data for each column


-- Use trim() function to remove spaces before the company's name
UPDATE layoffs_staging_2 SET company = trim(company);


-- Standardize the location column by fixing a few misspellings
SELECT DISTINCT location from layoffs_staging_2 order by 1;
UPDATE layoffs_staging_2 Set location = 'Düsseldorf' WHERE location = 'DÃ¼sseldorf';
UPDATE layoffs_staging_2 Set location = 'Florianópolis' WHERE location = 'FlorianÃ³polis';
UPDATE layoffs_staging_2 Set location = 'Malmö' WHERE location = 'MalmÃ¶';
UPDATE layoffs_staging_2 Set location = 'Other' WHERE location = 'Non-U.S.';


-- Standardize the industry column
Select distinct(industry) from layoffs_staging_2 order by industry;
-- Standardize the crypto industry name
UPDATE layoffs_staging_2 Set industry = 'Crypto' WHERE industry LIKE 'Crypto%';


-- Standardize the date column from a string to a date data type
UPDATE layoffs_staging_2 SET `date` = str_to_date(`date`, '%m/%d/%Y');
-- Change data type for the date column
ALTER TABLE layoffs_staging_2 Modify column `date` DATE;


-- Standardize the country column
Select distinct country from layoffs_staging_2 order by 1;
-- Remove period at the end of some countries
UPDATE layoffs_staging_2 SET country = trim(Trailing '.' from country);


-- Populate Blank Variables if possible
Select * from layoffs_staging_2 where  industry = '';
update layoffs_staging_2 set industry = NULL where industry = '';

Select * 
from layoffs_staging_2 t1 join layoffs_staging_2 t2 
on  t1.company = t2.company where t1.industry is null and t2.industry is not null;

Update  layoffs_staging_2 t1 join layoffs_staging_2 t2 
on  t1.company = t2.company 
set t1.industry = t2.industry
where t1.industry is null and t2.industry is not null;

-- Remove the rows that have total_laid_off and percentage_laid off as null variables since they are not meaningful data.

Delete from layoffs_staging_2 where percentage_laid_off is null and total_laid_off is null;

-- Drop column row_num since we don't need it anymore
Alter table layoffs_staging_2 drop column row_num ;
Select * from layoffs_staging_2 ;


