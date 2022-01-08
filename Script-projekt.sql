
--info o tab.covid19_tests

SELECT  
	min(date),
	max(date),
	count(distinct (date))
FROM covid19_tests ct 

SELECT 
	count(DISTINCT country)
FROM covid19_tests ct 

--info o tab.economies

SELECT
DISTINCT country
FROM economies e 

SELECT
DISTINCT year
FROM economies e 

SELECT 
	country,
	GDP,
	gini,
	mortaliy_under5 
FROM economies e 
WHERE year = '2020'

--info o tab.weather

SELECT
COUNT(DISTINCT city)
FROM weather w 

SELECT
DISTINCT city
FROM weather w 

SELECT 
DISTINCT c.country
FROM weather w 
LEFT JOIN countries c 
ON c.capital_city = w.city 


SELECT
	min(date),
	max(date),
	count(distinct (date))
FROM weather w 

--info o tab.life_expectancy

SELECT
count(DISTINCT country)
FROM life_expectancy le

SELECT 
count(DISTINCT country)
FROM life_expectancy le
WHERE iso3 IS NOT NULL

SELECT 
MIN(year),
MAX(year)
FROM life_expectancy le 

--info o tab. covid19_basic_differences

SELECT 
	MIN(date),
	MAX(date), 
	count(DISTINCT date)
FROM covid19_basic_differences cbd 

SELECT 
	count(DISTINCT country)
FROM covid19_basic_differences cbd 

--info o tab. religions

SELECT 
  DISTINCT year
FROM religions r 
  
SELECT
DISTINCT country
FROM religions

-- binární promìnná víkend/pracovní den, roèní období

CREATE OR REPLACE VIEW v_weekday AS
SELECT 
	*,
	weekday(date) as den,
FROM covid19_basic_differences cbd 

CREATE TABLE t_weekday_binarne_season AS
SELECT
	date,
	country,
	confirmed,
	deaths,
	recovered,
	CASE WHEN den = '5' OR den = '6' THEN 1
	ELSE 0 END AS weekday,
	CASE WHEN date >= '2019-12-22' AND date <= '2020-03-19' THEN '3'
		 WHEN date >= '2020-03-20' AND date <= '2020-06-19' THEN '0'
		 WHEN date >= '2020-06-20' AND date <= '2020-09-21' THEN '1'
		 WHEN date >= '2020-09-22' AND date <= '2020-12-20' THEN '2'
		 WHEN date >= '2020-12-21' AND date <= '2021-03-19' THEN '3'
		 WHEN date >= '2021-03-20' AND date <= '2021-06-20' THEN '0'
		 ELSE 'error' END AS season,
	substring(date,1,4) as year
FROM v_weekday;


  
--podíly jednotlivých náboženství

CREATE TABLE tmp_religion_2010 AS
SELECT
  	*
FROM religions r 
WHERE year = 2010;

CREATE TABLE tmp_population2010 AS
SELECT 
	*
FROM economies e 
WHERE year = 2010
  AND country IN (SELECT 
  					country
  				  FROM religions)

CREATE TABLE tmp_religion_sum_population2010 AS  				  
SELECT
	tr.year,
	tr.country,
	tr.religion,
	tr.population AS rel_population,
	tp.year AS country_year,
	tp.population AS sum_population
FROM tmp_religion_2010 tr 
LEFT JOIN tmp_population2010 tp 
ON tr.country = tp.country

CREATE TABLE t_percentage_individual_religion
SELECT 
	*,
	round((rel_population * 100 / sum_population),2) AS percentage_religion
FROM tmp_religion_sum_population2010 trsp 

SELECT 
	*
FROM t_percentage_individual_religion tpir
WHERE percentage_religion > 100

--rozdíl mezi oèekávanou dobou dožití v roce 1965 a v roce 2015

CREATE TABLE tmp_life_expectancy_1965 AS
SELECT 
	*
FROM life_expectancy le 
WHERE year = '1965' 

CREATE TABLE tmp_life_expectancy_2015 AS
SELECT
	*
FROM life_expectancy le 
WHERE year = '2015'

CREATE TABLE tmp_life_expectancy_join AS
SELECT
	tle.country,
	tle.year AS year_1965,
	tle.life_expectancy AS life_expectancy_1965,
	tle2.year AS year_2015,
	tle2.life_expectancy AS life_expectancy_2015
FROM tmp_life_expectancy_1965 tle 
LEFT JOIN tmp_life_expectancy_2015 tle2 
ON tle.country = tle2.country

CREATE TABLE t_life_expectancy_difference AS
SELECT
	*,
	round((life_expectancy_2015 - life_expectancy_1965),2) AS life_expectancy_difference_2015_1965
FROM tmp_life_expectancy_join tlej 
  

-- tabulka covid19_basic_differences + covid19_tests

CREATE TABLE t_covid_diff_test AS
SELECT 
	t.date,
	t.country,
	t.confirmed,
	t.deaths,
	t.recovered,
	t.weekday,
	t.season,
	ct.tests_performed
	FROM t_weekday_binarne_season t
LEFT JOIN covid19_tests ct 
 ON t.country = ct.country 
AND t.date = ct.date
ORDER BY country

CREATE TABLE tmp_economies2018
SELECT 
	*
FROM economies e 
WHERE `year` = '2018'

CREATE TABLE t_covid_diff_test_economies
SELECT 
	tc.*,
	c.population_density,
	c.median_age_2018 ,
	te.GDP,
	te.gini,
	te.mortaliy_under5 
FROM t_covid_diff_test tc
RIGHT JOIN countries c 
ON tc.country = c.country 
RIGHT JOIN tmp_economies2018 te 
ON tc.country = te.country 


CREATE TABLE t_covid_diff_test_economies_life_exp AS
SELECT 
	tc.*,
	tl.life_expectancy_difference_2015_1965 
FROM t_covid_diff_test_economies tc 
LEFT JOIN t_life_expectancy_difference tl
ON tc.country = tl.country 

CREATE TABLE t_almost_all AS
SELECT 
	ta.*,
	tp.religion,
	tp.rel_population,
	tp.percentage_religion 
FROM t_covid_diff_test_economies_life_exp ta
RIGHT JOIN t_percentage_individual_religion tp 
ON ta.country = tp.country

--POCASI
-- mìsta, která lze spárovat se zemí v countries

CREATE TABLE tmp_weather_ccity AS
SELECT 
	DISTINCT city
FROM weather w 
WHERE city IN (SELECT 
				capital_city
				FROM countries c)

-- mìsta, která nelze spárovat se zemí v countries
SELECT 
	DISTINCT city
FROM weather 			
EXCEPT
SELECT
	city
FROM tmp_weather_ccity vwc 

--zrušení suffixù

CREATE TABLE t_weather_no_suffix AS
SELECT 
	`index`,
	time,
	date,
	city,
	REPLACE(temp, '°c', '') AS temp_°c,
	REPLACE(gust, 'km/h', '') AS gust_kmh,
	REPLACE(rain, 'mm', '') AS rain_mm,
FROM weather w 

--zmìna datových typù

CREATE TABLE t_weather_copy AS
SELECT
	`index`,
	CAST(substring(date,1,10) AS DATE) AS date_d,
	time,
	city,
	CAST(temp_°c AS double) AS temp_c,
	CAST(gust_kmh AS double) AS gust_km_h,
	CAST(rain_mm AS double) AS rain_mm
FROM t_weather_no_suffix

--úprava názvù mìst dle názvù v tab.countries pro jejich párování se zemìmi

UPDATE t_weather_copy
SET city = 'Praha' WHERE city = 'Prague'

UPDATE t_weather_copy
SET city = 'Athenai' WHERE city = 'Athens'

UPDATE t_weather_copy
SET city = 'Bruxelles[Brussel]' WHERE city = 'Brussels'

UPDATE t_weather_copy
SET city = 'Bucuresti' WHERE city = 'Bucharest'

UPDATE t_weather_copy
SET city = 'Helsinki[Helsingfors]' WHERE city = 'Helsinki'

UPDATE t_weather_copy
SET city = 'Kyiv' WHERE city = 'Kiev'

UPDATE t_weather_copy
SET city = 'Lisboa' WHERE city = 'Lisbon'

UPDATE t_weather_copy
SET city = 'Luxembourt[Luxemburg/L' WHERE city = 'Luxembourg'

UPDATE t_weather_copy
SET city = 'Roma' WHERE city = 'Rome'

UPDATE t_weather_copy
SET city = 'Wien' WHERE city = 'Vienna'

UPDATE t_weather_copy
SET city = 'Warszawa' WHERE city = 'Warsaw'

--dosazení zemí do tabulky weather

CREATE TABLE t_weather_copy_country AS
SELECT
	twc.*,
	c.country
FROM t_weather_copy twc 
RIGHT JOIN countries c 
ON twc.city = c.capital_city 

--výpoèet prùmìrný denní teploty

CREATE TABLE t_weather_avg_temp
SELECT 
	date_d ,
	country , 
	AVG(temp_c) AS avg_day_temp
FROM t_weather_copy_country twc 
WHERE `time` IN ('06:00', '09:00', '12:00', '15:00', '18:00')
GROUP BY country , date_d 

--výpoèet maximální síly vìtru

CREATE TABLE t_weather_max_gust
SELECT 
	date_d,
	country ,
	MAX(gust_km_h) AS max_gust
FROM t_weather_copy_country twc
WHERE time IN ('00:00', '03:00', '06:00', '09:00', '12:00', '15:00', '18:00', '21:00')
GROUP BY country , date_d 

--výpoèet hodin bez srážek

CREATE TABLE t_weather_copy_country_rained AS
SELECT
	*,
	CASE WHEN rain_mm = '0' THEN '3'
	WHEN rain_mm IS NULL THEN 'error'
	ELSE '0' END AS rained
FROM t_weather_copy_country twc

SELECT
	date_d,
	city,
	rained
FROM t_t_weather_copy_country_rained ttwccr 
WHERE rained = 'error'

CREATE TABLE t_weather_wiithout_rain
SELECT 
	date_d,
	country,
	SUM(rained) AS hours_without_rain
FROM t_weather_copy_country_rained twccr 
WHERE `time` IN ('00:00', '03:00', '06:00', '09:00', '12:00', '15:00', '18:00', '21:00')
GROUP BY country, date_d 


--spojeni tabulek

CREATE TABLE t_weather_almost_finish AS
SELECT 
	twat.*,
	twmg.max_gust
FROM t_weather_avg_temp twat
LEFT JOIN t_weather_max_gust twmg 
ON twat.date_d = twmg.date_d 
AND twat.country = twat.country 



CREATE TABLE t_weather_finish AS
SELECT
	twaf.*,
	twwr.hours_without_rain 
FROM t_weather_almost_finish twaf
RIGHT JOIN t_weather_wiithout_rain twwr 
ON twaf.date_d = twwr.date_d 
AND twaf.country = twwr.country 

CREATE TABLE t_covid_diff_test_economies_life_exp_religion AS
SELECT
	tcd.*,
	tpir.religion,
	tpir.rel_population,
	tpir.sum_population,
	tpir.percentage_religion 
FROM t_covid_diff_test_economies_life_exp tcd
RIGHT JOIN t_percentage_individual_religion tpir 
ON tcd.country = tpir.country 
				

CREATE TABLE t_anna_hurtikova_projekt_SQL_final AS
SELECT 
	tcd.*,
	twf.avg_day_temp,
	twf.max_gust,
	twf.hours_without_rain
FROM t_covid_diff_test_economies_life_exp_religion tcd 
RIGHT JOIN t_weather_finish twf 
ON tcd.`date` = twf.date_d
AND tcd.country = twf.country

SELECT 
DISTINCT year
FROM religions r 




