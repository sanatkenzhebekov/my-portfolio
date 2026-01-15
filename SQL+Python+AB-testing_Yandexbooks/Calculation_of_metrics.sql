/* Проект «Яндекс книги»
 * Цель: расчет ключевых метрик
 * Автор: Кенжебеков Санат
 * Дата: 25.04.25
*/

-- 1. Расчёт MAU авторов

SELECT 
    a.main_author_name,
    COUNT(DISTINCT aud.puid) AS mau
FROM bookmate.audition aud
JOIN bookmate.content c ON aud.main_content_id = c.main_content_id
JOIN bookmate.author a ON c.main_author_id = a.main_author_id
WHERE 
    aud.msk_business_dt_str >= '2024-11-01' 
    AND aud.msk_business_dt_str < '2024-12-01'
GROUP BY a.main_author_name
ORDER BY mau DESC
LIMIT 3;

-- |main_author_name|	mau|
-- |----------------|-----|
-- |Андрей Усачев	 |7107 |
-- |Лиана Шнайдер	 |3338 |
-- |Игорь Носов     |3063 |


-- 2. Расчёт MAU произведений

SELECT 
    c.main_content_name,
    c.published_topic_title_list,
    a.main_author_name,
    COUNT(DISTINCT aud.puid) AS mau
FROM bookmate.audition aud
JOIN bookmate.content c ON aud.main_content_id = c.main_content_id
JOIN bookmate.author a ON c.main_author_id = a.main_author_id
WHERE 
    aud.msk_business_dt_str >= '2024-11-01' 
    AND aud.msk_business_dt_str < '2024-12-01'
GROUP BY 
    c.main_content_name, 
    c.published_topic_title_list, 
    a.main_author_name
ORDER BY mau DESC
LIMIT 3;

-- | main_content_name | published_topic_title_list | main_author_name | mau |
-- |-------------------|----------------------------|------------------|-----|
-- | Собачка Соня на даче | ['Детская проза и поэзия', 'Аудио'] | Андрей Усачев | 4 597 |
-- | Женькин клад и другие школьные рассказы | ['Сказки и фольклор', 'Детская проза и поэзия', 'Аудио'] | Игорь Носов | 3 050 |
-- | Знаменитая собачка Соня | ['Аудиоспектакли', 'Детская проза и поэзия', 'Аудио'] | Андрей Усачев | 2 785 |


-- 3. Расчёт Retention Rate

WITH cohort AS (
    SELECT DISTINCT puid AS user_id
    FROM bookmate.audition
    WHERE CAST(msk_business_dt_str AS date) = DATE '2024-12-02'
),
cohort_size AS (
    SELECT COUNT(*) AS cohort_users_count FROM cohort
),
activity AS (
    SELECT DISTINCT puid AS user_id,
           CAST(msk_business_dt_str AS date) AS log_date
    FROM bookmate.audition
    WHERE puid IS NOT NULL
),
daily_retention AS (
    SELECT c.user_id,
           (a.log_date - DATE '2024-12-02') AS day_since_install
    FROM cohort c
    JOIN activity a USING (user_id)
),
agg AS (
    SELECT
        dr.day_since_install,
        COUNT(DISTINCT dr.user_id) AS retained_users,
        cs.cohort_users_count
    FROM daily_retention dr
    CROSS JOIN cohort_size cs
    WHERE dr.day_since_install >= 0
    GROUP BY dr.day_since_install, cs.cohort_users_count
)
SELECT
    day_since_install,
    retained_users,
    ROUND(1.0 * retained_users / MAX(cohort_users_count) OVER (), 2)::numeric AS retention_rate
FROM agg
ORDER BY day_since_install;

-- | day_since_install | retained_users | retention_rate |
-- |-------------------|----------------|----------------|
-- | 0 | 4 259 | 1.00 |
-- | 1 | 2 698 | 0.63 |
-- | 2 | 2 550 | 0.60 |
-- | 3 | 2 421 | 0.57 |
-- | 4 | 2 231 | 0.52 |
-- | 5 | 1 994 | 0.47 |
-- | 6 | 2 129 | 0.50 |
-- | 7 | 2 287 | 0.54 |
-- | 8 | 2 274 | 0.53 |
-- | 9 | 2 207 | 0.52 |  

-- 4. Расчёт LTV
WITH activity AS (
SELECT
    a.puid,
    g.usage_geo_id_name AS city,
    date_trunc('month', CAST(a.msk_business_dt_str AS date))::date AS month_start
FROM bookmate.audition a
JOIN bookmate.geo g USING (usage_geo_id)
WHERE a.puid IS NOT NULL
    AND CAST(a.msk_business_dt_str AS date) BETWEEN DATE '2024-09-01' AND DATE '2024-12-11'
    AND g.usage_geo_id_name IN ('Москва', 'Санкт-Петербург')
),
user_month_city AS (
SELECT DISTINCT puid AS user_id, city, month_start
FROM activity
),
city_agg AS (
SELECT
    city,
    COUNT(DISTINCT user_id) AS total_users,
    COUNT(*) AS paid_months
FROM user_month_city
GROUP BY city
)
SELECT
    city,
    total_users::numeric,
    ROUND((paid_months * 399)::numeric / NULLIF(total_users, 0), 2)::numeric AS ltv
FROM city_agg
ORDER BY city;

-- | city | total_users | ltv |
-- |------|-------------|-----|
-- | Москва | 16 808 | 764.55 |
-- | Санкт-Петербург | 12 559 | 731.82 |

-- 5. Расчёт средней выручки прослушанного часа — аналог среднего чека
WITH monthly AS(
SELECT
date_trunc('month', CAST(msk_business_dt_str AS date))::date AS month,
puid,
COALESCE(hours, 0)::numeric AS hours
FROM bookmate.audition
WHERE CAST(msk_business_dt_str AS date) BETWEEN DATE '2024-09-01' AND DATE '2024-11-30'
)
SELECT
month,
COUNT(DISTINCT puid) AS mau,
ROUND(SUM(hours)::numeric, 2)::numeric AS hours,
ROUND((COUNT(DISTINCT puid) * 399.0) / NULLIF(SUM(hours), 0), 2)::numeric AS avg_hour_rev
FROM monthly
GROUP BY month
ORDER BY month;

-- | month | mau | hours | avg_hour_rev |
-- |-------|-----|-------|--------------|
-- | 2024-09-01 | 16 320 | 105 539 | 61.70 |
-- | 2024-10-01 | 18 280 | 137 384 | 53.09 |
-- | 2024-11-01 | 18 594 | 145 351 | 51.04 |


-- Подготовка данных для проверки гипотезы
WITH src AS (
SELECT
a.puid,
COALESCE(a.hours, 0)::numeric AS hours,
g.usage_geo_id_name AS city,
CAST(a.msk_business_dt_str AS date) AS dt
FROM bookmate.audition a
LEFT JOIN bookmate.geo g ON a.usage_geo_id = g.usage_geo_id
)
SELECT
city,
puid,
SUM(hours)::numeric AS hours
FROM src
WHERE city IS NOT NULL
AND city IN ('Москва', 'Санкт-Петербург', 'Moscow', 'Saint Petersburg')
GROUP BY city, puid
ORDER BY city, hours DESC;

-- Пример данных первые 5 строк
-- | city | puid | hours |
-- |------|------|-------|
-- | Москва | 6829aafc-f9d6-11ef-be00-c2c9fa6fd3d5 | 248.353 |
-- | Москва | 682b0848-f9d6-11ef-be00-c2c9fa6fd3d5 | 182.309 |
-- | Москва | 682a1b68-f9d6-11ef-be00-c2c9fa6fd3d5 | 174.573 |
-- | Москва | 682c1d28-f9d6-11ef-be00-c2c9fa6fd3d5 | 148.853 |
-- | Москва | 682bda2a-f9d6-11ef-be00-c2c9fa6fd3d5 | 144.343 |
