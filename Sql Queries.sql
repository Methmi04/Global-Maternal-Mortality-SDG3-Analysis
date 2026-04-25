-- Show all column names from MaternalMortality table
SELECT COLUMN_NAME 
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'MaternalMortality';

--STEP 1: SELECT only relevant fields and UNPIVOT
 --Clean Year columns and rename fields for clarity

SELECT
    GeoAreaCode      AS CountryCode,
    GeoAreaName      AS CountryName,
    Indicator        AS IndicatorName,
    SeriesDescription AS IndicatorDescription,
    Reporting_Type,
    Units,
    CAST(REPLACE(Year, '_', '') AS INT) AS Year,  -- Clean Year: remove underscore and convert to INT
    NULLIF(MaternalMortalityValue, '') AS Value   -- Convert empty strings to NULL
FROM dbo.MaternalMortality
UNPIVOT (
    MaternalMortalityValue FOR Year IN (
        [_2005], [_2006], [_2007], [_2008], [_2009], [_2010],
        [_2011], [_2012], [_2013], [_2014], [_2015],
        [_2016], [_2017], [_2018], [_2019], [_2020],
        [_2021], [_2022], [_2023]
    )
) AS Unpvt;

--STEP 2: Remove unnecessary columns(Age, Sex, Location, Extra blank columns, etc.)--
ALTER TABLE dbo.MaternalMortality
DROP COLUMN Age, Sex, Location, Freq,
Column33, Column34, Column35, Column36, Column37, Column38,
Column39, Column40, Column41, Column42, Column43, Column44,
Column45, Column46, Column47, Column48, Column49, Column50,
Column51, Column52;

--STEP 3: Standardize text & handle blanks--
UPDATE dbo.MaternalMortality
SET
    GeoAreaName = UPPER(LTRIM(RTRIM(GeoAreaName))),
    Indicator = LTRIM(RTRIM(Indicator)),
    SeriesDescription = LTRIM(RTRIM(SeriesDescription)),
    Reporting_Type = LTRIM(RTRIM(Reporting_Type)),
    Units = LTRIM(RTRIM(Units));

--STEP 4: Remove duplicate records--
WITH RemoveDuplicates AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY GeoAreaCode, Indicator, Units
               ORDER BY GeoAreaCode
           ) AS RowNum
    FROM dbo.MaternalMortality
)
DELETE FROM RemoveDuplicates WHERE RowNum > 1;

--STEP 5: Create Cleaned Final Table for Power BI--
SELECT DISTINCT
    GeoAreaCode      AS CountryCode,
    GeoAreaName      AS CountryName,
    Indicator        AS IndicatorName,
    SeriesDescription AS IndicatorDescription,
    Reporting_Type,
    Units,
    CAST(REPLACE(Year, '_', '') AS INT) AS Year,
    MaternalMortalityValue AS Value
INTO SDG_Cleaned
FROM dbo.MaternalMortality
UNPIVOT (
    MaternalMortalityValue FOR Year IN (
        [_2005], [_2006], [_2007], [_2008], [_2009], [_2010],
        [_2011], [_2012], [_2013], [_2014], [_2015],
        [_2016], [_2017], [_2018], [_2019], [_2020],
        [_2021], [_2022], [_2023]
    )
) AS Unpvt;

