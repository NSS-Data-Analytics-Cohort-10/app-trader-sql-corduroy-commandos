SELECT *
FROM app_store_apps

SELECT *
FROM play_store_apps

-- PRESENTATIONS @ NOON ON SATURDAY

-- OVERVIEW --
-- Your team has been hired by a new company called App Trader to help them explore and gain insights from apps that are made available through the Apple App Store and Android Play Store. App Trader is a broker that purchases the rights to apps from developers in order to market the apps and offer in-app purchase.

-- PERSONAL NOTES -- 

-- Top 10 (six with the highest revenue the rest tie) apps that are going to give the company the most revenue
-- Stick to assumptions 
-- Create query that will give app trader the most profitable apps 
-- Up to you to decide to get the answer 
-- Buisness proposal 

-- 2. Assumptions
-- Based on research completed prior to launching App Trader as a company, you can assume the following:

-- a. App Trader will purchase apps for 10,000 times the price of the app. For apps that are priced from free up to $1.00, the purchase price is $10,000.For example, an app that costs $2.00 will be purchased for $20,000. The cost of an app is not affected by how many app stores it is on. A $1.00 app on the Apple app store will cost the same as a $1.00 app on both stores.
-- If an app is on both stores, it's purchase price will be calculated based off of the highest app price between the two stores. Notes: 10,000 X price of app
-- calculate purchase prices for each app
--figure out which apps are in both app stores

SELECT 
    name,
    CAST(price AS money) AS price,
    CASE 
        WHEN CAST(price AS money) = 0::money THEN 10000::money 
        ELSE CAST(price AS money) * 10000 
    END AS purchase_price
FROM app_store_apps
ORDER BY price DESC;

SELECT 
	name,
	CAST(price AS money) AS price,
	CASE 	
		WHEN CAST(price AS money) = 0::money THEN 10000::money
		ELSE CAST (price AS money) * 10000
	END AS purchase_price
FROM play_store_apps
ORDER BY price DESC

-- b. Apps earn $5000 per month, per app store it is on, from in-app advertising and in-app purchases, regardless of the price of the app.

-- An app that costs $200,000 will make the same per month as an app that costs $1.00.

-- An app that is on both app stores will make $10,000 per month.
-- PERSONAL NOTES
--calculate montly revenue per app 

-- c. App Trader will spend an average of $1000 per month to market an app regardless of the price of the app. If App Trader owns rights to the app in both stores, it can market the app for both stores for a single cost of $1000 per month.
-- An app that costs $200,000 and an app that costs $1.00 will both cost $1000 a month for marketing, regardless of the number of stores it is in.
-- PERSONAL NOTES

-- CALCULATE MARKETING COST? 

-- d. For every half point that an app gains in rating, its projected lifespan increases by one year. In other words, an app with a rating of 0 can be expected to be in use for 1 year, an app with a rating of 1.0 can be expected to last 3 years, and an app with a rating of 4.0 can be expected to last 9 years.
-- App store ratings should be calculated by taking the average of the scores from both app stores and rounding to the nearest 0.5.

--CALCULATE RATING LIFESPAN


-- e. App Trader would prefer to work with apps that are available in both the App Store and the Play Store since they can market both for the same $1000 per month.

-- IDENTIFY APPS THAT ARE IN BOTH STORES

-- 3. Deliverables
-- a. Develop some general recommendations as to the price range, genre, content rating, or anything else for apps that the company should target.

-- b. Develop a Top 10 List of the apps that App Trader should buy.

-- c. Submit a report based on your findings. All analysis work must be done using PostgreSQL, however you may export query results to create charts in Excel for your report.