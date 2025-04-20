-- Data Cleaning

select * from layoffs;

-- 1.Remove Duplicates
-- 2. Standardize the Data
-- 3. Null Values or blank values
-- 4. Remove any columns 


-- Lets create a copy of the layoffs table

CREATE TABLE layoffs_staging
Like layoffs;  

Insert layoffs_staging
select * from layoffs;

select * from layoffs_staging;


-- Identify Duplicates
select *, 
row_number() over(
partition by company,industry,location,stage,country,funds_raised_millions,
total_laid_off, percentage_laid_off, `date`) as row_num
from layoffs_staging;

-- ---------------------------------
with duplicate_cte as
(
select *, 
row_number() over(
partition by company,industry,location,stage,country,funds_raised_millions,
total_laid_off, percentage_laid_off, `date`) as row_num
from layoffs_staging
)
select * 
from duplicate_cte
where row_num > 1 ;

-- ------------------------------------------

select *
from layoffs_staging
where company = 'Cazoo';


-- ------------------------------------------
-- now you may want to write it duplicates this:
WITH DELETE_CTE AS 
(
SELECT *
FROM (
	SELECT company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging
) duplicates
WHERE 
	row_num > 1
)
DELETE
FROM DELETE_CTE
;

-- this above query will give us an error so we need to follow these follwing steps
-- -- go to layoff_staging, double click then  copy to clipboard,then create statement ,then ctr+ v
-- we are adding another one coloumn in layoff_staging to remove duplicates by creating another staging table
-- ------------------------------------------


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


select *
from layoffs_staging2;

-- in the above step what we did was , we want to now remove duplicates , so we created cte to check our duplicates ,
-- now we created another table called layoff_staging2 , where we will be inserting data ,which will have no duplicates from layoff_staging


Insert into layoffs_staging2
select *, 
row_number() over(
partition by company,industry,location,stage,country,funds_raised_millions,
total_laid_off, percentage_laid_off, `date`) as row_num
from layoffs_staging;

select *
from layoffs_staging2
where row_num >1;

-- now lets delete those duplicates in this copied table

Delete
from layoffs_staging2
where row_num >1;

-- All duplicates are now removed

-- STANDARDIZING DATA
-- there is space in front of few company names ,lets trim it

select company ,trim(company)
from layoffs_staging2;

-- Now lets update trimmed comapany names to table

update layoffs_staging2
set company = trim(company);

select * from layoffs_staging2;


select distinct industry
from layoffs_staging2
order by industry;    -- OR order by 1

-- If we observe we see blank and null values in this column
-- crypto , crypto currency and cryptoCurrency are all same

select *
from layoffs_staging2
where industry like 'Crypto%';

-- Now lets update all crypto like industries to "Crypto"

update layoffs_staging2
set industry = 'Crypto'
where industry like 'Crypto%';

-- now all are updated

select distinct industry
from layoffs_staging2
order by industry;

select distinct location
from layoffs_staging2
order by 1;

select distinct country
from layoffs_staging2
order by 1;

-- United states , united states. both are same

select country 
from layoffs_staging2
where country like "United States%";

-- now trim and trail the dot in the end of the string

select distinct country, trim(Trailing '.' from Country)
from layoffs_staging2
order by country;

update layoffs_staging2
set country = trim(Trailing '.' from Country)
where country like "United States%";

-- updated 

-- Next we need to change is type of "Date" column , which is in text type , this should be changed to "date" type 
-- this is required when we are dealing with time series problems , we can work with that if we have date data in test format

select `date`,
str_to_date(`date`,'%m/%d/%Y')  -- str_to_date(which col, what is the current format of the date in that column)
from layoffs_staging2;

update layoffs_staging2
set `date` = str_to_date(`date`,'%m/%d/%Y');

-- now we have changed the format, lets change the type now

Alter table layoffs_staging2
Modify column `date` DATE;

select * from layoffs_staging2;


-- --------------------------------------------------------
-- Now let's try to clean null and blank values
-- If we look into industry col , we had few null and blank rows

select *
from layoffs_staging2
where industry is null
or industry = '';

-- now lets check for other records where company is Airbnb , if it has industry row in it 

select *
from layoffs_staging2
where company = 'Airbnb';



-- yes , we have it and industry is Travel
-- lets do this for all other companies as well
-- 'Bally''s Interactive'


-- to get the industry if it exists in other rows , we perform self join 
-- We're trying to fill in missing values for industry by looking at other rows from the same company and location.
-- Rows in t1 that have a NULL or empty industry
-- Finds a matching row in t2 (same company & location) that does have a non-null industry
-- Returns both versions (the one missing industry and the one with it), so you can:


select * 
from  layoffs_staging2 t1
join layoffs_staging2 t2
     on t1.company = t2.company
     and t1.location = t2.location
where (t1.industry is null or t1.industry = '')
and t2.industry is not null;

select t1.industry , t2.industry
from  layoffs_staging2 t1
join layoffs_staging2 t2
     on t1.company = t2.company
     and t1.location = t2.location
where (t1.industry is null or t1.industry = '')
and t2.industry is not null;

-- this is messy because we have both blank and null  values , lets make all blank values as null

update layoffs_staging2
set industry = null
where industry = '';

-- now run this query

select t1.industry , t2.industry
from  layoffs_staging2 t1
join layoffs_staging2 t2
     on t1.company = t2.company
     and t1.location = t2.location
where (t1.industry is null )
and t2.industry is not null;

update layoffs_staging2 t1
join layoffs_staging2 t2
     on t1.company = t2.company
     and t1.location = t2.location
set t1.industry = t2.industry
	where t1.industry is null
	and t2.industry is not null;
    
-- check
select *
from layoffs_staging2
where company = 'Airbnb';

select *
from layoffs_staging2
where company like 'Bally%';
    
select * 
from layoffs_staging2;

-- ---------------------------------------------------------------------------------------
select * 
from layoffs_staging2
where total_laid_off is null;  

-- if this col is absent , then we have percentage_laid_off , which can be reffered ,but if both are null then they are of no use
-- but even if percentage_laid_off is present ,we don't have total number of employees ,with which we could find out total_laid_off
-- Therefore we can delete all these rows which are not required ,as they have no values

select * 
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;  

delete
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;  

select * 
from layoffs_staging2;

-- now let's remove row_num col

Alter table layoffs_staging2
drop column row_num;

select * 
from layoffs_staging2;