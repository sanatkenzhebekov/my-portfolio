-- Итоговый проект. Анализ недвижимости в СПБ и Ленинградской области для агенства недвижимости.
-- Цель проекта: Определить наиболее привлекательные сегменты недвижимости Санкт-Петербурга 
-- и городов Ленинградской области, чтобы создать эффективную бизнес-стратегию на рынке недвижимости.
-- Понять сезонные тенденции на рынке Санкт-Петербурга и городов Ленинградской области, чтобы знать 
-- периоды с повышенной активностью продавцов и покупателей недвижимости в регионе.
-- Выяснить, в каких населённых пунктах Ленинградской области активнее всего продаётся недвижимость 
-- и какая именно, чтобы знать перспективные районы.

-- Автор: Кенжебеков Санат
-- Дата: 21.05.25


-- Проверка пропусков
SELECT 
  COUNT(*) FILTER (WHERE total_area IS NULL) AS missing_total_area,
  COUNT(*) FILTER (WHERE ceiling_height IS NULL) AS missing_ceiling_height,
  COUNT(*) FILTER (WHERE kitchen_area IS NULL) AS missing_kitchen_area
FROM real_estate.flats;

--|missing_total_area|missing_ceiling_height|missing_kitchen_area|
--|------------------|----------------------|--------------------|
--|0                 |9 160                 |2 269               |


-- Минимум и максимум по числовым признакам
SELECT 
  MIN(total_area) AS min_total_area, MAX(total_area) AS max_total_area,
  MIN(ceiling_height) AS min_ceiling_height, MAX(ceiling_height) AS max_ceiling_height,
  MIN(last_price) AS min_last_price, MAX(last_price) AS max_last_price
FROM real_estate.flats f 
JOIN real_estate.advertisement a ON f.id = a.id;

--|min_total_area|max_total_area|min_ceiling_height|max_ceiling_height|min_last_price|max_last_price|
--|--------------|--------------|------------------|------------------|--------------|--------------|
--|12            |900           |1                 |100               |12 190        |763 000 000   |

-- Диапазон времени имеющихся данных
SELECT 
  MIN(first_day_exposition) AS first_date,
  MAX(first_day_exposition) AS last_date
FROM real_estate.advertisement a; 

--|first_date|last_date |
--|----------|----------|
--|2014-11-27|2019-05-03|

-- Распределение объявлений по населённым пунктам в зависимости от их типа
SELECT 
  t.type,
  COUNT(DISTINCT c.city_id) AS num_cities,
  COUNT(*) AS num_ads
FROM real_estate.flats f
JOIN real_estate.city c ON f.city_id = c.city_id
JOIN real_estate.type t ON f.type_id = t.type_id
JOIN real_estate.advertisement a ON f.id = a.id
GROUP BY t.type
ORDER BY num_ads DESC;

--|type                                     |num_cities|num_ads|
--|-----------------------------------------|----------|-------|
--|город                                    |43        |20 008 |
--|посёлок                                  |113       |2 092  |
--|деревня                                  |106       |945    |
--|посёлок городского типа                  |30        |363    |
--|городской посёлок                        |13        |187    |
--|село                                     |9         |32     |
--|посёлок при железнодорожной станции      |6         |15     |
--|садовое товарищество                     |4         |4      |
--|коттеджный посёлок                       |3         |3      |
--|садоводческое некоммерческое товарищество|1         |1      |

-- Основная статистика по времени активности обьявлений
SELECT 
  MIN(days_exposition) AS min_days,
  MAX(days_exposition) AS max_days,
  ROUND(AVG(days_exposition::numeric), 2) AS avg_days,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY days_exposition) AS median_days
FROM real_estate.advertisement
WHERE days_exposition IS NOT NULL;

--|min_days|max_days|avg_days|median_days|
--|--------|--------|--------|-----------|
--|1       |1 580   |180,75  |95         |

-- Доля снятых обьявлений с публикации
SELECT 
  ROUND(
    100.0 * COUNT(days_exposition) / COUNT(*), 
    2
  ) AS percent_removed
FROM real_estate.advertisement;

--|percent_removed|
--|---------------|
--|86,55          |

-- Доля обьявлений о продаже недвижимости в СПБ.
SELECT 
  ROUND(
    100.0 * COUNT(CASE WHEN c.city = 'Санкт-Петербург' THEN 1 END) / COUNT(*),
    2
  ) AS spb_percent
FROM real_estate.flats f
JOIN real_estate.city c ON f.city_id = c.city_id
JOIN real_estate.advertisement a ON f.id = a.id;

--|spb_percent|
--|-----------|
--|66,47      |

-- Статистика значений стоимости 1кв.м2
SELECT 
  ROUND(MIN((a.last_price / f.total_area)::numeric), 2) AS min_price_per_m2,
  ROUND(MAX((a.last_price / f.total_area)::numeric), 2) AS max_price_per_m2,
  ROUND(AVG((a.last_price / f.total_area)::numeric), 2) AS avg_price_per_m2,
  ROUND(
    (PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY (a.last_price / f.total_area)))::numeric, 
    2
  ) AS median_price_per_m2
FROM real_estate.flats f
JOIN real_estate.advertisement a ON f.id = a.id
WHERE a.last_price IS NOT NULL 
  AND f.total_area IS NOT NULL 
  AND f.total_area > 0;

--|min_price_per_m2|max_price_per_m2|avg_price_per_m2|median_price_per_m2|
--|----------------|----------------|----------------|-------------------|
--|111,84          |1 907 500       |99 432,25       |95 000             |

-- Статистические показатели 
-- — минимальное и максимальное значения, среднее значение, медиану и 99 перцентиль 
-- по следующим количественным данным: общая площадь недвижимости, количество комнат и балконов, высота потолков, этаж.

SELECT
  -- Общая площадь
  ROUND(MIN(total_area)::numeric, 2) AS min_total_area,
  ROUND(MAX(total_area)::numeric, 2) AS max_total_area,
  ROUND(AVG(total_area)::numeric, 2) AS avg_total_area,
  ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_area)::numeric, 2) AS median_total_area,
  ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY total_area)::numeric, 2) AS p99_total_area, 
  -- Количество комнат
  MIN(rooms) AS min_rooms,
  MAX(rooms) AS max_rooms,
  ROUND(AVG(rooms)::numeric, 2) AS avg_rooms,
  ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY rooms)::numeric, 2) AS median_rooms,
  ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY rooms)::numeric, 2) AS p99_rooms,
  -- Количество балконов
  MIN(balcony) AS min_balcony,
  MAX(balcony) AS max_balcony,
  ROUND(AVG(balcony)::numeric, 2) AS avg_balcony,
  ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY balcony)::numeric, 2) AS median_balcony,
  ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY balcony)::numeric, 2) AS p99_balcony,
  -- Высота потолков
  ROUND(MIN(ceiling_height)::numeric, 2) AS min_ceiling_height,
  ROUND(MAX(ceiling_height)::numeric, 2) AS max_ceiling_height,
  ROUND(AVG(ceiling_height)::numeric, 2) AS avg_ceiling_height,
  ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ceiling_height)::numeric, 2) AS median_ceiling_height,
  ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY ceiling_height)::numeric, 2) AS p99_ceiling_height,
  -- Этаж
  MIN(floor) AS min_floor,
  MAX(floor) AS max_floor,
  ROUND(AVG(floor)::numeric, 2) AS avg_floor,
  ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY floor)::numeric, 2) AS median_floor,
  ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY floor)::numeric, 2) AS p99_floor
FROM real_estate.flats f;
--По площади квартиры
--|min_total_area|max_total_area|avg_total_area|median_total_area|p99_total_area|
--|--------------|--------------|--------------|-----------------|--------------|
--|12            |900           |60,33         |52               |197,56        |

--По кол-ву комнат
--|min_rooms|max_rooms|avg_rooms|median_rooms|p99_rooms|
--|---------|---------|---------|------------|---------|
--|0        |19       |2,07     |2           |5        |

--По кол-ву балконов
--|min_balcony|max_balcony|avg_balcony|median_balcony|p99_balcony|
--|-----------|-----------|-----------|--------------|-----------|
--|0          |5          |1,15       |1             |5          |

--По высоте потолков
--|min_ceiling_height|max_ceiling_height|avg_ceiling_height|median_ceiling_height|p99_ceiling_height|
--|------------------|------------------|------------------|---------------------|------------------|
--|1                 |100               |2,77              |2,65                 |3,82              |

--По этажам квартиры
--|min_floor|max_floor|avg_floor|median_floor|p99_floor|
--|---------|---------|---------|------------|---------|
--|1        |33       |5,89     |4           |23       |

-- Решение ad-hoc задачи 1.Время активности объявлений
-- Разделим объявления на категории по количеству дней активности 
-- и для каждой категории изучите параметры продаваемых квартир, 
-- включая среднюю стоимость квадратного метра, среднюю площадь недвижимости, 
-- количество комнат и балконов. Сравним объявления Санкт-Петербурга и городов Ленинградской области.

-- Шаг 1: фильтрация выбросов
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY f.total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY f.rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY f.balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY f.ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY f.ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats f
),
filtered_id AS (
    SELECT id
    FROM real_estate.flats f
    WHERE 
        f.total_area < (SELECT total_area_limit FROM limits)
        AND (f.rooms < (SELECT rooms_limit FROM limits) OR f.rooms IS NULL)
        AND (f.balcony < (SELECT balcony_limit FROM limits) OR f.balcony IS NULL)
        AND ((f.ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND f.ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR f.ceiling_height IS NULL)
),
-- Шаг 2: подготовка объединённых данных
prepared_data AS (
    SELECT
        a.id,
        CASE 
            WHEN c.city = 'Санкт-Петербург' THEN 'СПб'
            ELSE 'ЛенОбл'
        END AS region,
        a.days_exposition AS active_days,
        CASE 
            WHEN a.days_exposition BETWEEN 1 AND 30 THEN 'до 1 мес'
            WHEN a.days_exposition BETWEEN 31 AND 90 THEN '1–3 мес'
            WHEN a.days_exposition BETWEEN 91 AND 180 THEN '3–6 мес'
            WHEN a.days_exposition >= 181 THEN 'более 6 мес'
            ELSE 'неизвестно'
        END AS activity_category,
        f.total_area,
        f.rooms,
        f.balcony,
        f.ceiling_height,
        ROUND((a.last_price / f.total_area)::numeric, 2) AS price_per_m2
    FROM real_estate.advertisement a
    JOIN real_estate.flats f ON a.id = f.id
    JOIN real_estate.city c ON f.city_id = c.city_id
    JOIN filtered_id fi ON a.id = fi.id
    WHERE a.days_exposition IS NOT NULL
)
-- Шаг 3: итоговая агрегация
SELECT
    region,
    activity_category,
    COUNT(*) AS ads_count,
    ROUND(AVG(price_per_m2), 2) AS avg_price_per_m2,
    ROUND((AVG(total_area))::numeric, 2) AS avg_area,
    ROUND(AVG(rooms), 2) AS avg_rooms,
    ROUND((AVG(balcony))::numeric, 2) AS avg_balconies,
    ROUND((AVG(ceiling_height))::numeric, 2) AS avg_ceiling_height
FROM prepared_data
GROUP BY region, activity_category
ORDER BY region, 
         CASE activity_category
             WHEN 'до 1 мес' THEN 1
             WHEN '1–3 мес' THEN 2
             WHEN '3–6 мес' THEN 3
             WHEN 'более 6 мес' THEN 4
             ELSE 5
         END;

--|region|activity_category|ads_count|avg_price_per_m2|avg_area|avg_rooms|avg_balconies|avg_ceiling_height|
--|------|-----------------|---------|----------------|--------|---------|-------------|------------------|
--|ЛенОбл|до 1 мес         |862      |75 534,56       |47,86   |1,62     |1,1          |2,7               |
--|ЛенОбл|1–3 мес          |1 869    |70 607,31       |49,41   |1,75     |1,07         |2,69              |
--|ЛенОбл|3–6 мес          |1 119    |70 608,4        |50,77   |1,79     |1,02         |2,69              |
--|ЛенОбл|более 6 мес      |1 705    |69 192,9        |52,84   |1,89     |0,95         |2,7               |
--|СПб   |до 1 мес         |2 168    |110 568,88      |54,38   |1,87     |1,07         |2,76              |
--|СПб   |1–3 мес          |3 236    |111 573,23      |56,71   |1,92     |1,01         |2,77              |
--|СПб   |3–6 мес          |2 254    |111 938,93      |60,55   |2,03     |0,95         |2,79              |
--|СПб   |более 6 мес      |3 581    |115 457,22      |66,15   |2,17     |0,92         |2,83              |


-- Решение ad-hoc задачи 2.Сезонность объявлений
-- Изучаем сезонные тенденции на рынке недвижимости Санкт-Петербурга и Ленинградской области — то есть для всего региона, 
-- чтобы выявить периоды с повышенной активностью продавцов и покупателей недвижимости. 

-- Шаг 1: фильтрация выбросов
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY f.total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY f.rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY f.balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY f.ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY f.ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats f
),
filtered_id AS (
    SELECT id
    FROM real_estate.flats f
    WHERE 
        f.total_area < (SELECT total_area_limit FROM limits)
        AND (f.rooms < (SELECT rooms_limit FROM limits) OR f.rooms IS NULL)
        AND (f.balcony < (SELECT balcony_limit FROM limits) OR f.balcony IS NULL)
        AND ((f.ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND f.ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR f.ceiling_height IS NULL)
),
-- Шаг 2: подготовка данных с фильтрацией выбросов
ads_dates AS (
    SELECT
        a.id,
        a.first_day_exposition,
        a.days_exposition,
        f.total_area,
        ROUND((a.last_price::numeric / NULLIF(f.total_area, 0))::numeric, 2) AS price_per_m2,
        -- Месяц публикации
        EXTRACT(MONTH FROM a.first_day_exposition) AS pub_month_num,
        -- Месяц снятия (если известно)
        CASE 
            WHEN a.days_exposition IS NOT NULL 
            THEN EXTRACT(MONTH FROM a.first_day_exposition + a.days_exposition * INTERVAL '1 day')
        END AS rem_month_num
    FROM real_estate.advertisement a
    JOIN real_estate.flats f ON a.id = f.id
    JOIN filtered_id fi ON a.id = fi.id  -- Добавляем фильтрацию по выбросам
    WHERE f.total_area IS NOT NULL AND a.last_price IS NOT NULL
),
month_names AS (
    SELECT 1 AS month_num, 'January' AS month_name UNION ALL
    SELECT 2, 'February' UNION ALL
    SELECT 3, 'March' UNION ALL
    SELECT 4, 'April' UNION ALL
    SELECT 5, 'May' UNION ALL
    SELECT 6, 'June' UNION ALL
    SELECT 7, 'July' UNION ALL
    SELECT 8, 'August' UNION ALL
    SELECT 9, 'September' UNION ALL
    SELECT 10, 'October' UNION ALL
    SELECT 11, 'November' UNION ALL
    SELECT 12, 'December'
),
pub_data AS (
    SELECT
        pub_month_num AS month_num,
        COUNT(*) AS pub_count,
        ROUND(AVG(price_per_m2), 2) AS avg_price_per_m2_pub,
        ROUND((AVG(total_area))::numeric, 2) AS avg_area_pub
    FROM ads_dates
    GROUP BY pub_month_num
),
rem_data AS (
    SELECT
        rem_month_num AS month_num,
        COUNT(*) AS removed_count,
        ROUND(AVG(price_per_m2), 2) AS avg_price_per_m2_rem,
        ROUND((AVG(total_area))::numeric, 2) AS avg_area_rem
    FROM ads_dates
    WHERE rem_month_num IS NOT NULL
    GROUP BY rem_month_num
)
-- Финальный запрос: объединение публикаций и снятий
SELECT
    COALESCE(p.month_num, r.month_num) AS month_num,
    mn.month_name AS month,
    p.pub_count,
    r.removed_count,
    p.avg_price_per_m2_pub,
    r.avg_price_per_m2_rem,
    p.avg_area_pub,
    r.avg_area_rem
FROM pub_data p
FULL OUTER JOIN rem_data r USING (month_num)
JOIN month_names mn ON COALESCE(p.month_num, r.month_num) = mn.month_num
ORDER BY month_num;

--|month_num|month    |pub_count|removed_count|avg_price_per_m2_pub|avg_price_per_m2_rem|avg_area_pub|avg_area_rem|
--|---------|---------|---------|-------------|--------------------|--------------------|------------|------------|
--|1        |January  |1 212    |1 558        |101 439,03          |98 495,62           |57,4        |56,17       |
--|2        |February |2 106    |1 330        |100 035,76          |99 272,77           |58,39       |58,84       |
--|3        |March    |2 000    |1 540        |101 469,71          |101 129,77          |57,61       |57,83       |
--|4        |April    |1 909    |1 684        |103 100,47          |100 964,83          |58,45       |56,87       |
--|5        |May      |1 086    |901          |99 030,27           |95 988,08           |57,5        |55,75       |
--|6        |June     |1 461    |936          |98 780,66           |96 976,64           |56,74       |58,29       |
--|7        |July     |1 369    |1 342        |99 392,37           |97 532,15           |58,48       |57,4        |
--|8        |August   |1 409    |1 375        |100 842,61          |95 198,98           |57,4        |55,5        |
--|9        |September|1 602    |1 477        |101 823,87          |99 647,99           |59,05       |56,18       |
--|10       |October  |1 707    |1 625        |99 454,86           |99 969,06           |57,96       |57,18       |
--|11       |November |1 906    |1 572        |100 370,44          |98 860,17           |58,44       |55,35       |
--|12       |December |1 351    |1 454        |100 070,62          |99 899,47           |58,98       |57,51       |

-- Решение ad-hoc задачи 3.Анализ рынка недвижимости Ленобласти
-- определяем, в каких населённых пунктах Ленинградской области активнее всего продаётся недвижимость и какая именно.

-- Шаг 1: фильтрация выбросов
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY f.total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY f.rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY f.balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY f.ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY f.ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats f
),
filtered_id AS (
    SELECT id
    FROM real_estate.flats f
    WHERE 
        f.total_area < (SELECT total_area_limit FROM limits)
        AND (f.rooms < (SELECT rooms_limit FROM limits) OR f.rooms IS NULL)
        AND (f.balcony < (SELECT balcony_limit FROM limits) OR f.balcony IS NULL)
        AND ((f.ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND f.ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR f.ceiling_height IS NULL)
),
-- Шаг 2: подготовка данных с фильтрацией выбросов
lenobl_ads AS (
    SELECT 
        a.id AS adv_id,
        f.city_id,
        a.last_price AS price,
        f.total_area,
        a.days_exposition,
        CASE 
            WHEN a.days_exposition IS NULL THEN 0  -- активные объявления
            ELSE 1  -- снятые
        END AS is_removed
    FROM real_estate.advertisement a
    JOIN real_estate.flats f ON a.id = f.id
    JOIN real_estate.city c ON f.city_id = c.city_id 
    JOIN filtered_id fi ON a.id = fi.id  -- Добавляем фильтрацию по выбросам
    WHERE c.city <> 'Санкт-Петербург'
),
-- Шаг 3: расчет статистики по городам
stats_by_city AS (
    SELECT
        c.city,
        COUNT(*) AS ads_total,
        SUM(l.is_removed) AS ads_removed,
        ROUND(SUM(l.is_removed)::decimal / COUNT(*) * 100, 2) AS removed_ratio_percent,
        ROUND(AVG(l.price / NULLIF(l.total_area, 0))) AS avg_price_per_m2,
        ROUND((AVG(l.total_area))::numeric, 2) AS avg_area,
        ROUND(AVG(l.days_exposition)::numeric, 1) AS avg_days_exposition
    FROM lenobl_ads l
    JOIN real_estate.city c ON l.city_id = c.city_id 
    GROUP BY c.city 
    HAVING COUNT(*) > 50  -- фильтрация по порогу
)
-- Итоговый результат
SELECT *
FROM stats_by_city
ORDER BY ads_total DESC
LIMIT 15;

--|city           |ads_total|ads_removed|removed_ratio_percent|avg_price_per_m2|avg_area|avg_days_exposition|
--|---------------|---------|-----------|---------------------|----------------|--------|-------------------|
--|Мурино         |568      |532        |93,66                |85 968          |43,86   |149,2              |
--|Кудрово        |463      |434        |93,74                |95 420          |46,2    |160,6              |
--|Шушары         |404      |374        |92,57                |78 832          |53,93   |152                |
--|Всеволожск     |356      |305        |85,67                |69 053          |55,83   |190,1              |
--|Парголово      |311      |288        |92,6                 |90 273          |51,34   |156,2              |
--|Пушкин         |278      |231        |83,09                |104 159         |59,74   |196,6              |
--|Гатчина        |228      |203        |89,04                |69 005          |51,02   |188,1              |
--|Колпино        |227      |209        |92,07                |75 212          |52,55   |147                |
--|Выборг         |192      |168        |87,5                 |58 670          |56,76   |182,3              |
--|Петергоф       |154      |136        |88,31                |85 412          |51,77   |196,6              |
--|Сестрорецк     |149      |134        |89,93                |103 848         |62,45   |214,8              |
--|Красное Село   |136      |122        |89,71                |71 972          |53,2    |205,8              |
--|Новое Девяткино|120      |106        |88,33                |76 879          |50,52   |175,7              |
--|Сертолово      |117      |101        |86,32                |69 566          |53,62   |173,6              |
--|Бугры          |104      |91         |87,5                 |80 968          |47,35   |155,9              |



