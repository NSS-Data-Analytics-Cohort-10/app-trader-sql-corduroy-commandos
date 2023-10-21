-- Based on research completed prior to launching App Trader as a company, you can assume the following:

WITH X AS (

SELECT 
	O.AVG_RATING,
	O.EXPECTED_YEARS,
	O.TOTAL_MONTHS,
	O.MARKETING_MONTHS,
	O.TOTAL_REVENUE_OVER_MONTHS,
	O.APP_COST,
	O.TOTAL_PROFIT,
	O.APP_NAME,
    RANK () OVER (ORDER BY O.TOTAL_PROFIT DESC,O.APP_NAME) RANK_APP,
	M.GENRE
	FROM (
SELECT 
	W.AVG_RATING,
	ROUND(W.AVG_RATING/.5+1) EXPECTED_YEARS,
	ROUND(W.AVG_RATING/.5+1)*12  TOTAL_MONTHS,
	CAST(ROUND(W.AVG_RATING/.5+1)*12*1000 AS MONEY) MARKETING_MONTHS,
	
	CAST(ROUND(W.AVG_RATING/.5+1)*12 *
	(CASE
	WHEN COALESCE(Y.COUNT_APP,0) = 0 THEN 0
	ELSE COALESCE(Y.COUNT_APP,0)*5000
	END +
	CASE
	WHEN COALESCE(Z.COUNT_PLAY,0) = 0 THEN 0
	ELSE COALESCE(Z.COUNT_PLAY,0)*5000 
	END) AS MONEY) TOTAL_REVENUE_OVER_MONTHS,
	
	CAST(CASE 
	WHEN T.PRICE_APP = T.PRICE_PLAY THEN T.PRICE_APP
	WHEN T.PRICE_APP > T.PRICE_PLAY THEN T.PRICE_APP
	WHEN T.PRICE_APP < T.PRICE_PLAY THEN T.PRICE_PLAY
	END AS MONEY) APP_COST,
	
	CAST(
	ROUND(W.AVG_RATING/.5+1)*12 *
	CASE
	WHEN COALESCE(COUNT_APP,0) = 0 THEN 0
	ELSE COALESCE(COUNT_APP,0)*5000
	END
	+
	ROUND(W.AVG_RATING/.5+1)*12 *
	CASE
	WHEN COALESCE(Z.COUNT_PLAY,0) = 0 THEN 0
	ELSE COALESCE(Z.COUNT_PLAY,0)*5000
	END 
	-
	ROUND(W.AVG_RATING/.5+1)*12*1000 
    -
	CASE 
	WHEN T.PRICE_APP = T.PRICE_PLAY THEN T.PRICE_APP
	WHEN T.PRICE_APP > T.PRICE_PLAY THEN T.PRICE_APP
	WHEN T.PRICE_APP < T.PRICE_PLAY THEN T.PRICE_PLAY
	END AS MONEY) TOTAL_PROFIT,
		
	COALESCE(Y.COUNT_APP,0)COUNT_APP,
	CASE
	WHEN COALESCE(COUNT_APP,0) = 0 THEN 0
	ELSE  COALESCE(COUNT_APP,0)*5000
	END APP_MONEY_MONTHLY,
	
	COALESCE(Z.COUNT_PLAY,0)COUNT_PLAY,
	
	CASE
	WHEN COALESCE(Z.COUNT_PLAY,0) = 0 THEN 0
	ELSE COALESCE(Z.COUNT_PLAY,0)*5000
	END PLAY_MONEY_MONTHLY,
	
	RANK () OVER (PARTITION BY T.APP_NAME ORDER BY CASE 
	WHEN T.PRICE_APP = T.PRICE_PLAY THEN T.PRICE_APP
	WHEN T.PRICE_APP > T.PRICE_PLAY THEN T.PRICE_APP
	WHEN T.PRICE_APP < T.PRICE_PLAY THEN T.PRICE_PLAY
	END DESC) RANKING,
	APP_NAME
FROM (
	SELECT
		CASE WHEN
		COALESCE(CAST(A.PRICE AS NUMERIC),0) = 0 THEN 10000
		ELSE COALESCE(CAST(A.PRICE AS NUMERIC),0)*10000 END PRICE_APP,
	
		CASE 
		WHEN COALESCE(CAST(REPLACE(P.PRICE,'$','') AS NUMERIC),0) = 0 THEN 10000
		ELSE COALESCE(CAST(REPLACE(P.PRICE,'$','') AS NUMERIC),0)*10000 END PRICE_PLAY,
	
		COALESCE(UPPER(TRIM(A.NAME)),UPPER(TRIM(P.NAME))) APP_NAME
	FROM 
		APP_STORE_APPS A
		FULL JOIN PLAY_STORE_APPS P ON UPPER(TRIM(A.NAME)) =UPPER(TRIM(P.NAME))	
	GROUP BY
	    CASE WHEN
		COALESCE(CAST(A.PRICE AS NUMERIC),0) = 0 THEN 10000
		ELSE COALESCE(CAST(A.PRICE AS NUMERIC),0)*10000 END,
		CASE 
		WHEN COALESCE(CAST(REPLACE(P.PRICE,'$','') AS NUMERIC),0) = 0 THEN 10000
		ELSE COALESCE(CAST(REPLACE(P.PRICE,'$','') AS NUMERIC),0)*10000 END,
		COALESCE(UPPER(TRIM(A.NAME)),UPPER(TRIM(P.NAME)))) T
LEFT OUTER JOIN
	(
	SELECT 
		UPPER(TRIM(NAME)) APP_NAME_STORE,
		COUNT(DISTINCT(UPPER(TRIM(NAME)))) COUNT_APP
	FROM APP_STORE_APPS
	GROUP BY UPPER(TRIM(NAME))
	) Y ON T.APP_NAME = Y.APP_NAME_STORE
LEFT OUTER JOIN
	(
	SELECT 
		UPPER(TRIM(NAME)) PLAY_NAME_STORE,
		COUNT(DISTINCT(UPPER(TRIM(NAME))))  COUNT_PLAY
	FROM PLAY_STORE_APPS
	GROUP BY  UPPER(TRIM(NAME))
	) Z ON T.APP_NAME = Z.PLAY_NAME_STORE	
INNER  JOIN 
(SELECT 
	ROUND(AVG(RATING)/.5)*.5 AVG_RATING,
	APP_NAME_AVG
 FROM 
(
SELECT 
	UPPER(TRIM(NAME)) APP_NAME_AVG,
	RATING 
FROM
	APP_STORE_APPS 
UNION
SELECT 
	UPPER(TRIM(NAME))  APP_NAME_AVG,
	RATING
FROM
	PLAY_STORE_APPS
)
WHERE 
  RATING IS NOT NULL
GROUP BY 
APP_NAME_AVG) W ON W.APP_NAME_AVG = T.APP_NAME
) O
INNER JOIN 
(SELECT
	UPPER(TRIM(NAME)) GENRE_APP_NAME,
	UPPER(PRIMARY_GENRE)  GENRE
FROM
	APP_STORE_APPS) M ON O.APP_NAME = M.GENRE_APP_NAME
WHERE 
--COUNT_APP >= 1 AND COUNT_PLAY >= 1 
	--AND
RANKING = 1 ORDER BY RANK_APP)

SELECT * FROM X WHERE RANK_APP <= 15


-- a. App Trader will purchase apps for 10,000 times the price of the app. For apps that are priced from free up to $1.00, the purchase price is $10,000.
    
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

