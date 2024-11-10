--Goal For this project
--1.Clean this Data
SELECT *
FROM [New York Housing Market].[dbo].[NY Housing Dataset]
--After careful consideration of the data I'm assuming that the data was scrapped off of zillow or some real estate website as it contains basic information of the property
--The data also contains information on whether the property has been sold, in process or contingent
--There are many different columns
--Brokertitle:Who is selling or sold the property
--TYPE: What kind of property it is (House, Townhouse,Co-op, etc)
--PRICE:Pretty obvious the price of the property
--Beds:Total Bedrooms in the property
--Bath:Total Bathrooms in the house
--PROPERTYSQFT:The size of the property
--Main Address/Formatted Address: Address of the property
--Many of the sub columns of the main address/ formatted address are disorganized and well be using the formatted address to create seperate columns
--Longitude/Latitude:Coordinates of our property

--For out purpose with this dataset there are a few columns we won't be needing. 
--For example the longitude and the latitude, also the main address as the main address and the formatted address are repetitve and the reason why I am using the formatted address versus the main address is because it is easier to parsename
--After careful consideration of our dataset there are a few columns that needs to be trimmed as the brokertitle, the suffixes of the title
USE [New York Housing Market]
GO

--Time to collect information about our table
SELECT *
FROM [New York Housing Market].INFORMATION_SCHEMA.COLUMNS
--With the given data, the values that have float type data are the Price, Beds, Bath, and PropertySQFT

ALTER TABLE [NY HOUSING DATASET]
ALTER COLUMN BEDS INT

--Count the amount of properties on the market
SELECT count(FORMATTED_ADDRESS)
FROM [NY Housing Dataset]

SELECT latitude,longitude
FROM [NY Housing Dataset]

--I don't think I'll be needing the latitude and longitude columns therefore to make things simpler I'll be deleting these columns
ALTER TABLE [New York Housing Market].[dbo].[NY Housing Dataset]
DROP COlUMN latitude,longitude

--After careful review of this data there were many columns that weren't needed as it would get repetitve and deleting the columns
--for reasons later 
ALTER TABLE[New York Housing Market].[dbo].[NY Housing Dataset]
DROP COLUMN ADDRESS, STATE, MAIN_ADDRESS, LONG_NAME, ADMINISTRATIVE_AREA_LEVEL_2

--Cleaning the Formatted Address
SELECT parsename(replace(formatted_Address,',','.'),1) as [COUNTRY],
substring(parsename(replace(formatted_Address,',','.'),2),1,3) as [STATE], 
substring(parsename(replace(formatted_Address,',','.'),2),4,len(parsename(replace(formatted_Address,',','.'),2))-3) AS [ZIP],
parsename(replace(formatted_Address,',','.'),3) AS [CITY], 
parsename(replace(formatted_Address,',','.'),4) AS [STREET]
FROM [New York Housing Market].[dbo].[NY Housing Dataset]
--Parsename is working by seperating the formatted address and to do this we first replace the ',' as '.' due to parsename nature
--Because the zip and state are in the same row we are "substringing" it. Because the first 2 characters are generally the state then 
--we substring the first 2 call it the state column then we substring the rest as parsename(replace(formatted_Address,',','.'),2)
--is what we are substring, start on the 4th space because that's where the zip code starts and we extract the first 3

--There are a few rows where the property sqft are not put in integer format therefore I'll be converting the values to integers
UPDATE [New York Housing Market].[dbo].[NY Housing Dataset]
SET PropertySQFT = convert(int,PropertySQFT)

SELECT Administrative_area_level_2
FROM [New York Housing Market].[dbo].[NY Housing Dataset]
WHERE Administrative_area_level_2 not like 'United States'

SELECT Brokertitle, avg(price)
FROM [New York Housing Market].[dbo].[NY Housing Dataset]
GROUP BY BrokerTitle

--I noticed that all the Brokertitle contains "Brokered by" so to clean the data up some more it would probably be best to trim it
ALTER TABLE [New York Housing Market].[dbo].[NY Housing Dataset]
ADD Brokerage_Company nvarchar(255)

UPDATE [New York Housing Market].[dbo].[NY Housing Dataset]
SET Brokerage_Company = TRIM(REPLACE(Brokertitle,'Brokered by',''))

ALTER TABLE [New York Housing Market].[dbo].[NY Housing Dataset]
DROP COLUMN BROKERTITLE

SELECT TYPE
FROM [New York Housing Market].[dbo].[NY Housing Dataset]
GROUP BY TYPE

-- Another question I can ask is what is the average price for property across different zip codes
--We have previously cleaned the Formatted address so all we need to do is replace it into the dataset
ALTER TABLE [New York Housing Market].[dbo].[NY Housing Dataset]
ADD Address nvarchar(255)

ALTER TABLE [New York Housing Market].[dbo].[NY Housing Dataset]
ADD CITY NVARCHAR(255)

ALTER TABLE [New York Housing Market].[dbo].[NY Housing Dataset]
ADD STATE NVARCHAR(255)

ALTER TABLE [New York Housing Market].[dbo].[NY Housing Dataset]
ADD ZIP_CODE NVARCHAR(255)

ALTER TABLE [New York Housing Market].[dbo].[NY Housing Dataset]
ADD COUNTRY NVARCHAR(255)

UPDATE [New York Housing Market].[dbo].[NY Housing Dataset]
SET ADDRESS = parsename(replace(formatted_Address,',','.'),4)

UPDATE [New York Housing Market].[dbo].[NY Housing Dataset]
SET CITY = parsename(replace(formatted_Address,',','.'),3)

UPDATE [New York Housing Market].[dbo].[NY Housing Dataset]
SET ZIP_CODE = substring(parsename(replace(formatted_Address,',','.'),2),4,len(parsename(replace(formatted_Address,',','.'),2))-3)

UPDATE [New York Housing Market].[dbo].[NY Housing Dataset]
SET STATE = substring(parsename(replace(formatted_Address,',','.'),2),1,3) 

UPDATE [New York Housing Market].[DBO].[NY Housing Dataset]
SET COUNTRY = PARSENAME(REPLACE(FORMATTED_ADDRESS,',','.'),1)

--We are almost done cleaning as for the type of housing it is we are not concerened with whether or not it's 
--for sale of not so well just remove that from the column
UPDATE [New York Housing Market].dbo.[NY Housing Dataset]
SET TYPE = TRIM(REPLACE(TYPE,'for sale',''))

--Now that most of the data is cleaned we can start doing some research on out data
--What is the mean price of the housing
SELECT cast(avg(price) as INT) as AvgPrice
from [New York Housing Market].dbo.[NY Housing Dataset]
--The given average is 2356940
--This mean is probably squed due to the outlier 
--Now to compare the most expensive properties to the least expensive properties
SELECT TOP 10 TYPE,PRICE,FORMATTED_ADDRESS, Brokerage_Company
FROM [New York Housing Market].dbo.[NY Housing Dataset]
ORDER BY PRICE DESC
--Seems like there is an error in the most expensive house on the market. 
--Apparently a house on staten island is worth 2,147,483,647 and after researching I have found that zillow estimates the house to be $2,286,100
--Now to change the price
UPDATE [New York Housing Market].dbo.[NY Housing Dataset]
SET PRICE = 2286100
WHERE FORMATTED_ADDRESS = '6659 Amboy Rd, Staten Island, NY 10309, USA'

--After fixing the error the new most expensive property in this dataset is the condo penthouse located at Central Park Tower costing $195,000,000 with 7 beds, 11 baths, and 17,545 sqft (Found on Zillow) 

--Now to find the minimum priced property in this dataset
--The first few houses are rental properties which explains why the price is must lower than I thought it would
--Some more insight on this dataset is that most of these prices are from pre 2020 so most of these properties do not reflect the current day prices
SELECT TOP 10 TYPE, Price, Formatted_Address, Brokerage_Company
FROM [NY Housing Dataset]
ORDER BY PRICE 

--Because I'm only focusing on properties that are on sale not for rent the minimum price would be the $60,000 Condo that is a studio, 1 bath, and 445 square feet according to zillow located in Midtown.

--Calculating the quartiles
SELECT TOP 1
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY price) OVER () AS Q1,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY price) OVER () AS Q2,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY price) OVER () AS Q3
FROM
    [NY Housing Dataset];
	
--USING PERCENTILE_CONT to calculate the percentile of the price
--Q1 = 499000
--Q2 = 825000
--Q3 = 1495000


--What is the average price of the properties each brokerage company is selling
Select Brokerage_Company, round(avg(price),0) as AveragePrice, count(Brokerage_Company) as PropertiesSelling
FROM [New York Housing Market].dbo.[NY Housing Dataset]
GROUP BY Brokerage_Company
ORDER BY AveragePrice DESC
--Here we see the average housing prices for each brokerage company and we can see that Anne Lopa Real Estate has the highest Average price
--but with only 2 properties than compared to COMPASS brokerage selling 457 properties. 

--Calculate the marketshare of each broker
SELECT brokerage_company, COUNT(brokerage_company) as 'Number of listings per broker'
FROM [NY Housing Dataset]
GROUP BY Brokerage_Company
order by 'Number of listings per broker' desc

--Now to calculate the percentages
WITH Marketshare AS (
    SELECT brokerage_company, COUNT(brokerage_company) AS Number_of_listings_per_broker
    FROM [NY Housing Dataset]
    GROUP BY brokerage_company
)
SELECT *, round(Number_of_listings_per_broker * 100.0 / sum(Number_of_listings_per_broker) over(),2) as perc_Marketshare
FROM Marketshare
ORDER BY perc_Marketshare desc

--We can see here that COMPASS holds the greatest marketshare at about 9.52% 

SELECT SUBLOCALITY, COUNT(SUBLOCALITY) as PropPerCounty
FROM [New York Housing Market].dbo.[NY Housing Dataset]
GROUP BY SUBLOCALITY

--Now lets find the average sqft of each type of property by the type and zipcode
WITH Averagesqft (zip_code,type,avgsqft) as(
	SELECT ZIP_CODE,TYPE,AVG(PROPERTYSQFT) AS AvgSqft
	FROM [New York Housing Market].[dbo].[NY Housing Dataset]
	WHERE PROPERTYSQFT IS NOT NULL AND TYPE not like ''
	GROUP BY ZIP_CODE, TYPE
	)

select *
fROM Averagesqft
order by avgsqft

--Finally consider the properties that are selling above the average sqft
WITH AvgPricePerSQFT_by_location (AvgPriceperSQFT, ZIP_CODE) as (
	SELECT avg(price/PROPERTYSQFT) as AvgPriceperSQFT, ZIP_CODE
	FROM [New York Housing Market].dbo.[NY Housing Dataset]
	GROUP BY ZIP_CODE
	)
SELECT housing.FORMATTED_ADDRESS, housing.price, housing.PROPERTYSQFT,housing.price/housing.PROPERTYSQFT as PricePerSQFT, average.AvgPriceperSQFT
FROM [New York Housing Market].dbo.[NY Housing Dataset] housing
	join AvgPricePerSQFT_by_location average on housing.ZIP_CODE = average.ZIP_CODE
WHERE housing.price/housing.PROPERTYSQFT > average.AvgPriceperSQFT
ORDER BY housing.price 