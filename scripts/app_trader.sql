--### App Trader

--Your team has been hired by a new company called App Trader to help them explore and gain insights from apps that are made available through the Apple App Store and Android Play Store. App Trader is a broker that purchases the rights to apps from developers in order to market the apps and offer in-app purchase. 

--Unfortunately, the data for Apple App Store apps and Android Play Store Apps is located in separate tables with no referential integrity.

--#### 1. Loading the data
---a. Launch PgAdmin and create a new database called app_trader.  

--b. Right-click on the app_trader database and choose `Restore...`  

-- c. Use the default values under the `Restore Options` tab. 

-- d. In the `Filename` section, browse to the backup file `app_store_backup.backup` in the data folder of this repository.  

-- e. Click `Restore` to load the database.  

-- f. Verify that you have two tables:  
--     - `app_store_apps` with 7197 rows  
--     - `play_store_apps` with 10840 rows

-- #### 2. Assumptions

-- Based on research completed prior to launching App Trader as a company, you can assume the following:

-- a. App Trader will purchase apps for 10,000 times the price of the app. For apps that are priced from free up to $1.00, the purchase price is $10,000.
    
-- - For example, an app that costs $2.00 will be purchased for $20,000.
    
-- - The cost of an app is not affected by how many app stores it is on. A $1.00 app on the Apple app store will cost the same as a $1.00 app on both stores. 
    
-- - If an app is on both stores, it's purchase price will be calculated based off of the highest app price between the two stores. 

-- b Apps earn $5000 per month, per app store it is on, from in-app advertising and in-app purchases, regardless of the price of the app.
    
--- An app that costs $200,000 will make the same per month as an app that costs $1.00. 

--- An app that is on both app stores will make $10,000 per month. 

-- c. App Trader will spend an average of $1000 per month to market an app regardless of the price of the app. If App Trader owns rights to the app in both stores, it can market the app for both stores for a single cost of $1000 per month.
    
-- - An app that costs $200,000 and an app that costs $1.00 will both cost $1000 a month for marketing, regardless of the number of stores it is in.

-- d. For every half point that an app gains in rating, its projected lifespan increases by one year. In other words, an app with a rating of 0 can be expected to be in use for 1 year, an app with a rating of 1.0 can be expected to last 3 years, and an app with a rating of 4.0 can be expected to last 9 years.
    
-- - App store ratings should be calculated by taking the average of the scores from both app stores and rounding to the nearest 0.5.

-- e. App Trader would prefer to work with apps that are available in both the App Store and the Play Store since they can market both for the same $1000 per month.


-- #### 3. Deliverables

-- a. Develop some general recommendations as to the price range, genre, content rating, or anything else for apps that the company should target.

-- b. Develop a Top 10 List of the apps that App Trader should buy.

-- c. Submit a report based on your findings. All analysis work must be done using PostgreSQL, however you may export query results to create charts in Excel for your report. 

-- updated 2/18/2023

--  SELECT*FROM 
--  app_store_apps;
-- WHERE name='Bible';

-- SELECT*FROM
-- play_store_apps
-- WHERE name='Bible';

----ans
--   SELECT DISTINCT name 
--    FROM app_store_apps;
   
--    SELECT* FROM 
--    app_store_apps
--    WHERE price > 0;
   
   
--    SELECT CASE 
--    WHEN currency  = 'USD' THEN
--    CAST('$' AS VARCHAR)
--    ELSE currency END AS currency
--    FROM app_store_apps;
   
   
   
--     SELECT 
-- 	APP_name
-- 	play_name
-- 	APP_price
-- 	PLAY-price
	
-- 	////////////////
--ans	
	WITH both_apps AS (
		SELECT
			DISTINCT UPPER(TRIM(a.name)) as aname,
			UPPER(TRIM(P.name)) as pname,
			a.primary_genre AS a_genre,
			p.genres AS p_genre,
			a.price AS apple_price,
			CAST(REGEXP_REPLACE(p.price, '[^0-9.]', '', 'g') AS NUMERIC) AS android_price,
			a.rating AS apple_rating,
			p.rating AS android_rating,
			a.review_count as apple_review_count
-- 			p.review_count as play_review_count
	--		(CAST(REGEXP_REPLACE(a.review_count, '[^0-9.]', '', 'g'),'0') AS NUMERIC) AS apple_review_count
		FROM app_store_apps AS a
		INNER JOIN
			play_store_apps p 
		USING(name)
	),
	normalized_apps AS (
		SELECT
			*,
			GREATEST(apple_price, COALESCE(android_price, 0)) AS max_price,
			(apple_rating + COALESCE(android_rating, 0)) / 2 AS avg_rating
		FROM both_apps
	),
	lifespan AS (
		SELECT
			*,
			ROUND(COALESCE((2 * avg_rating) / 2 * 2 + 1)) AS projected_lifespan_years
		FROM normalized_apps
	),
	revenues AS (
		SELECT
			aname,
			pname,
			a_genre,
			p_genre,
			apple_review_count,
			projected_lifespan_years,
			CASE
				WHEN CAST(apple_price AS money)=CAST(0.00 AS money) THEN CAST (0.00 as money)
				WHEN CAST (android_price AS money)=CAST (0.00 AS money) THEN CAST (0.00 as money)
				WHEN CAST (apple_price AS money) >=CAST (0.00 AS money) THEN CAST (apple_price as money)
				WHEN CAST (android_price AS money) >= CAST (0.00 AS money) THEN CAST (android_price as money)
			 END AS app_price,
			 CASE 
				WHEN CAST(apple_price AS money)=CAST(0.00 AS money) THEN 10000
				WHEN CAST (android_price AS money)=CAST (0.00 AS money) THEN 10000
				WHEN CAST (apple_price AS money) >=CAST (0.00 AS money) THEN apple_price*10000
				WHEN CAST (android_price AS money) >= CAST (0.00 AS money) THEN android_price*10000
			 END AS purchase_price,
			CASE 
				 WHEN apple_price IS NULL THEN CAST(5000.00 AS money)
				 WHEN android_price  IS NULL THEN CAST(5000.00 as money)
				 ELSE CAST(10000.00 AS money)
			END AS monthly_earnings,
			ROUND(COALESCE((apple_rating+android_rating)/2,1)) AS average_rating,
		 	ROUND(COALESCE((apple_rating+android_rating)/2,1)*2-1) AS half_points,
			ROUND((projected_lifespan_years * 12 * 5000 - (projected_lifespan_years * 12 * 1000)) / 10) * 10 AS total_revenue
		FROM lifespan
	)
	SELECT  DISTINCT COALESCE(aname, pname) app_name,
		CAST(purchase_price as money),
		CAST(total_revenue as money),
		app_price,
		monthly_earnings,
		a_genre,
		p_genre,
		average_rating,
		half_points,
		CAST(ROUND((total_revenue - purchase_price) / 10) * 10 AS money) AS net_profit,
		projected_lifespan_years
	FROM revenues rev
	order by net_profit DESC
	LIMIT 10;
	
	
-- 	//////////
	
	
	
-- 	///////////



	
	
	
   
   
   
   
