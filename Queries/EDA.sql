-- Exploratory Data Analysis (EDA)

USE world_layoffs;
SELECT * FROM layoffs_staging2;

-- Layoffs by industries
SELECT industry, SUM(total_laid_off) as total_layoffs
FROM layoffs_staging2 
GROUP BY industry
ORDER BY 2 DESC;

-- Layoffs by country
SELECT country, SUM(total_laid_off) as total_layoffs
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC; 

-- Total layoffs by year
SELECT YEAR(`date`) AS 'Year', SUM(total_laid_off) AS 'Total Layoffs'
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

-- Layoffs over a period of time
SELECT SUBSTRING(`date`, 1, 7) as `Month`, SUM(total_laid_off) as total_layoffs
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `Month`
ORDER BY 1 ASC;

WITH Rolling_Total AS
(
SELECT SUBSTRING(`date`, 1, 7) as `Month`, 
SUM(total_laid_off) AS Total_Layoffs
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `Month`
ORDER BY 1 ASC
)

SELECT `Month`, Total_Layoffs, SUM(Total_Layoffs) OVER(ORDER BY `Month`) AS Rolling_Total_Layoffs
FROM Rolling_Total;

-- Top Layoffs in each year by companies
WITH company_year(company, `year`, total_laid_offs) AS
(
SELECT company, YEAR(`date`) as `year`, SUM(total_laid_off) FROM layoffs_staging2
WHERE YEAR(`date`) IS NOT NULL
GROUP BY company, YEAR(`date`)
),

company_year_ranking AS
(
SELECT *, 
DENSE_RANK() OVER(PARTITION BY `year` 
ORDER BY total_laid_offs DESC)
AS Ranking FROM company_year
)

SELECT * FROM company_year_ranking
WHERE ranking <= 5;