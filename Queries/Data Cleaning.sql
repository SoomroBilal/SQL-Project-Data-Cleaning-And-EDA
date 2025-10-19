USE world_layoffs;
SELECT * FROM layoffs;

-- Creating a table similar to original one
CREATE TABLE layoffs_staging LIKE layoffs;

-- Inserting all data from layoffs into layoffs_staging
INSERT layoffs_staging
SELECT * FROM layoffs;

SELECT * FROM layoffs_staging
WHERE company = 'Casper';


-- Removing duplicates from staging table

-- Checking if there are any duplicates
WITH duplicate_cte AS
(
SELECT *, ROW_NUMBER() OVER(PARTITION BY 
company, location, industry, total_laid_off,
percentage_laid_off, `date`, stage, country, 
funds_raised_millions) as row_num
FROM layoffs_staging
)

SELECT * FROM duplicate_cte
WHERE row_num > 1;

-- Removing duplicates by creating a new table having duplicates
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * FROM layoffs_staging2;

INSERT layoffs_staging2
SELECT *, ROW_NUMBER() OVER(PARTITION BY 
company, location, industry, total_laid_off,
percentage_laid_off, `date`, stage, country, 
funds_raised_millions) as row_num
FROM layoffs_staging; 

-- Setting this to 0, So we can safely delete or update records
SET SQL_SAFE_UPDATES = 0;

-- Deleting duplicates
DELETE FROM layoffs_staging2
WHERE row_num > 1;

SELECT * FROM layoffs_staging2
WHERE row_num > 1;


-- Now we will standardise our data
SELECT company, TRIM(company)
FROM layoffs_staging2;

-- Removing white spaces around company name
UPDATE layoffs_staging2
SET company = TRIM(company);

-- Making industry name consistent
SELECT DISTINCT industry FROM layoffs_staging2
ORDER BY 1;

SELECT industry from layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';



SELECT DISTINCT country FROM layoffs_staging2
ORDER BY 1;

-- There was found a inconsistency in a country's name need to update that
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.'  FROM country)
WHERE country LIKE 'United States%'; 


-- Updating date column
SELECT `date` 
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


-- Handling null values

SELECT * FROM layoffs_staging2
WHERE company = 'Airbnb';

SELECT * FROM layoffs_staging2
WHERE industry IS NULL OR industry = '';


SELECT t1.industry, t2.industry FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2 ON 
t1.company = t2.company and 
t1.location = t2.location
WHERE t1.industry IS NULL and t2.industry IS NOT NULL;

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2 ON 
t1.company = t2.company and 
t1.location = t2.location
SET t1.industry = t2.industry
WHERE t1.industry IS NULL and t2.industry IS NOT NULL;


-- Removing those rows which might not be required
-- Since this data is about layoffs so if any which has total_laid_off or percentage_laid_off as null we might not require that

SELECT * FROM layoffs_staging2
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

DELETE FROM layoffs_staging2
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;


-- Lastly the column that was added row_num is not required anymore so we are going to remove it
SELECT * FROM layoffs_staging2;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;
