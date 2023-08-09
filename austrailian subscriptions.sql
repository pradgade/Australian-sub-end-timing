-- Code for Australia sub end timings

-- Extracted australian subscriptions ended in last 2 weeks which were not sub rollers.
DROP TEMPORARY TABLE IF EXISTS aus;

CREATE TEMPORARY TABLE aus
	(KEY (user_id))
SELECT sui.sub_ux_id,
			 sui.user_id,
			 ux_start_date,
			 ux_end_date,
			 sub_type
FROM analytics.sub_ux_ind AS sui
	LEFT JOIN analytics.user_info_subs AS uis
		ON sui.user_id = uis.user_id
WHERE ux_end_date BETWEEN DATE_SUB(CURDATE(), INTERVAL 2 WEEK) AND CURDATE() -- Only looking at 2 weeks data
	AND rolled_sub = 0                                                         -- Not a sub roller
	AND uis.country_id = 12 -- For Australia
;

SELECT MIN(ux_end_date),
			 MAX(ux_end_date)
FROM aus;

-- Extracted users who viewed resources 12 hours leading up to the end of the sub end date
DROP TEMPORARY TABLE IF EXISTS res_viewed;

CREATE TEMPORARY TABLE res_viewed
SELECT a.sub_ux_id,
			 a.user_id,
			 a.sub_type,
			 a.ux_end_date,
			 mtrv.datetime,
			 mtrv.career_id
FROM aus AS a
	JOIN analytics.meta_temp_resource_views AS mtrv
		ON a.user_id = mtrv.user_id
WHERE DATE(mtrv.datetime) = a.ux_end_date
	AND TIME(mtrv.datetime) BETWEEN '12:00:00' AND '23:59:59';

SELECT *
FROM res_viewed;

-- Created duplicate of temporary table res_viewed to access twice in the below analysis table

DROP TEMPORARY TABLE IF EXISTS rv_dup;

CREATE TEMPORARY TABLE rv_dup AS
SELECT *
FROM res_viewed;

-- Created temporary table for analysis

DROP TEMPORARY TABLE IF EXISTS analysis;

CREATE TEMPORARY TABLE analysis AS
SELECT t1.ux_end_date, t1.no_views, t2.number_of_users_viewed
FROM (
			 SELECT aus.ux_end_date,
							COUNT(DISTINCT aus.user_id) AS no_views
			 FROM aus
				 LEFT JOIN rv_dup AS rv
					 ON aus.user_id = rv.user_id
			 WHERE rv.user_id IS NULL
			 GROUP BY aus.ux_end_date
		 ) t1
	JOIN
(
	SELECT ux_end_date,
				 COUNT(DISTINCT user_id) AS number_of_users_viewed
	FROM res_viewed
	GROUP BY ux_end_date
) t2
		ON t1.ux_end_date = t2.ux_end_date;


SELECT *
FROM analysis;

-- Most popular career_id among these australian users
SELECT career_id,
			 COUNT(career_id) AS count
FROM res_viewed
GROUP BY career_id
ORDER BY count DESC
LIMIT 5;

-- In general popular career_id among these australian users during the last two weeks

SELECT career_id,
			 COUNT(career_id) AS count
FROM analytics.meta_temp_resource_views
WHERE datetime BETWEEN DATE_SUB(CURDATE(), INTERVAL 2 WEEK) AND CURDATE()
	AND country_id = 12
GROUP BY career_id
ORDER BY count DESC
LIMIT 5;


-- Extracted users who downloaded resources 12 hours leading up to the end of the sub end date
DROP TEMPORARY TABLE IF EXISTS res_down;

CREATE TEMPORARY TABLE res_down
SELECT a.sub_ux_id,
			 a.user_id,
			 a.sub_type,
			 a.ux_end_date,
			 gmtdl.datetime,
			 gmtdl.career_id
FROM aus AS a
	JOIN george_meta_temp_download_log AS gmtdl
		ON a.user_id = gmtdl.user_id
WHERE DATE(gmtdl.datetime) = a.ux_end_date
	AND TIME(gmtdl.datetime) BETWEEN '12:00:00' AND '23:59:59';


-- Most popular career_id among these australian users
SELECT career_id,
			 COUNT(career_id)
FROM res_down
GROUP BY career_id;


-- Rough work

SELECT *
FROM aus
	JOIN analytics.meta_temp_resource_views AS mtrv
		ON aus.user_id = mtrv.user_id
WHERE date BETWEEN DATE_SUB(CURDATE(), INTERVAL 2 WEEK) AND CURDATE();

SELECT DISTINCT (outcome_type)
FROM cancellation_downgrade_pause_metrics;

SELECT *
FROM aus AS a
	JOIN analytics.meta_temp_resource_views AS mtrv
		ON a.user_id = mtrv.user_id
		AND DATE_FORMAT(mtrv.datetime, '%Y-%m-%d') = a.ux_end_date
WHERE mtrv.datetime BETWEEN CONCAT(a.ux_end_date, ' 23:59:00') AND DATE_SUB(CONCAT(a.ux_end_date, ' 23:59:00'), INTERVAL 12 HOUR);



