-- EDA - Exploratory Data Analysis
-- Here we are jsut going to explore the data and find trends or patterns or anything interesting like outliers

Select *
from layoffs_staging2;

select max(total_laid_off) , max(percentage_laid_off)
from layoffs_staging2;

-- Here max percentage=1 means complete 100% , i.e alll employees were fired 

select *
from layoffs_staging2
where percentage_laid_off = 1
order by total_laid_off desc;

-- let's see how much these companies had when they laid off

select *
from layoffs_staging2
where percentage_laid_off = 1
order by funds_raised_millions desc;

-- let's check total how many employees were laid of by grouping comapnies
select company , sum(total_laid_off)
from layoffs_staging2
group by company
order by 2 desc;

-- -------output -------------
/*
Amazon	18150
Google	12000
Meta	11000
Salesforce	10090
Microsoft	10000
Philips	10000
Ericsson	8500
Uber	7585
Dell	6650 

--> Most layoff took place in big tech comapnies like amazon, google , meta etc
*/

-- now let's check when this layoff stated and ended (according to data)

select  min(`date`),max(`date`) 
from layoffs_staging2;

/* 
-->   started --> 2020-03-11	Ended -->2023-03-06 
-->  Looking at this date range , it is clear that layoff happened during Pandemic 
*/

select industry , sum(total_laid_off)
from layoffs_staging2
group by industry
order by 2 desc;

-- > consumer industry was hit a lot during that period
-- > Manufacturing was effected least

select country , sum(total_laid_off)
from layoffs_staging2
group by country
order by 2 desc;

-- > United States , India and Netherlands were top 3 countries that was effected the most

select Year(`date`) , sum(total_laid_off)
from layoffs_staging2
group by  Year(`date`)
order by 1 desc;

-- > 2023 year saw many layoffs across world 

select stage , sum(total_laid_off)
from layoffs_staging2
group by  stage
order by 2 desc;

-- > Post-IPO total_layoffs were higher comapared to other stages of a comany 

-- now let's check how many layoff took place every month from start to end date range in the data

select substring(`date`,1,7) as `month` , sum(total_laid_off)
from layoffs_staging2
where substring(`date`,1,7) is not null
group by `month`
order by `month`;


-- Let's do Rolling_total 
-- we can do this using CTE

with Rolling_Total as
(
select substring(`date`,1,7) as `month` , sum(total_laid_off) as total_layoff
from layoffs_staging2
where substring(`date`,1,7) is not null
group by `month`
order by `month`
)
select `month`, total_layoff ,
 sum(total_layoff) over(order by `month`) as rolling_total
 from Rolling_Total;

  
-- > now let's do ranking company wise per year in terms of layoffs

select company , year(`date`) , sum(total_laid_off)
from layoffs_staging2
group by company , year(`date`)
order by 3 desc; 

with Company_Year AS
(
select company , year(`date`) , sum(total_laid_off)
from layoffs_staging2
group by company , year(`date`)
order by 3 desc
)
select * from Company_Year;

with Company_Year (company , years ,total_laid_off) AS                    -- Aliases (company , years ,total_laid_off)
(
select company , year(`date`) , sum(total_laid_off)
from layoffs_staging2
group by company , year(`date`)
order by 3 desc
)
select * ,
dense_rank() over(partition by years order by total_laid_off desc) as ranking 
from Company_Year
where years is not null
order by ranking;


-- -----------------------------------------------------
-- let's simplify the output and have top 5 ranks every year

 
with Company_Year (company , years ,total_laid_off) AS                    
(
select company , year(`date`) , sum(total_laid_off)
from layoffs_staging2
group by company , year(`date`)
order by 3 desc
),
Company_year_rank as
(
select * ,
dense_rank() over(partition by years order by total_laid_off desc) as ranking 
from Company_Year
where years is not null
)
select *
from Company_year_rank
where ranking <= 5;


-- High level analysis
/*
you would find the proportion of layoffs per company as opposed to just finding the companies that got rid of the most people.
The argument here is that a large company with a layoff proportion of 0.05 could still show more people being laid off,
then a smaller company with a layoff proportion of 0.7, even though this gives valuable insight that the past 3 years have
hit small companies very hard. Thought I would mention this and open it up to any discussion
*/

SELECT stage, ROUND(AVG(percentage_laid_off),2)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;
