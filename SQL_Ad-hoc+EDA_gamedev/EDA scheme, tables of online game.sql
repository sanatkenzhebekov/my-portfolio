/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить:
 * какие таблицы представлены в схеме fantasy;
 * из каких полей состоят таблицы и какие данные в них хранятся;
 * какие существуют взаимосвязи между таблицами.
 * Автор: Кенжебеков Санат
 * Дата: 25.04.25
*/

-- Разведочный анализ данных
SELECT table_name
FROM information_schema.tables
WHERE table_schema='fantasy';

--|table_name|
--|----------|
--|classes   |
--|country   |
--|events    |
--|items     |
--|race      |
--|skills    |
--|users     |

WITH
users_stat AS (
    SELECT table_schema, table_name, column_name, data_type
    FROM information_schema.columns
    WHERE table_schema = 'fantasy' AND table_name = 'users'
),
keys_stat AS (
    SELECT table_schema, table_name, column_name, constraint_name
    FROM information_schema.key_column_usage
    WHERE table_schema = 'fantasy' AND table_name = 'users'
)
SELECT 
    us.table_schema, 
    us.table_name, 
    us.column_name, 
    us.data_type, 
    ks.constraint_name
FROM users_stat AS us
LEFT JOIN keys_stat AS ks 
  ON us.table_schema = ks.table_schema 
  AND us.table_name = ks.table_name 
  AND us.column_name = ks.column_name;

--| schema | table | column          | data_type        | constraint        |
--|--------|-------|-----------------|------------------|-------------------|
--| fantasy| users | id              | character varying| users_pkey        |
--| fantasy| users | tech_nickname   | character varying|                   |
--| fantasy| users | class_id        | character varying| users_class_id_fkey|
--| fantasy| users | ch_id           | character varying| users_ch_id_fkey  |
--| fantasy| users | birthdate       | character varying|                   |
--| fantasy| users | pers_gender     | character varying|                   |
--| fantasy| users | registration_dt | character varying|                   |
--| fantasy| users | server          | character varying|                   |
--| fantasy| users | race_id         | character varying| users_race_id_fkey|
--| fantasy| users | payer           | integer          |                   |
--| fantasy| users | loc_id          | character varying| users_loc_id_fkey |

--Познакомимся с данными таблицы users
SELECT *, COUNT(*) OVER() AS row_count
FROM fantasy.users
LIMIT 5;

--| id         | tech_nickname       | class_id | ch_id | birthdate | pers_gender | registration_dt | server   | race_id | payer | loc_id | row_count |
--|------------|---------------------|----------|-------|-----------|-------------|-----------------|----------|---------|-------|--------|-----------|
--| 00-0037846 | DivineBarbarian4154 | 9RD      | JJR2  | 6/4/1994  | Male        | 1/20/2005       | server_1 | B1      | 0     | US     | 22214     |
--| 00-0041533 | BoldInvoker7693     | Z3Q      | HQ9N  | 6/29/1987 | Male        | 4/8/2022        | server_1 | R2      | 0     | US     | 22214     |
--| 00-0045747 | NobleAlchemist7633  | 382      | IXBW  | 7/29/1992 | Male        | 10/12/2013      | server_1 | K3      | 0     | US     | 22214     |
--| 00-0055274 | SteadfastArcher8318 | ZD0      | QSUB  | 9/14/1985 | Female      | 4/10/2008       | server_1 | R2      | 0     | US     | 22214     |
--| 00-0076100 | RadiantProphet353   | YC8      | HQ9N  | 4/11/1997 | Female      | 9/29/2013       | server_2 | K4      | 1     | US     | 22214     |

--Проверка пропусков в таблице users
SELECT COUNT(*)
FROM fantasy.users
WHERE class_id IS NULL
   OR ch_id IS NULL
   OR pers_gender IS NULL
   OR server IS NULL
   OR race_id IS NULL
   OR payer IS NULL
   OR loc_id IS NULL;

--|count|
--|0    |

SELECT server, COUNT(server) AS count_users_on_server
FROM fantasy.users
GROUP BY server
ORDER BY server;

--|server	|count_users_on_server|
--|---------|---------------------|
--|server_1	| 16715               |
--|server_2	|5499                 |

-- Выводим названия полей, их тип данных и метку о ключевом поле таблицы events
SELECT c.table_schema,
       c.table_name,
       c.column_name,
       c.data_type,
       k.constraint_name
FROM information_schema.columns AS c 
-- Присоединяем данные с ограничениями полей
LEFT JOIN information_schema.key_column_usage AS k 
    USING(table_name, column_name, table_schema)
-- Фильтруем результат по названию схемы и таблицы
WHERE table_schema = 'fantasy' AND table_name = 'events'
ORDER BY c.table_name;

-- | schema | table  | column        | data_type        | constraint          |
-- |--------|--------|---------------|------------------|---------------------|
-- | fantasy| events | transaction_id| character varying| events_pkey         |
-- | fantasy| events | id            | character varying| events_id_fkey      |
-- | fantasy| events | date          | character varying|                     |
-- | fantasy| events | time          | character varying|                     |
-- | fantasy| events | item_code     | integer          | events_item_code_fkey|
-- | fantasy| events | amount        | real             |                     |
-- | fantasy| events | seller_id     | character varying|                     |

--Познакомимся с данными таблицы events
SELECT *, COUNT(*) OVER() AS row_count
FROM fantasy.events
LIMIT 5;

-- | transaction_id | id         | date       | time     | item_code | amount | seller_id | row_count |
-- |----------------|------------|------------|----------|-----------|--------|-----------|-----------|
-- | 2129235853     | 37-5938126 | 2021-01-03 | 16:31:49 | 6010      | 21.41  | 220381    | 1307678   |
-- | 2129237617     | 37-5938126 | 2021-01-03 | 16:49:00 | 6010      | 64.98  | 54680     | 1307678   |
-- | 2129239381     | 37-5938126 | 2021-01-03 | 21:05:29 | 6010      | 50.68  | 888909    | 1307678   |
-- | 2129241145     | 37-5938126 | 2021-01-03 | 22:03:02 | 6010      | 46.49  | 888902    | 1307678   |
-- | 2129242909     | 37-5938126 | 2021-01-03 | 22:04:26 | 6010      | 18.72  | 888905    | 1307678   |

--Проверка пропусков в таблице events
SELECT COUNT(*)
FROM fantasy.events
WHERE
date IS NULL
OR time IS NULL
OR amount IS NULL
OR seller_id IS NULL;

-- |count |
-- |508186|

--Изучаем пропуски в таблице events
-- Считаем количество строк с данными в каждом поле
SELECT 
COUNT(date) AS data_count,
COUNT(time) AS data_time,
COUNT(amount) AS data_amount,
COUNT(seller_id) AS data_seller_id
FROM fantasy.events
WHERE date IS NULL
  OR time IS NULL
  OR amount IS NULL
  OR seller_id IS NULL;

-- | data_count | data_time | data_amount | data_seller_id |
-- |------------|-----------|-------------|----------------|
-- | 508186     | 508186    | 508186      | 0              |

-- Все 508186 пропусков содержатся только в поле seller_id, то есть в данных нет информации о продавце. 
-- Видимо, в таком случае покупка совершалась в игровом магазине, а не у других продавцов.
