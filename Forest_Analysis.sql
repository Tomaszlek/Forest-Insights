--Creating table and then importing data from CSV file using COPY keyword
CREATE TABLE forests(
	CountryID INT PRIMARY KEY,
	Country TEXT,
	Forest_area_1990 NUMERIC(10,2),
	Forest_area_2000 NUMERIC(10,2),
	Forest_area_2010 NUMERIC(10,2),
	Forest_area_2015 NUMERIC(10,2),
	Forest_area_2020 NUMERIC(10,2),
	Total_land_area_2020  NUMERIC(10,2),
	Forest_area_as_a_percentage_of_total_area_2020 NUMERIC(10,2),
	Deforestation_2015_2020 NUMERIC(10,2),
	Burnt_forest_area_2020 NUMERIC(10,2)
);

--checking whether data were correctly copied to the table
SELECT * FROM forests LIMIT 100;

--first, let's check the most and least forested countries today(2020)
SELECT
    Country,
    Forest_area_2020,
    ROW_NUMBER() OVER (ORDER BY Forest_area_2020 DESC) AS forest_area_rank
FROM
    forests
WHERE
    Countryid <> 1.0
LIMIT 10;
--TOP 5 Most Forested: Russia, Brazil, China, Canada, USA

SELECT
    Country,
    Forest_area_2020,
    ROW_NUMBER() OVER (ORDER BY Forest_area_2020) AS forest_area_rank
FROM
    forests
WHERE
    Countryid <> 1.0
LIMIT 10;
--TOP 5 Least Forested: MONACO, HOLY SEE, FALCELANDS, GIBRALTAR, NAURU, each with a percentage of forestation equal to 0%

SELECT
    CORR(Total_land_area_2020, Forest_area_as_a_percentage_2020) AS Correlation
FROM
    forests;
--There is no correlation between the size of the country and the percentage of forestation. 
--It means that forestation does not depend on the size of the country

--To make further analysis, let's create a materialized view to store the data needed to conduct the deforestation analysis
CREATE MATERIALIZED VIEW Changes_in_forestation AS(
	SELECT
		Country AS Countries,
		Forest_area_1990 AS Forest_area,
		(Forest_area_2000 - Forest_area_1990) AS Forest_Area_Change_1990_2000,
		(Forest_area_2010 - Forest_area_2000) AS Forest_Area_Change_2000_2010,
		(Forest_area_2015 - Forest_area_2010) AS Forest_Area_Change_2010_2015,
		(Forest_area_2020 - Forest_area_2015) AS Forest_Area_Change_2015_2020,
		(Forest_area_2020 - Forest_area_1990) AS Total_forest_area_change
	FROM
		forests
	WHERE Countryid <> 1.0
)
	
--checking correctness
SELECT * FROM Changes_in_forestation;

--ON THE BASIS OF THE TREND WE WILL FIND COUNTRIES THAT HAD A POSITIVE TREND AND THOSE THAT HAD A NEGATIVE ONE
SELECT COUNT(Countries)
FROM Changes_in_forestation
WHERE Total_forest_area_change > 0;
--91 Countries have had a positive trend

SELECT COUNT(Countries)
FROM Changes_in_forestation
WHERE Total_forest_area_change < 0;
--99 Countries have had a negative trend,
--THE OTHER 46 COUNTRIES HAD A TREND OF 0, WHICH MAY BE RELATED TO THE LACK OF SUFFICIENT DATA

--Let's check the global trend over the years
SELECT
    AVG(Forest_area_2000 - Forest_area_1990) AS "Avg_Change_1990_2000",
    AVG(Forest_area_2010 - Forest_area_2000) AS "Avg_Change_2000_2010",
    AVG(Forest_area_2015 - Forest_area_2010) AS "Avg_Change_2010_2015",
    AVG(Forest_area_2020 - Forest_area_2015) AS "Avg_Change_2015_2020"
FROM
    forests
WHERE
    Countryid <> 1.0;

--TREND IS MOSTLY NEGATIVE, WHILE THE AVERAGE ALONE TELLS US LITTLE DUE TO THE SPREAD OF COUNTRIES IN TERMS OF TERRAIN

--LET'S SEE WHICH COUNTRIES HAVE HAD THE MOST PROGRESS IN REFORESTATION IN PERCENTAGE TERMS, AND WHICH HAVE HAD THE WORST
SELECT
	Countries,
	ROUND((Total_forest_area_change / Forest_area) * 100, 2) AS Forestation_percentage_change
FROM
	Changes_in_forestation
WHERE
	Forest_area > 0
ORDER BY 2 DESC
LIMIT 10;
--BAHRAIN(+215%), ICELAND(+200.8%) AND URUGUAY(+154.7%) ARE THE BEST ONES

SELECT
	Countries,
	ROUND((Total_forest_area_change / Forest_area) * 100, 2) AS Forestation_percentage_change
FROM
	Changes_in_forestation
WHERE
	Forest_area > 0
ORDER BY 2 
LIMIT 10;
--THE WORST PERFORMING COUNTRIES ARE IVORY COAST (-64%), NICARAGUA (-47%), NIGER (-44.4%)

--I'LL TRY TO EXAMINE THE IMPACT OF DEFORESTATION IN RECENT YEARS AND FIRES
SELECT
	c.Countries,
    ROUND(COALESCE(f.Deforestation_2015_2020/ABS(c.Forest_Area_Change_2015_2020), 0) * 100, 2) AS "Procent wylesienia",
	ROUND(COALESCE(f.Burnt_forest_area_2020/ABS(c.Forest_Area_Change_2015_2020), 0) * 100, 2) AS "Procent spalonych lasów"
FROM
    forests f
FULL JOIN Changes_in_forestation C ON f.Country = c.Countries
WHERE
    f.Countryid <> 1.0 AND c.Forest_Area_Change_2015_2020 > 0
ORDER BY 3 DESC, 2 DESC;

--DATA ARE AVAILABLE FOR ONLY 69 OUT OF 235 COUNTRIES AND REGIONS IN THE WORLD, THE MOST DEFORESTED COUNTRIES IN 5 YEARS ARE MOLDOVA (340%) AND AZERBAIJAN (160.28%)
--THE MOST FOREST LOST BY FIRE WERE AUSTRALIA (1622.49%), RUSSIA (721.23%) and again MOLDOVA (350%).
--IT SHOULD BE BORNE IN MIND THAT THESE ARE PEAK FIGURES AND THE CHANGE IN FOREST COVER OCCURS OVER 5 CONSECUTIVE YEARS, SO IT COULD HAVE BEEN BOTH TEMPORARY CHANGES AND THE PLANTING OF NEW FORESTS
--DESPITE SIGNIFICANT DEFORESTATION
