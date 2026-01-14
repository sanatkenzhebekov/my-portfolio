--Расчёт метрик сервиса доставки еды

--Расчёт DAU
SELECT
    log_date,
    COUNT(DISTINCT user_id) AS DAU
FROM analytics_events
WHERE 
    city_id = (SELECT city_id FROM cities WHERE city_name = 'Саранск') -- Находим ID Саранска
    AND event = 'order' -- Критерий активности - событие заказа
    AND user_id IS NOT NULL -- Убеждаемся, что пользователь зарегистрирован
    AND log_date BETWEEN '2021-05-01' AND '2021-06-30' -- Период май-июнь
GROUP BY log_date
ORDER BY log_date ASC -- Сортировка по дате по возрастанию
LIMIT 10; -- Ограничение выгрузки первыми 10 строками

-- | log_date | dau |
-- |----------|-----|
-- | 2021-05-01 | 56 |
-- | 2021-05-02 | 36 |
-- | 2021-05-03 | 72 |
-- | 2021-05-04 | 85 |
-- | 2021-05-05 | 60 |
-- | 2021-05-06 | 52 |
-- | 2021-05-07 | 52 |
-- | 2021-05-08 | 52 |
-- | 2021-05-09 | 33 |
-- | 2021-05-10 | 35 |

--Расчёт Conversion Rate
SELECT log_date,
       ROUND((COUNT(DISTINCT user_id) FILTER (WHERE event = 'order')) / COUNT(DISTINCT user_id)::numeric, 2) AS CR
FROM analytics_events
JOIN cities ON analytics_events.city_id = cities.city_id
WHERE log_date BETWEEN '2021-05-01' AND '2021-06-30'
    AND city_name = 'Саранск'
GROUP BY log_date
ORDER BY log_date
LIMIT 10;

-- | log_date | cr |
-- |----------|-----|
-- | 2021-05-01 | 0.43 |
-- | 2021-05-02 | 0.28 |
-- | 2021-05-03 | 0.41 |
-- | 2021-05-04 | 0.41 |
-- | 2021-05-05 | 0.32 |
-- | 2021-05-06 | 0.25 |
-- | 2021-05-07 | 0.28 |
-- | 2021-05-08 | 0.33 |
-- | 2021-05-09 | 0.28 |
-- | 2021-05-10 | 0.30 |

--Расчёт среднего чека
-- Рассчитываем величину комиссии с каждого заказа, отбираем заказы по дате и городу
WITH orders AS
    (SELECT *,
            revenue * commission AS commission_revenue
     FROM analytics_events
     JOIN cities ON analytics_events.city_id = cities.city_id
     WHERE revenue IS NOT NULL
         AND log_date BETWEEN '2021-05-01' AND '2021-06-30'
         AND city_name = 'Саранск')

SELECT
    DATE_TRUNC('month', log_date)::date AS "Месяц",
    COUNT(DISTINCT order_id) AS "Количество заказов",
    ROUND(SUM(commission_revenue)::numeric, 2) AS "Сумма комиссии",
    ROUND(SUM(commission_revenue)::numeric / COUNT(DISTINCT order_id), 2) AS "Средний чек"
FROM orders
WHERE event = 'order'
GROUP BY DATE_TRUNC('month', log_date)::date
ORDER BY "Месяц" ASC;

-- | Месяц | Количество заказов | Сумма комиссии | Средний чек |
-- |-------|-------------------|----------------|-------------|
-- | 2021-05-01 | 2 111 | 286 852 | 135.88 |
-- | 2021-06-01 | 2 225 | 328 539 | 147.66 |

--Расчёт LTV ресторанов
-- Рассчитываем величину комиссии с каждого заказа, отбираем заказы по дате и городу
WITH orders AS
    (SELECT analytics_events.rest_id,
            analytics_events.city_id,
            revenue * commission AS commission_revenue
     FROM analytics_events
     JOIN cities ON analytics_events.city_id = cities.city_id
     WHERE revenue IS NOT NULL
         AND log_date BETWEEN '2021-05-01' AND '2021-06-30'
         AND city_name = 'Саранск')

SELECT
    o.rest_id,
    p.chain AS "Название сети",
    p.type AS "Тип кухни",
    ROUND(SUM(o.commission_revenue)::numeric, 2) AS LTV
FROM orders o
JOIN partners p ON o.rest_id = p.rest_id AND o.city_id = p.city_id
WHERE o.rest_id IS NOT NULL
GROUP BY o.rest_id, p.chain, p.type
ORDER BY LTV DESC
LIMIT 3;

-- | rest_id | Название сети | Тип кухни | ltv |
-- |---------|---------------|-----------|-----|
-- | 2e2b2b9c458b42ce9da395ba9c247fdc | Гурманское Наслаждение | Ресторан | 170,479.00 |
-- | b94505e7efff41d2b2bf6bbb78fe71f2 | Гастрономический Шторм | Ресторан | 164,508.00 |
-- | 42d14fe9fd254ba9b18ab4acd64d4f33 | Шоколадный Рай | Кондитерская | 61,199.80 |

--Расчёт LTV ресторанов — самые популярные блюда
-- Рассчитываем величину комиссии с каждого заказа, отбираем заказы по дате и городу
WITH orders AS
    (SELECT analytics_events.rest_id,
            analytics_events.city_id,
            analytics_events.object_id,
            revenue * commission AS commission_revenue
     FROM analytics_events
     JOIN cities ON analytics_events.city_id = cities.city_id
     WHERE revenue IS NOT NULL
         AND log_date BETWEEN '2021-05-01' AND '2021-06-30'
         AND city_name = 'Саранск'), 

-- Рассчитываем два ресторана с наибольшим LTV 
top_ltv_restaurants AS
    (SELECT orders.rest_id,
            chain,
            type,
            ROUND(SUM(commission_revenue)::numeric, 2) AS LTV
     FROM orders
     JOIN partners ON orders.rest_id = partners.rest_id AND orders.city_id = partners.city_id
     GROUP BY 1, 2, 3
     ORDER BY LTV DESC
     LIMIT 2)

SELECT
    t.chain AS "Название сети",
    d.name AS "Название блюда",
    d.spicy,
    d.fish,
    d.meat,
    ROUND(SUM(o.commission_revenue)::numeric, 2) AS LTV
FROM orders o
JOIN top_ltv_restaurants t ON o.rest_id = t.rest_id
JOIN dishes d ON o.object_id = d.object_id
WHERE o.object_id IS NOT NULL
GROUP BY t.chain, d.name, d.spicy, d.fish, d.meat
ORDER BY LTV DESC
LIMIT 5;

-- | Название сети | Название блюда | spicy | fish | meat | ltv |
-- |---------------|----------------|-------|------|------|-----|
-- | Гастрономический Шторм | brokkoli zapechennaja v duhovke s jajcami i travami | 0 | 1 | 1 | 41,140.4 |
-- | Гурманское Наслаждение | govjazhi shashliki v pesto iz kinzi | 0 | 1 | 1 | 36,676.8 |
-- | Гурманское Наслаждение | medaloni iz lososja | 0 | 1 | 1 | 14,946.9 |
-- | Гурманское Наслаждение | myasnye ezhiki | 0 | 0 | 1 | 14,337.9 |
-- | Гастрономический Шторм | teljatina s sousom iz belogo vina petrushki | 0 | 1 | 1 | 13,981.0 |

--Расчёт Retention Rate
-- Рассчитываем новых пользователей по дате первого посещения продукта
WITH new_users AS
    (SELECT DISTINCT first_date,
                     user_id
     FROM analytics_events
     JOIN cities ON analytics_events.city_id = cities.city_id
     WHERE first_date BETWEEN '2021-05-01' AND '2021-06-24'
         AND city_name = 'Саранск'),

-- Рассчитываем активных пользователей по дате события
active_users AS
    (SELECT DISTINCT log_date,
                     user_id
     FROM analytics_events
     JOIN cities ON analytics_events.city_id = cities.city_id
     WHERE log_date BETWEEN '2021-05-01' AND '2021-06-30'
         AND city_name = 'Саранск'),

retention_data AS (
    SELECT
        n.first_date,
        n.user_id,
        a.log_date,
        (a.log_date - n.first_date) AS day_since_install
    FROM new_users n
    LEFT JOIN active_users a ON n.user_id = a.user_id 
        AND a.log_date >= n.first_date
        AND (a.log_date - n.first_date) BETWEEN 0 AND 7
)

SELECT
    day_since_install,
    COUNT(DISTINCT user_id) AS retained_users,
    ROUND(
        COUNT(DISTINCT user_id)::numeric/ 
        (SELECT COUNT(DISTINCT user_id) FROM new_users),
        2
    ) AS retention_rate
FROM retention_data
WHERE day_since_install IS NOT NULL
GROUP BY day_since_install
ORDER BY day_since_install ASC;

-- | day_since_install | retained_users | retention_rate |
-- |-------------------|----------------|----------------|
-- | 0 | 5 572 | 1.00 |
-- | 1 | 768 | 0.14 |
-- | 2 | 419 | 0.08 |
-- | 3 | 283 | 0.05 |
-- | 4 | 251 | 0.05 |
-- | 5 | 207 | 0.04 |
-- | 6 | 205 | 0.04 |
-- | 7 | 205 | 0.04 |

--Сравнение Retention Rate по месяцам
-- Рассчитываем новых пользователей по дате первого посещения продукта
WITH new_users AS
    (SELECT DISTINCT first_date,
                     user_id
     FROM analytics_events
     JOIN cities ON analytics_events.city_id = cities.city_id
     WHERE first_date BETWEEN '2021-05-01' AND '2021-06-24'
         AND city_name = 'Саранск'),

-- Рассчитываем активных пользователей по дате события
active_users AS
    (SELECT DISTINCT log_date,
                     user_id
     FROM analytics_events
     JOIN cities ON analytics_events.city_id = cities.city_id
     WHERE log_date BETWEEN '2021-05-01' AND '2021-06-30'
         AND city_name = 'Саранск'),

-- Соединяем таблицы с новыми и активными пользователями
daily_retention AS
    (SELECT new_users.user_id,
            first_date,
            log_date::date - first_date::date AS day_since_install
     FROM new_users
     JOIN active_users ON new_users.user_id = active_users.user_id
     AND log_date >= first_date),

-- Рассчитываем общее количество пользователей по месяцам
cohort_sizes AS (
    SELECT 
        CAST(DATE_TRUNC('month', first_date) AS date) AS cohort_month,
        COUNT(DISTINCT user_id) AS total_users
    FROM new_users
    GROUP BY CAST(DATE_TRUNC('month', first_date) AS date)
)

SELECT
    CAST(DATE_TRUNC('month', dr.first_date) AS date) AS "Месяц",
    dr.day_since_install,
    COUNT(DISTINCT dr.user_id) AS retained_users,
    ROUND(
        COUNT(DISTINCT dr.user_id)::numeric / MAX(cs.total_users),
        2
    ) AS retention_rate
FROM daily_retention dr
JOIN cohort_sizes cs ON CAST(DATE_TRUNC('month', dr.first_date) AS date) = cs.cohort_month
WHERE dr.day_since_install BETWEEN 0 AND 7
GROUP BY "Месяц", dr.day_since_install
ORDER BY "Месяц" ASC, dr.day_since_install ASC;

-- | Месяц | day_since_install | retained_users | retention_rate |
-- |-------|-------------------|----------------|----------------|
-- | 2021-05-01 | 0 | 3 069 | 1.00 |
-- | 2021-05-01 | 1 | 443 | 0.14 |
-- | 2021-05-01 | 2 | 223 | 0.07 |
-- | 2021-05-01 | 3 | 144 | 0.05 |
-- | 2021-05-01 | 4 | 142 | 0.05 |
-- | 2021-05-01 | 5 | 122 | 0.04 |
-- | 2021-05-01 | 6 | 120 | 0.04 |
-- | 2021-05-01 | 7 | 140 | 0.05 |
-- | 2021-06-01 | 0 | 2 576 | 1.00 |
-- | 2021-06-01 | 1 | 328 | 0.13 |
-- | 2021-06-01 | 2 | 196 | 0.08 |
-- | 2021-06-01 | 3 | 140 | 0.05 |
-- | 2021-06-01 | 4 | 109 | 0.04 |
-- | 2021-06-01 | 5 | 86 | 0.03 |
-- | 2021-06-01 | 6 | 85 | 0.03 |
-- | 2021-06-01 | 7 | 65 | 0.03 |
