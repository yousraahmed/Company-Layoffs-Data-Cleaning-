-- Data Exploration

-- Temporal Trends
-- What is the time frame of the layoffs?
SELECT 
    MIN(`date`), MAX(`date`)
FROM
    layoffs_staging_2;

-- How have layoffs trended over time (monthly, quarterly, yearly)?
-- Monthly
SELECT 
    YEAR(`date`) AS year,
    MONTH(`date`) AS month,
    SUM(total_laid_off) AS total_layoffs
FROM
    layoffs_staging_2
WHERE
    YEAR(`date`) IS NOT NULL
        AND MONTH(`date`) IS NOT NULL
GROUP BY YEAR(`date`) , MONTH(`date`)
ORDER BY 1 , 2;

-- Quraterly 
SELECT
    YEAR(`date`) AS year,
    QUARTER(`date`) AS quarter,
    Sum(total_laid_off) AS layoffs_count
FROM
    layoffs_staging_2
    where YEAR(`date`) is not null and QUARTER(`date`) is not null
GROUP BY
    YEAR(`date`), QUARTER(`date`)
ORDER BY
    year, quarter;

-- Yearly
SELECT 
    YEAR(`date`), SUM(total_laid_off)
FROM
    layoffs_staging_2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

-- Total rolling layoffs
With monthly_layoffs as (
SELECT 
    YEAR(`date`) AS year,
    MONTH(`date`) AS month,
    SUM(total_laid_off) AS total_layoffs
FROM
    layoffs_staging_2
WHERE
    YEAR(`date`) IS NOT NULL
        AND MONTH(`date`) IS NOT NULL
GROUP BY YEAR(`date`) , MONTH(`date`)
ORDER BY 1 , 2
)

SELECT
	year,
    month,
    SUM(total_layoffs) OVER(ORDER BY year, month) AS rolling_layoffs 
FROM monthly_layoffs;



-- Geographical trends
-- Which countries have the highest number of layoffs?
SELECT 
    country, SUM(total_laid_off) as total_layoffs
FROM
    layoffs_staging_2
GROUP BY country
ORDER BY 2 DESC;

-- Are there any noticeable trends in layoffs by country over time?
SELECT 
    country,
    YEAR(`date`) AS year,
    SUM(total_laid_off) AS total_layoffs
FROM
    layoffs_staging_2
WHERE
    YEAR(`date`) IS NOT NULL
GROUP BY country , YEAR(`date`)
ORDER BY 1 , 2;


-- Industry Analysis
-- Which industries were most impacted by the layoffs?
SELECT 
    industry, SUM(total_laid_off) as total_layoffs
FROM
    layoffs_staging_2
GROUP BY industry
ORDER BY 2 DESC;

-- Rank the percentage of layoffs in each industry per year? 
WITH industry_total_workforce as
(
SELECT 
    YEAR(`date`) AS year,
    industry,
    SUM(ROUND(total_laid_off / percentage_laid_off)) AS total_workforce,
    SUM(total_laid_off) AS total_layoffs
FROM
    layoffs_staging_2
WHERE
    total_laid_off IS NOT NULL
        AND percentage_laid_off IS NOT NULL
        AND YEAR(`date`) IS NOT NULL
GROUP BY year , industry
ORDER BY 1 , 2
)

, industry_percentage AS(
SELECT 
	year,
    industry,
    round(total_layoffs/total_workforce, 2) AS percentage_layoffs
    FROM industry_total_workforce
)
Select  
	year,
    industry,
    percentage_layoffs,
    DENSE_RANK() OVER(partition by year order by percentage_layoffs desc) as industry_rank
FROM industry_percentage;

-- How do layoff temporal trends differ across various industries?
SELECT 
    industry, YEAR(`date`) AS year, SUM(total_laid_off) as total_layoffs
FROM
    layoffs_staging_2
WHERE
    YEAR(`date`) IS NOT NULL
        AND industry IS NOT NULL
GROUP BY industry , YEAR(`date`)
ORDER BY 1 , 2;




-- Company analysis
-- Which companys had the highest numbers of layoffs?
SELECT 
    company, SUM(total_laid_off)
FROM
    layoffs_staging_2
GROUP BY company
ORDER BY 2 DESC;

-- Which stages are more prone to layoffs?
SELECT 
    stage, SUM(total_laid_off)
FROM
    layoffs_staging_2
GROUP BY stage
ORDER BY 2 DESC;

-- Which companys had to completely shut down?
SELECT 
    company, percentage_laid_off
FROM
    layoffs_staging_2
WHERE
    percentage_laid_off = 1
ORDER BY 1;

-- Rank the top five companys that had the highest number of layoffs each year
WITH company_year as
(
SELECT 
    company,
    YEAR(`date`) AS year,
    SUM(total_laid_off) AS total_layoffs
FROM
    layoffs_staging_2
WHERE
    YEAR(`date`) IS NOT NULL
GROUP BY company , YEAR(`date`)
ORDER BY 1
)
, company_year_ranking AS (
SELECT
	*,
    DENSE_RANK() OVER(PARTITION BY year ORDER BY total_layoffs DESC) AS company_rank 
FROM company_year
)
SELECT * FROM company_year_ranking WHERE company_rank <= 5;


select * from layoffs_staging_2;






