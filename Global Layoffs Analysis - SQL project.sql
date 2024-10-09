USE project1;
SELECT * 
FROM layoffs;

-- Creating 2 table skeleton copies
CREATE TABLE layoffs_staging
LIKE layoffs;

CREATE TABLE layoffs_staging2
LIKE layoffs;

-- Filling the table with data
INSERT layoffs_staging
SELECT * 
FROM layoffs;

SELECT * 
FROM layoffs_staging;

-- Inserting data into table 2
INSERT layoffs_staging2
SELECT * 
FROM layoffs;

-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------
#1. Remove Duplicates
#Adding a new column in second table copy
ALTER TABLE layoffs_staging2
-- DROP COLUMN row_numb;
ADD COLUMN row_numb INT NOT NULL; 

-- Filling new column with ranking values
INSERT INTO layoffs_staging2
SELECT *, ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised) AS row_numb
FROM layoffs_staging;

SELECT * 
FROM layoffs_staging2;

SELECT * 
FROM layoffs_staging2
-- WHERE row_numb=2;
WHERE company = "Amazon";

DELETE 
FROM layoffs_staging2
WHERE row_numb=0;

# 2. Standardizartion
UPDATE layoffs_staging2
SET company = TRIM(company);

#Scan for weirdly named industries that could be grouped
SELECT DISTINCT industry  
FROM layoffs_staging2
ORDER BY 1;

SELECT * 
FROM layoffs_staging2
WHERE industry LIKE "%https%";

UPDATE layoffs_staging2
SET industry = "Consumer"	
WHERE industry LIKE "%https%";

-- Trim and remove trailing spaces
SELECT DISTINCT country, TRIM(Trailing '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country =  TRIM(Trailing '.' FROM country)
WHERE country LIKE '%United%';


SELECT `date`,
str_to_date(`date`, '%Y-%m-%d')
FROM layoffs_staging2;
#As you learned through a ridiculuous trial and error process, make sure to MATCH THE 2nd paramater's FORMAT OF STR_TO_DATE to the date being fed in for conversion.

UPDATE layoffs_staging2
SET `date` = str_to_date(`date`, '%Y-%m-%d');
#Even though the date in the date column is in the date format, it still shows it as text in the Info tab. SO let's change that:
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

SELECT `date`
FROM layoffs_staging2;

#Best part of standardization - dealing with the NULL values.
SELECT * 
FROM layoffs_staging2
WHERE total_laid_off= 0 AND percentage_laid_off = 0;

DELETE FROM layoffs_staging2
WHERE total_laid_off= 0 AND percentage_laid_off = 0;
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------
# Status Check
SELECT * 
FROM layoffs_staging2;

SELECT count(*)
FROM layoffs_staging2;
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT * 
FROM layoffs_staging2
-- WHERE industry IS NULL;
WHERE industry = '' OR industry IS NULL;

UPDATE layoffs_staging2
SET industry = 'Infrastructure'
WHERE industry = '';



-- Exploratory Data Analysis
-- In this case, the (CAST columnname AS UNSIGNED) was necessary to get MYSQL to read the data as numbers rather than text.
SELECT company, percentage_laid_off, MAX(CAST(total_laid_off AS UNSIGNED)) 
FROM layoffs_staging2
GROUP BY company,percentage_laid_off;

SELECT company, MAX(CAST(total_laid_off AS UNSIGNED)) 
FROM layoffs_staging2
GROUP BY company;

SELECT * 
FROM layoffs_staging2
WHERE percentage_laid_off=1
ORDER BY funds_raised DESC;

SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY industry DESC;

SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

SELECT YEAR(`date`),  SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

SELECT stage,  SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 1 DESC;


SELECT `date`, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY `date`;

SELECT SUBSTRING(`date`, 1,7) AS MONTH, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY `MONTH`
ORDER BY 2 ASC;

-- Now for a rolling total version,****
WITH RollingTotal AS
(
SELECT SUBSTRING(`date`, 1,7) AS MONTH,    SUM(total_laid_off) AS TotalLaidOff 
FROM layoffs_staging2
GROUP BY `MONTH`
ORDER BY 2 ASC
)
SELECT `MONTH`, TotalLaidOff, SUM(TotalLaidOff) OVER (ORDER BY `MONTH`) AS Rolling__Total
FROM RollingTotal;


SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY company ASC;

SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC;
