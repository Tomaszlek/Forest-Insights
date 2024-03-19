--tworzenie tabeli a następnie import danych
CREATE TABLE forests(
	CountryID INT PRIMARY KEY,
	"Country and Area" TEXT,
	"Forest Area, 1990" NUMERIC(10,2),
	"Forest Area, 2000" NUMERIC(10,2),
	"Forest Area, 2010" NUMERIC(10,2),
	"Forest Area, 2015" NUMERIC(10,2),
	"Forest Area, 2020" NUMERIC(10,2),
	"Total Land Area, 2020"  NUMERIC(10,2),
	"Forest Area as a Proportion of Total Land Area, 2020" NUMERIC(10,2),
	"Deforestation, 2015-2020" NUMERIC(10,2),
	"Total Forest Area Affected by Fire, 2015" NUMERIC(10,2)
);

--sprawdzenie zawartości danych
SELECT * FROM forests LIMIT 100;

--najpierw sprawdźmy najbardziej i najmniej zalesione kraje obecnie(2020 rok)
SELECT
    "Country and Area",
    "Forest Area, 2020",
    ROW_NUMBER() OVER (ORDER BY "Forest Area, 2020" DESC) AS forest_area_rank
FROM
    forests
WHERE
    countryid <> 1.0
LIMIT 10;
--TOP 5 NAJBARDZIEJ ZALESIONYCH: ROSJA, BRAZYLIA, KANADA, USA, CHINY

SELECT
    "Country and Area",
    "Forest Area, 2020",
    ROW_NUMBER() OVER (ORDER BY "Forest Area, 2020") AS forest_area_rank
FROM
    forests
WHERE
    countryid <> 1.0
LIMIT 10;
--TOP 5 NAJMNIEJ ZALESIONYCH: MONAKO, HOLY SEE, Falklandy, GIBRALTAR, NAURU, ZALESIENIE W KAZDYM Z NICH TO 0%

SELECT
    CORR("Total Land Area, 2020", "Forest Area as a Proportion of Total Land Area, 2020") AS Correlation
FROM
    forests;
--Nie istnieje korelacja pomiędzy wielkością kraju, a procentem zalesienia. Oznacza to, że zalesienie nie zależy od wielkości kraju

--SPRAWDŹMY TERAZ RÓŻNICĘ W ZALESIENIU NA PRZESTRZENI LAT(WYZNACZYMY TREND DLA KAZDEGO Z PANSTW)
CREATE MATERIALIZED VIEW Changes_in_forestation AS(
	SELECT
		"Country and Area" AS Countries,
		"Forest Area, 1990" AS Forest_area,
		("Forest Area, 2000" - "Forest Area, 1990") AS Forest_Area_Change_1990_2000,
		("Forest Area, 2010" - "Forest Area, 2000") AS Forest_Area_Change_2000_2010,
		("Forest Area, 2015" - "Forest Area, 2010") AS Forest_Area_Change_2010_2015,
		("Forest Area, 2020" - "Forest Area, 2015") AS Forest_Area_Change_2015_2020,
		("Forest Area, 2020" - "Forest Area, 1990") AS Total_forest_area_change
	FROM
		forests
	WHERE countryid <> 1.0
)
	
--SPRAWDZMY JAK WYGLADAJA NASZE DANE
SELECT * FROM Changes_in_forestation;

--NA PODSTAWIE TRENDU ZNAJDZIEMY PANSTWA KTORE MIALY TREND DODATNI I TE KTÓRE MIAŁY UJEMNY
SELECT COUNT(Countries)
FROM Changes_in_forestation
WHERE Total_forest_area_change > 0;
--91 PANSTW MIAŁO TREND DODATNI

SELECT COUNT(Countries)
FROM Changes_in_forestation
WHERE Total_forest_area_change < 0;
--99 PANSTW MIAŁO TREND UJEMNY, POZOSTAŁE 46 PANSTW MIALY TREND NA 0, CO MOZE BYC ZWIAZANE Z BRAKIEM WYSTARCZAJACYCH DANYCH

--SPRAWDZMY TREND GLOBALNY:
SELECT
    AVG("Forest Area, 2000" - "Forest Area, 1990") AS "Avg_Change_1990_2000",
    AVG("Forest Area, 2010" - "Forest Area, 2000") AS "Avg_Change_2000_2010",
    AVG("Forest Area, 2015" - "Forest Area, 2010") AS "Avg_Change_2010_2015",
    AVG("Forest Area, 2020" - "Forest Area, 2015") AS "Avg_Change_2015_2020"
FROM
    forests
WHERE
    countryid <> 1.0;

--TREND JEST PRZEWAŻNIE UJEMNY, NATOMIAST SAMA ŚREDNIA NIEWIELE NAM MÓWI Z UWAGI NA ROZPIĘTOŚĆ KRAJÓW POD WZGLĘDEM TERENU

--SPRAWDZMY, KTÓRE PAŃSTWA MIAŁY NAJWIĘKSZE POSTĘPY W ZALESIANIU PROCENTOWO, A KTÓRE NAJGORSZY
SELECT
	Countries,
	ROUND((Total_forest_area_change / Forest_area) * 100, 2) AS Forestation_percentage_change
FROM
	Changes_in_forestation
WHERE
	Forest_area > 0
ORDER BY 2 DESC
LIMIT 10;
--NAJLEPSZY JEST BAHRAJN(+215%), ISLANDIA(+200,8%) I URUGWAJ(+154,7%)

SELECT
	Countries,
	ROUND((Total_forest_area_change / Forest_area) * 100, 2) AS Forestation_percentage_change
FROM
	Changes_in_forestation
WHERE
	Forest_area > 0
ORDER BY 2 
LIMIT 10;
--NAJGORZEJ WYPADAJA TAKIE KRAJE JAK WYBRZEZE KOŚCI SŁONIOWEJ(-64%), NIKARAGUA(-47%), NIGER(-44,4%)

--SPRAWDŹMY, JAKI WPŁYW MIAŁO WYLESIENIE W OSTATNICH LATACH, A JAKI POŻARY
SELECT
	c.Countries,
    ROUND(COALESCE(f."Deforestation, 2015-2020"/ABS(c."forest_area_change_2015_2020"), 0) * 100, 2) AS "Procent wylesienia",
	ROUND(COALESCE(f."Total Forest Area Affected by Fire, 2015"/ABS(c."forest_area_change_2015_2020"), 0) * 100, 2) AS "Procent spalonych lasów"
FROM
    forests f
FULL JOIN Changes_in_forestation C ON f."Country and Area" = c.Countries
WHERE
    f.countryid <> 1.0 AND c."forest_area_change_2015_2020" > 0
ORDER BY 3 DESC, 2 DESC;

--ISTNIEJĄ DANE TYLKO DLA 69 SPOŚRÓD 235 KRAJÓW I REGIONÓW NA ŚWIECIE, NAJBARDZIEJ PROCENTOWO PRZEZ 5 LAT WYLESIŁA SIĘ MOŁDAWIA(340%) I AZERBEJDŻAN(160,28%)
--NAJWIĘCEJ LASÓW STRAWIŁ POŻAR W AUSTRALII(1622,49%), rosji(721,23%) i znowu Mołdawii(350%).
--NALEŻY MIEĆ NA UWADZE, ŻE TO SĄ DANE W PEAKU, A ZMIANA ZALESIENIA NASTĘPUJE PRZEZ 5 KOLEJNYCH LAT, WIĘC MOGŁY BYĆ TO ZARÓWNO ZMIANY CHWILOWE JAK I ZASADZANIE NOWYCH LASÓW
--POMIMO SPOREJ WYCINKI
