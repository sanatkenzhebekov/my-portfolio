--Напишем общие запросы для каждой таблицы, чтобы понять их объем и структуру.
--Что мы узнаем из этого запроса?
--Общий объем данных о покупках.
--Все ли order_id уникальны? (Если total_rows = unique_orders, то да).
--Сколько уникальных пользователей и мероприятий у нас в данных.
--Ключевой момент: За какой период у нас данные? Это прямо отвечает на вопрос о сезонности. 
--Сравним first_order_date и last_order_date. Охватывает ли он осень 2024 года?

SELECT 
    COUNT(*) as total_rows,
    COUNT(DISTINCT order_id) as unique_orders,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT event_id) as unique_events,
    MIN(created_dt_msk) as first_order_date,
    MAX(created_dt_msk) as last_order_date
FROM afisha.purchases;

--|total_rows|unique_orders|unique_users|unique_events|first_order_date       |last_order_date        |
--|----------|-------------|------------|-------------|-----------------------|-----------------------|
--|292 034   |292 034      |22 000      |22 484       |2024-06-01 00:00:00.000|2024-10-31 00:00:00.000|

--Анализ результата:
--Объем данных: 292 034 строки с покупками. Это хороший объем для анализа.
--Уникальность заказов: total_rows = unique_orders. Это отличная новость! Значит, дубликатов заказов нет, 
--и order_id можно использовать как первичный ключ.
--Пользователи и события: 22 000 уникальных пользователей и 22 484 уникальных события. 
--Интересное наблюдение: событий почти столько же, сколько пользователей. Это может означать, 
--что в среднем на одно событие приходится мало покупок, или что пользователи редко ходят на несколько разных событий. 
--Это потенциальная тема для дальнейшего исследования.
--Период данных: Ключевой момент!
--Первая покупка: 1 июня 2024 г.
--Последняя покупка: 31 октября 2024 г.
--Вывод: У нас есть данные за 5 полных месяцев: июнь, июль, август, сентябрь, октябрь. 
--Это полностью покрывает осенний период (сентябрь, октябрь), который интересует продукт, и дает летние месяцы для сравнения. 
--Мы можем отследить, как менялись продажи с лета на осень.

--Аналогичные запросы стоит выполнить для других таблиц (events, venues, city, regions), чтобы понять их размер.

--events
SELECT 
    COUNT(*) as total_events,
    COUNT(DISTINCT event_id) as unique_event_id,
    COUNT(DISTINCT event_name_code) as unique_event_names,
    COUNT(DISTINCT event_type_main) as unique_event_types,
    COUNT(DISTINCT city_id) as cities_with_events,
    COUNT(DISTINCT venue_id) as unique_venues
FROM afisha.events;

--|total_events|unique_event_id|unique_event_names|unique_event_types|cities_with_events|unique_venues|
--|------------|---------------|------------------|------------------|------------------|-------------|
--|22 484      |22 484         |15 287            |8                 |353               |3 228        |

--venues
SELECT 
    COUNT(*) as total_venues,
    COUNT(DISTINCT venue_id) as unique_venue_id,
    COUNT(DISTINCT venue_name) as unique_venue_names
FROM afisha.venues;

--|total_venues|unique_venue_id|unique_venue_names|
--|------------|---------------|------------------|
--|3 228       |3 228          |3 220             |

--city
SELECT 
    COUNT(*) as total_cities,
    COUNT(DISTINCT city_id) as unique_city_id,
    COUNT(DISTINCT city_name) as unique_city_names,
    COUNT(DISTINCT region_id) as regions_represented
FROM afisha.city;

--|total_cities|unique_city_id|unique_city_names|regions_represented|
--|------------|--------------|-----------------|-------------------|
--|353         |353           |352              |81                 |

--regions
SELECT 
    COUNT(*) as total_regions,
    COUNT(DISTINCT region_id) as unique_region_id,
    COUNT(DISTINCT region_name) as unique_region_names
FROM afisha.regions;

--|total_regions|unique_region_id|unique_region_names|
--|-------------|----------------|-------------------|
--|81           |81              |81                 |

--Анализ результатов по таблицам
--1. Таблица events
--22484 события - это соответствует количеству уникальных event_id из purchases, что отлично!
--15287 уникальных названий - значит, многие события имеют одинаковые названия (возможно, это сеансы одного фильма 
--или разные даты одного концерта).
--Всего 8 типов мероприятий - это идеально для анализа и визуализации в DataLens (не слишком много категорий).
--События проходят в 353 городах на 3228 площадках.
--
--2. Таблица venues
--3 228 площадок - полностью соответствует числу из events, значит, все площадки из events есть в справочнике.
--3 220 уникальных названий - есть 8 случаев, когда разные venue_id имеют одинаковые названия (возможно, филиалы одной сети).
--
--3. Таблица city
--353 города - полностью соответствует cities_with_events из events.
--352 уникальных названия - есть 1 случай, когда разные city_id имеют одинаковое название (возможно, города-тезки в разных регионах).
--Города распределены по 81 региону.
--
--4. Таблица regions
--81 регион - соответствует regions_represented из city.
--Все идентификаторы и названия уникальны.
--
--Ключевые выводы о качестве данных:
--Отличная целостность данных:
--Все event_id из purchases есть в events
--Все city_id из events есть в city
--Все venue_id из events есть в venues
--Все region_id из city есть в regions
--
--Нет дубликатов в первичных ключах
--Минимальное количество расхождений в названиях городов и площадок
--Удобная для анализа структура - всего 8 типов мероприятий, что идеально для дашборда

--Проверка качества данных
--Проверка на пропуски в ключевых полях таблицы purchases
SELECT 
    COUNT(*) - COUNT(order_id) as miss_order_id,
    COUNT(*) - COUNT(user_id) as miss_user_id,
    COUNT(*) - COUNT(event_id) as miss_event_id,
    COUNT(*) - COUNT(created_dt_msk) as miss_date,
    COUNT(*) - COUNT(device_type_canonical) as miss_device,
    COUNT(*) - COUNT(revenue) as miss_revenue,
    COUNT(*) - COUNT(total) as miss_total
FROM afisha.purchases;

--|miss_order_id|miss_user_id|miss_event_id|miss_date|miss_device|miss_revenue|miss_total|
--|-------------|------------|-------------|---------|-----------|------------|----------|
--|0            |0           |0            |0        |0          |0           |0         |

--Анализ финансовых полей (revenue и total)
SELECT 
    MIN(revenue) as min_revenue,
    MAX(revenue) as max_revenue,
    AVG(revenue) as avg_revenue,
    MIN(total) as min_total,
    MAX(total) as max_total,
    AVG(total) as avg_total,
    -- Посчитаем, сколько заказов с нулевой или отрицательной выручкой
    SUM(CASE WHEN revenue <= 0 THEN 1 ELSE 0 END) as non_positive_revenue_count,
    SUM(CASE WHEN total <= 0 THEN 1 ELSE 0 END) as non_positive_total_count
FROM afisha.purchases;

--|min_revenue|max_revenue|avg_revenue   |min_total|max_total|avg_total       |non_positive_revenue_count|non_positive_total_count|
--|-----------|-----------|--------------|---------|---------|----------------|--------------------------|------------------------|
--|-90,76     |81 174,54  |624,8337734043|-358,85  |811 745,4|7 524,0000497583|6 153                     |6 134                   |

--Изучение категориальных полей (для будущих срезов в DataLens)
-- Какие типы устройств используются?
SELECT device_type_canonical, COUNT(*) as count
FROM afisha.purchases
GROUP BY device_type_canonical
ORDER BY count DESC;

--|device_type_canonical|count  |
--|---------------------|-------|
--|mobile               |232 679|
--|desktop              |58 170 |
--|tablet               |1 180  |
--|tv                   |3      |
--|other                |2      |


-- Какие валюты? (Ожидаем в основном RUB)
SELECT currency_code, COUNT(*) as count
FROM afisha.purchases
GROUP BY currency_code
ORDER BY count DESC;

--|currency_code|count  |
--|-------------|-------|
--|rub          |286 961|
--|kzt          |5 073  |


-- Какие основные типы мероприятий? (Это нам очень пригодится)
SELECT event_type_main, COUNT(*) as event_count
FROM afisha.events
GROUP BY event_type_main
ORDER BY event_count DESC;

--|event_type_main|event_count|
--|---------------|-----------|
--|концерты       |8 699      |
--|театр          |7 090      |
--|другое         |4 662      |
--|спорт          |872        |
--|стендап        |636        |
--|выставки       |291        |
--|ёлки           |215        |
--|фильм          |19         |
--
--
--Анализ качества данных в таблице purchases
--1. Пропуски в данных:
--Идеально! Нет ни одного пропуска в ключевых полях. Это отличное качество данных для анализа.
--
--2. Финансовые показатели:
--Здесь есть несколько важных наблюдений:
--
--Средняя выручка (revenue): 624.83 руб.
--Средний чек (total): 7,524 руб.
--
--Разница в 12 раз между revenue и total - это нормально, так как revenue - это комиссия сервиса, 
--а total - полная стоимость заказа.
--
--Внимание на аномалии:
--
--6,153 заказов с неположительной выручкой (<= 0)
--
--6,134 заказов с неположительной общей суммой (<= 0)
--
--Отрицательные значения: min_revenue = -90.76, min_total = -358.85
--
--Это могут быть:
--
--Возвраты билетов
--
--Тестовые или ошибочные заказы
--
--Акционные предложения с нулевой стоимостью
--
--Рекомендация: При анализе нам нужно решить, включать ли эти записи в расчеты. Обычно для анализа продаж их исключают.
--
--3. Категориальные поля:
--Устройства:
--
--Mobile доминирует: 232,679 (79.7%) - пользователи в основном покупают с телефонов
--
--Desktop: 58,170 (19.9%)
--
--Tablet/TV/Other: незначительные доли (<1%)
--
--Валюты:
--
--RUB: 286,961 (98.3%) - основная валюта
--
--KZT: 5,073 (1.7%) - казахстанские тенге
--
--Типы мероприятий (очень важно!):
--
--Концерты: 8,699 (38.7%) - лидер
--
--Театр: 7,090 (31.5%) - второй по популярности
--
--Другое: 4,662 (20.7%)
--
--Спорт: 872 (3.9%)
--
--Стендап: 636 (2.8%)
--
--Выставки: 291 (1.3%)
--
--Ёлки: 215 (1.0%)
--
--Фильм: 19 (0.1%) - очень мало
--
--Итоги знакомства с данными
--Положительные стороны:
--
--Отличная целостность данных (все связи работают)
--
--Нет пропусков в ключевых полях
--
--Удобная для анализа структура (8 типов мероприятий)
--
--Четкое распределение по устройствам и валютам
--
--Данные за 5 месяцев (июнь-октябрь 2024) - можно анализировать сезонность
--
--Вопросы для дальнейшего анализа:
--
--Как обращаться с заказами с неположительной выручкой?
--
--Почему так мало фильмов в афише?
--
--Как менялась популярность типов мероприятий с лета на осень?

--4. "Среднее значение выручки от заказов, оплаченных в тенге, составляет 3446 тенге"
--Нам нужно выполнить запрос выше чтобы получить точное среднее для KZT
SELECT 
    currency_code,
    COUNT(*) as orders_count,
    ROUND(MIN(revenue)::numeric, 2) as min_revenue,
    ROUND(MAX(revenue)::numeric, 2) as max_revenue,
    ROUND(AVG(revenue)::numeric, 2) as avg_revenue,
    ROUND(STDDEV(revenue)::numeric, 2) as std_revenue,
    SUM(CASE WHEN revenue <= 0 THEN 1 ELSE 0 END) as non_positive_count
FROM afisha.purchases 
GROUP BY currency_code
ORDER BY orders_count DESC;

--|currency_code|orders_count|min_revenue|max_revenue|avg_revenue|std_revenue|non_positive_count|
--|-------------|------------|-----------|-----------|-----------|-----------|------------------|
--|rub          |286 961     |-90,76     |81 174,5   |547,57     |870,62     |6 147             |
--|kzt          |5 073       |0          |26 425,9   |4 995,31   |4 916,64   |6                 |

--Запрос: Анализ операторов (service_name)
SELECT 
    service_name,
    COUNT(*) as orders_count,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() as percent_total
FROM afisha.purchases 
GROUP BY service_name
ORDER BY orders_count DESC;

--|service_name          |orders_count|percent_total|
--|----------------------|------------|-------------|
--|Билеты без проблем    |63 932      |21,8919714828|
--|Лови билет!           |41 338      |14,1552011067|
--|Билеты в руки         |40 500      |13,8682482177|
--|Мой билет             |34 965      |11,9729209613|
--|Облачко               |26 730      |9,1530438237 |
--|Лучшие билеты         |17 872      |6,1198353616 |
--|Весь в билетах        |16 910      |5,7904216632 |
--|Прачечная             |10 385      |3,5560927837 |
--|Край билетов          |6 238       |2,1360526514 |
--|Тебе билет!           |5 242       |1,794996473  |
--|Яблоко                |5 057       |1,7316476849 |
--|Дом культуры          |4 514       |1,545710431  |
--|За билетом!           |2 877       |0,9851592623 |
--|Городской дом культуры|2 747       |0,9406438976 |
--|Show_ticket           |2 208       |0,7560763473 |
--|Мир касс              |2 171       |0,7434065896 |
--|Быстробилет           |2 010       |0,6882760227 |
--|Выступления.ру        |1 621       |0,5550723546 |
--|Восьмёрка             |1 126       |0,385571543  |
--|Crazy ticket!         |796         |0,272571002  |
--|Росбилет              |544         |0,1862796798 |
--|Шоу начинается!       |499         |0,1708705151 |
--|Быстрый кассир        |381         |0,130464261  |
--|Радио ticket          |380         |0,1301218351 |
--|Телебилет             |321         |0,1099187081 |
--|КарандашРУ            |133         |0,0455426423 |
--|Реестр                |130         |0,0445153646 |
--|Билет по телефону     |85          |0,0291062    |
--|Вперёд!               |81          |0,0277364964 |
--|Дырокол               |74          |0,0253395153 |
--|Кино билет            |67          |0,0229425341 |
--|Цвет и билет          |61          |0,0208879788 |
--|Тех билет             |22          |0,0075333694 |
--|Лимоны                |8           |0,0027394071 |
--|Зе Бест!              |5           |0,0017121294 |
--|Билеты в интернете    |4           |0,0013697035 |

--Запрос: Проверка неявных дубликатов в названиях операторов
SELECT 
    LOWER(TRIM(service_name)) as cleaned_name,
    COUNT(DISTINCT service_name) as original_names_count,
    STRING_AGG(DISTINCT service_name, ', ') as original_names
FROM afisha.purchases 
GROUP BY LOWER(TRIM(service_name))
HAVING COUNT(DISTINCT service_name) > 1;

--Таблица результата последнего запроса пуста, неявных дубликатов в названиях операторов не найдено.


