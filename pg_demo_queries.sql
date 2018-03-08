-- PostgreSQL Hands-On
-- NICAR 2018 Chicago

-- Simple Queries
-- --------------

-- 1. SELECT statement (2010 Decennial Census data)

SELECT geo_name,
       state_us_abbreviation,
       p0010001 AS pop_2010
FROM us_counties_2010
ORDER BY pop_2010 DESC
LIMIT 10;

-- 2. Table join (2010 and 2000 Decennial Census data)

SELECT c2010.geo_name,
       c2010.state_us_abbreviation AS state,
       c2010.p0010001 AS pop_2010,
       c2000.p0010001 AS pop_2000
FROM us_counties_2010 c2010 INNER JOIN us_counties_2000 c2000
ON c2010.state_fips = c2000.state_fips
   AND c2010.county_fips = c2000.county_fips;
   
-- Let's calculate percent change in population
SELECT c2010.geo_name,
       c2010.state_us_abbreviation AS state,
       c2010.p0010001 AS pop_2010,
       c2000.p0010001 AS pop_2000,
       round( (CAST(c2010.p0010001 AS numeric(8,1)) - c2000.p0010001)
           / c2000.p0010001 * 100, 1 ) AS pct_change
FROM us_counties_2010 c2010 INNER JOIN us_counties_2000 c2000
ON c2010.state_fips = c2000.state_fips
   AND c2010.county_fips = c2000.county_fips
ORDER BY pct_change DESC;


-- 2. Stats Functions
-- ------------------

-- Five-year Census ACS data (2011-2015)
SELECT *
FROM acs_2011_2015_stats;

-- Find the correlation coefficient between median household income
-- and percent of population with a bachelor's degree
SELECT corr(median_hh_income, pct_bachelors_higher)
    AS bachelors_income_r
FROM acs_2011_2015_stats;

-- Correlation between income and master's degree
SELECT corr(median_hh_income, pct_masters_higher)
    AS bachelors_income_r
FROM acs_2011_2015_stats;

-- Correlation between income and percent who commute 60+ minutes
SELECT corr(median_hh_income, pct_travel_60_min)
    AS bachelors_income_r
FROM acs_2011_2015_stats;

-- Calculating the coefficient of determination, or r-squared
SELECT regr_r2(median_hh_income, pct_bachelors_higher)
    AS r_squared
FROM acs_2011_2015_stats;


-- 3. Spatial Queries with PostGIS

-- Farmers markets in the U.S.
-- https://catalog.data.gov/dataset/farmers-markets-geographic-data
-- https://www.ams.usda.gov/local-food-directories/farmersmarkets

SELECT * FROM farmers_markets;

-- Using ST_DWithin() to locate farmers' markets within 10 kilometers of
-- downtown Des Moines, Iowa

SELECT market_name,
       city,
       st
FROM farmers_markets
WHERE ST_DWithin(geog_point,
                 ST_GeogFromText('POINT(-93.6204386 41.5853202)'),
                 10000)
ORDER BY market_name;

-- Using ST_Distance() to calculate the miles between Yankee Stadium
-- and Citi Field (Mets)
-- 1609.344 meters/mile
SELECT ST_Distance(
                   ST_GeogFromText('POINT(-73.9283685 40.8296466)'),
                   ST_GeogFromText('POINT(-73.8480153 40.7570917)')
                   ) / 1609.344 AS mets_to_yanks;

-- Using ST_Distance() for each row in farmers_markets

SELECT market_name,
       city,
       round(
           (ST_Distance(geog_point,
                        ST_GeogFromText('POINT(-93.6204386 41.5853202)')
                        ) / 1609.344)::numeric(8,5), 2
            ) AS miles_from_dt
FROM farmers_markets
WHERE ST_DWithin(geog_point,
                 ST_GeogFromText('POINT(-93.6204386 41.5853202)'),
                 10000)
ORDER BY miles_from_dt ASC;

-- Working with shapefiles
-- Find the largest counties by area using ST_Area()

SELECT * FROM us_counties_2010_shp;

SELECT ST_AsText(geom)
FROM us_counties_2010_shp
LIMIT 1;

SELECT name10,
       statefp10 AS st,
       round(
             ( ST_Area(geom::geography) / 2589988.110336 )::numeric, 2
            )  AS square_miles
FROM us_counties_2010_shp
ORDER BY square_miles DESC
LIMIT 5;

-- Listing 14-16: Find the county belonging to a pair of coordinates with ST_Within()

SELECT name10,
       statefp10
FROM us_counties_2010_shp
WHERE ST_Within('SRID=4269;POINT(-87.6375298 41.8958031)'::geometry, geom);


-- 4. Full text search
-- -------------------

-- FULL TEXT SEARCH

-- Full-text search operators:
-- & (AND)
-- | (OR)
-- ! (NOT)

-- Listing 13-15: Converting text to tsvector data

SELECT to_tsvector('I am walking across the sitting room to sit with you.');

-- Listing 13-16: Converting search terms to tsquery data

SELECT to_tsquery('walking & sitting');

-- Listing 13-17: Querying a tsvector type with a tsquery

SELECT to_tsvector('I am walking across the sitting room') @@ to_tsquery('walking & sitting');

SELECT to_tsvector('I am walking across the sitting room') @@ to_tsquery('walking & running');

-- Listing 13-21: Finding speeches containing the word "Vietnam"
SELECT president, speech_date
FROM president_speeches
WHERE search_speech_text @@ to_tsquery('Vietnam')
ORDER BY speech_date;

-- Listing 13-22: Displaying search results with ts_headline()

SELECT president,
       speech_date,
       ts_headline(speech_text, to_tsquery('Vietnam'),
                   'StartSel = <,
                    StopSel = >,
                    MinWords=5,
                    MaxWords=7,
                    MaxFragments=1')
FROM president_speeches
WHERE search_speech_text @@ to_tsquery('Vietnam');

-- Listing 13-24: Find speeches where "defense" follows "military"

SELECT president,
       speech_date,
       ts_headline(speech_text, to_tsquery('military <-> defense'),
                   'StartSel = <,
                    StopSel = >,
                    MinWords=5,
                    MaxWords=7,
                    MaxFragments=1')
FROM president_speeches
WHERE search_speech_text @@ to_tsquery('military <-> defense');

-- Listing 13-25: Scoring relevance with ts_rank()

SELECT president,
       speech_date,
       ts_rank(search_speech_text,
               to_tsquery('war & security & threat & enemy')) AS score
FROM president_speeches
WHERE search_speech_text @@ to_tsquery('war & security & threat & enemy')
ORDER BY score DESC
LIMIT 5;

-- Listing 13-26: Normalizing ts_rank() by speech length

SELECT president,
       speech_date,
       ts_rank(search_speech_text,
               to_tsquery('war & security & threat & enemy'), 2)::numeric 
               AS score
FROM president_speeches
WHERE search_speech_text @@ to_tsquery('war & security & threat & enemy')
ORDER BY score DESC
LIMIT 5;

-- 5. Creating Functions
-- ---------------------

-- Creating a percent_change function
-- To delete this function: DROP FUNCTION percent_change(numeric,numeric,integer);

CREATE OR REPLACE FUNCTION
percent_change(new_value numeric,
               old_value numeric,
               decimal_places integer DEFAULT 1)
RETURNS numeric AS
'SELECT round(
        ((new_value - old_value) / old_value) * 100, decimal_places
);'
LANGUAGE SQL
IMMUTABLE
RETURNS NULL ON NULL INPUT;

-- Testing the percent_change() function

SELECT percent_change(110, 108, 2);

-- Testing percent_change() on Census data

SELECT c2010.geo_name,
       c2010.state_us_abbreviation AS st,
       c2010.p0010001 AS pop_2010,
       percent_change(c2010.p0010001, c2000.p0010001) AS pct_chg_func,
       round( (CAST(c2010.p0010001 AS numeric(8,1)) - c2000.p0010001)
           / c2000.p0010001 * 100, 1 ) AS pct_chg_formula
FROM us_counties_2010 c2010 INNER JOIN us_counties_2000 c2000
ON c2010.state_fips = c2000.state_fips
   AND c2010.county_fips = c2000.county_fips
ORDER BY pct_chg_func DESC
LIMIT 5;


