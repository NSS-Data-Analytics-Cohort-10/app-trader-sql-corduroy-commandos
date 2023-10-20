-- Create a new table that includes:
	-- the app name
	-- whether it appears in the App Store, the Play Store, or both
	-- the purchase price (10,000 times the download price in the store)
	-- the anticipated monthly earnings
	-- the average rating between the two stores, rounded to the nearest 0.5
	-- the projected lifespan based on rating (1 year for every half-point in rating)

CREATE TABLE all_apps AS
	(
-- First aggregate the ratings
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
-- Then aggregate price/availability - add a column to show availability in one or both stores
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
-- Put the CTEs together and start compiling th erelavant metrics based on App Trader criteria
	SELECT
		DISTINCT COALESCE(r.app_name,p.app_name) AS app_name,
		p.availability,
-- NOTE: App Trader purchase price is 10,000 times the price in the store(s)
		CASE
			WHEN p.availability = 'app_store_only' AND p.app_store_price = CAST(0 AS money) THEN CAST(10000	AS money)
			WHEN p.availability = 'app_store_only' THEN p.app_store_price*10000
			WHEN p.availability = 'play_store_only' AND p.play_store_price = CAST(0 AS money) THEN CAST(10000 AS money)
			WHEN p.availability = 'play_store_only' THEN p.play_store_price*10000
			WHEN p.availability = 'both_stores' AND p.app_store_price = CAST(0 AS money) AND p.play_store_price = CAST(0 AS money) THEN CAST(10000 AS money)
			ELSE CAST(10000 AS money)
		END AS purchase_price,
-- NOTE: earnings are $5,000 per store, or $10,000 if an app is in both stores
		CASE
			WHEN p.availability = 'app_store_only' OR p.availability = 'play_store_only' THEN CAST(5000 AS money)
			WHEN p.availability = 'both_stores' THEN CAST(10000 AS money)
		END AS monthly_earnings,
-- NOTE: ratings rounded to the nearest 0.5, averaging the ratings for each store where relevant
		CASE
			WHEN p.availability = 'app_store_only' AND app_store_rating IS NULL THEN 0.0
			WHEN p.availability = 'app_store_only' THEN ROUND(ROUND(r.app_store_rating*2,0)/2,1)
			WHEN p.availability = 'play_store_only' AND play_store_rating IS NULL THEN 0.0
			WHEN p.availability = 'play_store_only' THEN ROUND(ROUND(r.play_store_rating*2,0)/2,1)
			ELSE ROUND((r.app_store_rating+r.play_store_rating)/2,1)
		END AS avg_rating,
-- NOTE: lifespan is assumed to be 1 year for every half-point in rating
--	null or 0 ratings assumed to have a 1 year lifespan
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
	);

-- Calculate the relevant financial metrics
WITH
finances AS
	(
	SELECT
		DISTINCT app_name,
		purchase_price,
-- NOTE: marketing expenses assumed to be $1,000/month per app, regardless of availability in multiple stores
		CAST((lifespan_in_yrs*12*1000) AS money) AS lifetime_mktg_cost,
-- Add total_cost column to add initial purchase price to the marketing budget
		CAST((lifespan_in_yrs*12*1000) AS money)+purchase_price AS total_cost,
		(lifespan_in_yrs*12*monthly_earnings) AS lifetime_earnings
	FROM all_apps
	)
SELECT
	DISTINCT a.app_name,
	a.availability,
	f.total_cost,
	f.lifetime_earnings,
	(f.lifetime_earnings-f.total_cost) AS profits,
--NOTE: ROI calculated as [(profits-total_cost)/total_cost], expressed as a percentage
	ROUND(CAST((((f.lifetime_earnings-f.total_cost)-f.total_cost)/f.total_cost*100) AS numeric),2) AS pct_roi
FROM finances AS f
LEFT JOIN all_apps AS a
	USING(app_name)
WHERE
	ROUND(CAST((((lifetime_earnings-total_cost)-total_cost)/total_cost*100) AS numeric),2) > 0.00
	AND a.availability = 'both_stores'
	AND a.avg_rating > 4.5
	ORDER BY pct_roi DESC;

-- Copy the above code and create an overall top 10 table
CREATE TABLE top_10_overall AS
	(
	WITH
	finances AS
		(
		SELECT
			DISTINCT app_name,
			purchase_price,
			CAST((lifespan_in_yrs*12*1000) AS money) AS lifetime_mktg_cost,
			CAST((lifespan_in_yrs*12*1000) AS money)+purchase_price AS total_cost,
			(lifespan_in_yrs*12*monthly_earnings) AS lifetime_earnings
		FROM all_apps
		)
	SELECT
		DISTINCT a.app_name,
		a.availability,
		f.total_cost,
		f.lifetime_earnings,
		(f.lifetime_earnings-f.total_cost) AS profits,
		ROUND(CAST((((f.lifetime_earnings-f.total_cost)-f.total_cost)/f.total_cost*100) AS numeric),2) AS pct_roi
	FROM finances AS f
	LEFT JOIN all_apps AS a
		USING(app_name)
	WHERE
		ROUND(CAST((((lifetime_earnings-total_cost)-total_cost)/total_cost*100) AS numeric),2) > 0.00
		AND a.availability = 'both_stores'
		AND a.avg_rating > 4.5
		ORDER BY pct_roi DESC
	LIMIT 10
	);

--Check against content rating & genre
SELECT
	DISTINCT COALESCE(UPPER(TRIM(a.name)),UPPER(TRIM(p.name))) AS app_name,
	a.content_rating AS app_store_rating,
	p.content_rating AS play_store_rating,
	a.primary_genre AS app_store_genre,
	p.genres AS play_store_genre
FROM app_store_apps AS a
FULL JOIN play_store_apps AS p
	ON UPPER(TRIM(a.name)) = UPPER(TRIM(p.name))
WHERE UPPER(TRIM(a.name)) IN
	(
	SELECT
		app_name
	FROM top_10_overall
	);

-- Create a new top 10 table with a filter for "all ages" apps (where the content rating in the Play Store is 'Everyone')
CREATE TABLE top_10_everyone AS
	(
	WITH
	finances AS
		(
		SELECT
			DISTINCT app_name,
			purchase_price,
			CAST((lifespan_in_yrs*12*1000) AS money) AS lifetime_mktg_cost,
			CAST((lifespan_in_yrs*12*1000) AS money)+purchase_price AS total_cost,
			(lifespan_in_yrs*12*monthly_earnings) AS lifetime_earnings
		FROM all_apps
		)
	SELECT
		DISTINCT a.app_name,
		a.availability,
		f.total_cost,
		f.lifetime_earnings,
		(f.lifetime_earnings-f.total_cost) AS profits,
		ROUND(CAST((((f.lifetime_earnings-f.total_cost)-f.total_cost)/f.total_cost*100) AS numeric),2) AS pct_roi
	FROM finances AS f
	LEFT JOIN all_apps AS a
		USING(app_name)
	WHERE
		ROUND(CAST((((lifetime_earnings-total_cost)-total_cost)/total_cost*100) AS numeric),2) > 0.00
		AND a.availability = 'both_stores'
		AND a.avg_rating > 4.5
		AND a.app_name IN
			(
			SELECT
				UPPER(TRIM(name))
			FROM play_store_apps
			WHERE content_rating LIKE 'Everyone'
			)
		ORDER BY pct_roi DESC
	LIMIT 10
	);
	
--Check against & genre
SELECT
	DISTINCT COALESCE(UPPER(TRIM(a.name)),UPPER(TRIM(p.name))) AS app_name,
	a.primary_genre AS app_store_genre,
	p.genres AS play_store_genre
FROM app_store_apps AS a
FULL JOIN play_store_apps AS p
	ON UPPER(TRIM(a.name)) = UPPER(TRIM(p.name))
WHERE UPPER(TRIM(a.name)) IN
	(
	SELECT
		app_name
	FROM top_10_everyone
	);

-- Now create a top 10 table for games
CREATE TABLE top_10_games AS
	(
	WITH
	finances AS
		(
		SELECT
			DISTINCT app_name,
			purchase_price,
			CAST((lifespan_in_yrs*12*1000) AS money) AS lifetime_mktg_cost,
			CAST((lifespan_in_yrs*12*1000) AS money)+purchase_price AS total_cost,
			(lifespan_in_yrs*12*monthly_earnings) AS lifetime_earnings
		FROM all_apps
		)
	SELECT
		DISTINCT a.app_name,
		a.availability,
		f.total_cost,
		f.lifetime_earnings,
		(f.lifetime_earnings-f.total_cost) AS profits,
		ROUND(CAST((((f.lifetime_earnings-f.total_cost)-f.total_cost)/f.total_cost*100) AS numeric),2) AS pct_roi
	FROM finances AS f
	LEFT JOIN all_apps AS a
		USING(app_name)
	WHERE
		ROUND(CAST((((lifetime_earnings-total_cost)-total_cost)/total_cost*100) AS numeric),2) > 0.00
		AND a.availability = 'both_stores'
		AND a.avg_rating > 4.5
		AND a.app_name IN
			(
			SELECT
				UPPER(TRIM(name))
			FROM app_store_apps
			WHERE primary_genre LIKE 'Games'
			)
		ORDER BY pct_roi DESC
	LIMIT 10
	);

-- ... And check against & content rating
SELECT
	DISTINCT COALESCE(UPPER(TRIM(a.name)),UPPER(TRIM(p.name))) AS app_name,
	a.content_rating AS app_store_rating,
	p.content_rating AS play_store_rating
FROM app_store_apps AS a
FULL JOIN play_store_apps AS p
	ON UPPER(TRIM(a.name)) = UPPER(TRIM(p.name))
WHERE UPPER(TRIM(a.name)) IN
	(
	SELECT
		app_name
	FROM top_10_games
	);
	
-- Now create a top 10 table for games
CREATE TABLE top_10_games_everyone AS
	(
	WITH
	finances AS
		(
		SELECT
			DISTINCT app_name,
			purchase_price,
			CAST((lifespan_in_yrs*12*1000) AS money) AS lifetime_mktg_cost,
			CAST((lifespan_in_yrs*12*1000) AS money)+purchase_price AS total_cost,
			(lifespan_in_yrs*12*monthly_earnings) AS lifetime_earnings
		FROM all_apps
		)
	SELECT
		DISTINCT a.app_name,
		a.availability,
		f.total_cost,
		f.lifetime_earnings,
		(f.lifetime_earnings-f.total_cost) AS profits,
		ROUND(CAST((((f.lifetime_earnings-f.total_cost)-f.total_cost)/f.total_cost*100) AS numeric),2) AS pct_roi
	FROM finances AS f
	LEFT JOIN all_apps AS a
		USING(app_name)
	WHERE
		ROUND(CAST((((lifetime_earnings-total_cost)-total_cost)/total_cost*100) AS numeric),2) > 0.00
		AND a.availability = 'both_stores'
		AND a.avg_rating > 4.5
		AND a.app_name IN
			(
			SELECT
				UPPER(TRIM(name))
			FROM play_store_apps
			WHERE content_rating LIKE 'Everyone'
			)
		AND a.app_name IN
			(
			SELECT
				UPPER(TRIM(name))
			FROM app_store_apps
			WHERE primary_genre LIKE 'Games'
			)
		ORDER BY pct_roi DESC
	LIMIT 10
	);

-- Check the output
SELECT *
FROM top_10_games_everyone

-- Which apps show up in all 4 lists?
SELECT
	*
FROM all_apps
WHERE app_name IN	
		(
		SELECT app_name
		FROM top_10_overall
		)
	AND	app_name IN	
		(
		SELECT app_name
		FROM top_10_everyone
		)
	AND	app_name IN	
		(
		SELECT app_name
		FROM top_10_games
		)
	AND	app_name IN	
		(
		SELECT app_name
		FROM top_10_games_everyone
		)