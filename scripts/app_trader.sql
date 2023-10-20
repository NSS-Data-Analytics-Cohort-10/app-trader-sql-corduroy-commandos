-- Assumptions
	-- Based on research completed prior to launching App Trader as a company, you can assume the following:
	-- a. App Trader will purchase apps for 10,000 times the price of the app. For apps that are priced from free up to $1.00, the purchase price is $10,000.
		-- - For example, an app that costs $2.00 will be purchased for $20,000.
		-- - The cost of an app is not affected by how many app stores it is on. A $1.00 app on the Apple app store will cost the same as a $1.00 app on both stores. 
		-- - If an app is on both stores, it's purchase price will be calculated based off of the highest app price between the two stores. 
	-- b. Apps earn $5000 per month, per app store it is on, from in-app advertising and in-app purchases, regardless of the price of the app.
    	-- - An app that costs $200,000 will make the same per month as an app that costs $1.00. 
		-- - An app that is on both app stores will make $10,000 per month. 
	-- c. App Trader will spend an average of $1000 per month to market an app regardless of the price of the app. If App Trader owns rights to the app in both stores, 		it can market the app for both stores for a single cost of $1000 per month.
    	-- - An app that costs $200,000 and an app that costs $1.00 will both cost $1000 a month for marketing, regardless of the number of stores it is in.
	-- d. For every half point that an app gains in rating, its projected lifespan increases by one year. In other words, an app with a rating of 0 can be expected to
		-- be in use for 1 year, an app with a rating of 1.0 can be expected to last 3 years, and an app with a rating of 4.0 can be expected to last 9 years.
    	-- - App store ratings should be calculated by taking the average of the scores from both app stores and rounding to the nearest 0.5.
	-- e. App Trader would prefer to work with apps that are available in both the App Store and the Play Store since they can market both for the same $1000 per month.
	
-- 	Deliverables
	-- a. Develop some general recommendations as to the price range, genre, content rating, or anything else for apps that the company should target.
	-- b. Develop a Top 10 List of the apps that App Trader should buy.
	-- c. Submit a report based on your findings. All analysis work must be done using PostgreSQL, however you may export query results to create charts in Excel for 			your report.

--CREATE TABLE all_apps
--AS
CREATE TABLE all_apps
	(
	WITH
	app_ratings AS
		(
		SELECT
			DISTINCT COALESCE(UPPER(TRIM(a.name)),UPPER(TRIM(p.name))) AS app_name,
			a.rating AS app_store_rating,
			p.rating AS play_store_rating
		FROM app_store_apps AS a
		FULL JOIN play_store_apps AS p
			ON UPPER(TRIM(a.name)) = UPPER(TRIM(p.name))
		),
	app_prices AS
		(
		SELECT
			DISTINCT COALESCE(UPPER(TRIM(a.name)),UPPER(TRIM(p.name))) AS app_name,
			CASE
			WHEN a.price IS NOT NULL AND p.price IS NOT NULL THEN 'both_stores'
			WHEN a.price IS NOT NULL AND p.price IS NULL THEN 'app_store_only'
			WHEN a.price IS NULL AND p.price IS NOT NULL THEN 'play_store_only'
			ELSE 'N/A'
			END AS availability,
			CASE
				WHEN a.price IS NOT NULL THEN CAST(a.price AS money)
				ELSE CAST(0.00 AS money)
			END AS app_store_price,
			CASE
				WHEN p.price IS NOT NULL THEN CAST(p.price AS money)
				ELSE CAST(0.00 AS money)
			END AS play_store_price
		FROM app_store_apps AS a
		FULL JOIN play_store_apps AS p
			ON UPPER(TRIM(a.name)) = UPPER(TRIM(p.name))
		)
	SELECT
		DISTINCT COALESCE(r.app_name,p.app_name) AS app_name,
		p.availability,
		CASE
			WHEN p.availability = 'app_store_only' AND p.app_store_price = CAST(0 AS money) THEN CAST(10000	AS money)
			WHEN p.availability = 'app_store_only' THEN p.app_store_price*10000
			WHEN p.availability = 'play_store_only' AND p.play_store_price = CAST(0 AS money) THEN CAST(10000	AS money)
			WHEN p.availability = 'play_store_only' THEN p.play_store_price*10000
			WHEN p.availability = 'both_stores' AND p.app_store_price = CAST(0 AS money) AND p.play_store_price = CAST(0 AS money) THEN CAST(10000	AS money)
			ELSE CAST(10000 AS money)
		END AS purchase_price,
		CASE
			WHEN p.availability = 'app_store_only' OR p.availability = 'play_store_only' THEN CAST(5000 AS money)
			WHEN p.availability = 'both_stores' THEN CAST(10000 AS money)
		END AS monthly_earnings,
		CASE
			WHEN p.availability = 'app_store_only' AND app_store_rating IS NULL THEN 0.0
			WHEN p.availability = 'app_store_only' THEN r.app_store_rating
			WHEN p.availability = 'play_store_only' AND play_store_rating IS NULL THEN 0.0
			WHEN p.availability = 'play_store_only' THEN r.play_store_rating
			ELSE ROUND((r.app_store_rating+r.play_store_rating)/2,1)
		END AS avg_rating,
		CASE
			WHEN p.availability = 'app_store_only' AND app_store_rating IS NULL OR app_store_rating = 0.0 THEN 1
			WHEN p.availability = 'app_store_only' THEN ROUND(r.app_store_rating/0.5,0)
			WHEN p.availability = 'play_store_only' AND play_store_rating IS NULL OR play_store_rating IS NULL THEN 1
				WHEN p.availability = 'play_store_only' THEN ROUND(r.play_store_rating/0.5,0)
			ELSE ROUND(ROUND((r.app_store_rating+r.play_store_rating)/2,1)/0.5,0)
		END AS lifespan_in_yrs
	FROM app_ratings AS r
	FULL JOIN app_prices AS p
		USING (app_name)
	)

SELECT
	app_name,
	