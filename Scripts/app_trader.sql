-- Based on research completed prior to launching App Trader as a company, you can assume the following:
-- a. App Trader will purchase apps for 10,000 times the price of the app. For apps that are priced from free up to $1.00, the purchase price is $10,000.
 
WITH X AS (
SELECT 
	COALESCE(T.APP_NAME,T.PLAY_NAME) APP,
	T.APP_IN_PLAY,
	COALESCE(T.PRICE_APP,0) PRICE_APP,
	COALESCE(T.PRICE_APP,0) PRICE_PLAY,
	CAST(COALESCE(CASE
	WHEN COALESCE(T.PRICE_APP,0) = COALESCE(T.PRICE_PLAY,0) THEN T.APP_PRICE_CALCULATED
	WHEN COALESCE(T.PRICE_APP,0) > COALESCE(T.PRICE_PLAY,0) THEN T.APP_PRICE_CALCULATED
	WHEN COALESCE(T.PRICE_PLAY,0) > COALESCE(T.PRICE_APP,0) THEN T.PLAY_PRICE_CALCULATED 
	END,10000) AS MONEY) PRICE_OF_APP
FROM 
(SELECT 
	UPPER(A.NAME) APP_NAME,
    UPPER(P.NAME) PLAY_NAME,
	CASE
	WHEN UPPER(TRIM(A.NAME)) =UPPER(TRIM(P.NAME)) THEN 'YES'
    ELSE 'NO' END APP_IN_PLAY,
	CAST(A.PRICE AS NUMERIC) PRICE_APP,
	CAST(REPLACE(P.PRICE,'$','') AS NUMERIC) PRICE_PLAY,
	CASE WHEN A.PRICE <= 1 THEN 10000 
	ELSE A.PRICE*10000 END APP_PRICE_CALCULATED,
	CASE WHEN CAST(REPLACE(P.PRICE,'$','') AS NUMERIC) <= 1 THEN 10000 
	ELSE CAST(REPLACE(P.PRICE,'$','') AS NUMERIC)*10000 END  PLAY_PRICE_CALCULATED 
FROM 
   APP_STORE_APPS A
   FULL JOIN PLAY_STORE_APPS P ON UPPER(TRIM(A.NAME)) =UPPER(TRIM(P.NAME))) T)
SELECT 
	APP,
	PRICE_OF_APP
FROM X ---WHERE APP = '21-DAY MEDITATION EXPERIENCE'
GROUP BY 
	APP,
	PRICE_OF_APP
ORDER BY 1

/*
SELECT * FROM APP_STORE_APPS LIMIT (10);
SELECT * FROM PLAY_STORE_APPS WHERE UPPER(NAME) = '21-DAY MEDITATION EXPERIENCE'
*/

-- - For example, an app that costs $2.00 will be purchased for $20,000.
    
-- - The cost of an app is not affected by how many app stores it is on. A $1.00 app on the Apple app store will cost the same as a $1.00 app on both stores. 
    
-- - If an app is on both stores, it's purchase price will be calculated based off of the highest app price between the two stores. 

-- b. Apps earn $5000 per month, per app store it is on, from in-app advertising and in-app purchases, regardless of the price of the app.
    
-- - An app that costs $200,000 will make the same per month as an app that costs $1.00. 

-- - An app that is on both app stores will make $10,000 per month. 

-- c. App Trader will spend an average of $1000 per month to market an app regardless of the price of the app. If App Trader owns rights to the app in both stores, it can market the app for both stores for a single cost of $1000 per month.
    
-- - An app that costs $200,000 and an app that costs $1.00 will both cost $1000 a month for marketing, regardless of the number of stores it is in.

-- d. For every half point that an app gains in rating, its projected lifespan increases by one year. In other words, an app with a rating of 0 can be expected to be in use for 1 year, an app with a rating of 1.0 can be expected to last 3 years, and an app with a rating of 4.0 can be expected to last 9 years.
    
-- - App store ratings should be calculated by taking the average of the scores from both app stores and rounding to the nearest 0.5.

-- e. App Trader would prefer to work with apps that are available in both the App Store and the Play Store since they can market both for the same $1000 per month.


-- #### 3. Deliverables

-- a. Develop some general recommendations as to the price range, genre, content rating, or anything else for apps that the company should target.

-- b. Develop a Top 10 List of the apps that App Trader should buy.

-- c. Submit a report based on your findings. All analysis work must be done using PostgreSQL, however you may export query results to create charts in Excel for your report. 