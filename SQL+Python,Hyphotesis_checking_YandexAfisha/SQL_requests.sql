/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Кенжебеков Санат, da_123
 * Дата: 25.04.25
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:

SELECT total_users, paying_users,
	   paying_users::float/total_users AS paying_users_share
FROM (SELECT COUNT(id) AS total_users,
	  COUNT(id) FILTER(WHERE payer=1) AS paying_users
	  FROM fantasy.users) AS paying_users_stat;

--|total_users|paying_users|paying_users_share|
--|-----------|------------|------------------|
--|22 214     |3 929       |0,1768704421      |
--Доля платящих игроков по всем данным составляет 17,7% от общего кол-ва игроков

-- 1.2. Доля платящих пользователей в разрезе расы персонажа:

SELECT race, 
	   COUNT(id) AS total_users,
	   COUNT(id) FILTER(WHERE payer=1) AS paying_users,
	   ROUND(COUNT(id) FILTER(WHERE payer=1)::numeric/COUNT(id), 4) AS paying_users_share
FROM fantasy.users u
JOIN fantasy.race r ON u.race_id=r.race_id
GROUP BY race;

--|race    |total_users|paying_users|paying_users_share|
--|--------|-----------|------------|------------------|
--|Angel   |1 327      |229         |0,1726            |
--|Elf     |2 501      |427         |0,1707            |
--|Demon   |1 229      |238         |0,1937            |
--|Orc     |3 619      |636         |0,1757            |
--|Human   |6 328      |1 114       |0,176             |
--|Northman|3 562      |626         |0,1757            |
--|Hobbit  |3 648      |659         |0,1806            |
-- В разрезе расы персонажа доля платящих игроков колеблется от 17,1% до 19,4%.
-- При этом максимальная доля платящих игроков 19,4% персонажей расы "Demon",
-- а минимальная доля платящих игроков 17,1% персонажей расы "Elf".
-- Незнаю насколько это разница сильная, как по мне разница небольшая, и 
-- корреляции доли платящих игроков в зависимости от расы персонажа я не вижу.
-- Мое мнение, всем персонажам разных рас игровой сюжет построен одинаково сложно,
-- и для прохождения игры пятая часть игроков покупают игровую валюту.


-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:

SELECT COUNT(*) AS purchase_count,
	   SUM(amount) AS purchase_sum,
	   MAX(amount) AS max_purchase,
	   MIN(amount) AS min_purchase,
	   ROUND(AVG(amount)::numeric, 2) AS avg_purchase,
	   PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY amount) AS median_purchase,
	   ROUND(STDDEV(amount)::numeric, 2) AS stddev_purchase
FROM fantasy.events; 

--|purchase_count|purchase_sum|max_purchase|min_purchase|avg_purchase|median_purchase|stddev_purchase|
--|--------------|------------|------------|------------|------------|---------------|---------------|
--|1 307 678     |686 615 040 |486 615,1   |0           |525,69      |74,86          |2 517,35       |
-- Общее кол-во покупок 1 307 678, сумма всех покупок составляет 686 615 040 рублей или долларов незнаю, но сумма внушительная.
-- Максимальная покупка составляет 486 615.1, а минимальная покупка равна нулю. Надо выяснить какое количество нулевых покупок,
-- и какую долю от общего количества они занимают.
-- Средняя покупка составляет 525.69, Медиана покупок равна 74.86, стандартное отклонение составляет 2517.35.  

-- 2.2: Аномальные нулевые покупки:
SELECT	   
       COUNT(*) AS purchase_count,
	   COUNT(*) FILTER(WHERE amount=0) AS zero_purchase,
	   ROUND(COUNT(*) FILTER(WHERE amount=0)::numeric/COUNT(*), 4) AS zero_purchase_share
FROM fantasy.events;

--|purchase_count|zero_purchase|zero_purchase_share|
--|--------------|-------------|-------------------|
--|1 307 678     |907          |0,0007             |
-- Нулевые покупки составляют 0.07% доли от общего кол-ва покупок. Т.к. они не помогают зарабатывать команде разработки
-- следует исключить их из анализа.

-- 2.3: Сравнительный анализ активности платящих и неплатящих игроков:
WITH user_stats AS (
    SELECT 
        u.payer,
        e.id,
        COUNT(e.transaction_id) AS purchase_count,
        SUM(e.amount) AS total_purchase
    FROM fantasy.events e
    JOIN fantasy.users u ON e.id = u.id
    WHERE e.amount > 0  -- Исключаем покупки с нулевой стоимостью
    GROUP BY u.payer, e.id
)
SELECT 
    payer,
    COUNT(id) AS total_users,
    ROUND(AVG(purchase_count)::numeric, 2) AS avg_purchase_count,
    ROUND(AVG(total_purchase)::numeric, 2) AS avg_total_purchase
FROM user_stats
GROUP BY payer
ORDER BY payer;

--|payer|total_users|avg_purchase_count|avg_total_purchase|
--|-----|-----------|------------------|------------------|
--|0    |11 348     |97,56             |48 631,74         |
--|1    |2 444      |81,68             |55 467,74         |
--Платящих игроков 2 444, неплатящих - 11 348. Платящие игроки в среднем меньше покупают 
--(81,68 заказов у платящих, против 97,56 заказов у неплатящих), однако тратят больше при этом 
--(средник чек покупки 55 467,74 у платящих, против 48 631,74 у неплатящих).


-- 2.4: Популярные эпические предметы:
WITH item_sales AS (
    SELECT
        e.item_code,
        i.game_items,
        COUNT(*) AS total_sales,
        COUNT(DISTINCT e.id) AS unique_buyers
    FROM fantasy.events e
    JOIN fantasy.items i ON e.item_code = i.item_code
    WHERE e.amount > 0  -- исключаем покупки с amount = 0
    GROUP BY e.item_code, i.game_items
),
overall_stats AS (
    SELECT 
        COUNT(*) AS all_sales,
        COUNT(DISTINCT id) AS all_buyers
    FROM fantasy.events
    WHERE amount > 0
)
SELECT 
    isales.item_code,
    isales.game_items,
    isales.total_sales,
    ROUND(isales.total_sales::numeric / ostats.all_sales, 4) AS sales_share,
    ROUND(isales.unique_buyers::numeric / ostats.all_buyers, 4) AS player_share
FROM item_sales isales
CROSS JOIN overall_stats ostats
ORDER BY player_share DESC;

--|item_code|game_items               |total_sales|sales_share|player_share|
--|---------|-------------------------|-----------|-----------|------------|
--|6 010    |Book of Legends          |1 004 516  |0,7687     |0,8841      |
--|6 011    |Bag of Holding           |271 875    |0,2081     |0,8677      |
--|6 012    |Necklace of Wisdom       |13 828     |0,0106     |0,118       |
--|6 536    |Gems of Insight          |3 833      |0,0029     |0,0671      |
--|5 964    |Treasure Map             |3 084      |0,0024     |0,0546      |
--|5 411    |Silver Flask             |795        |0,0006     |0,0459      |
--|4 112    |Amulet of Protection     |1 078      |0,0008     |0,0323      |
--|5 541    |Glowing Pendant          |563        |0,0004     |0,0257      |
--|5 691    |Strength Elixir          |580        |0,0004     |0,024       |
--|5 661    |Ring of Wisdom           |379        |0,0003     |0,0225      |
--|5 999    |Gauntlets of Might       |514        |0,0004     |0,0204      |
--|5 261    |Potion of Speed          |375        |0,0003     |0,0167      |
--|5 211    |Ring of Invisibility     |252        |0,0002     |0,0133      |
--|5 732    |Potion of Acceleration   |230        |0,0002     |0,0131      |
--|5 651    |Feather of Writing       |222        |0,0002     |0,0112      |
--|4 511    |Herbs for Potions        |241        |0,0002     |0,0107      |
--|5 941    |Time Artifact            |168        |0,0001     |0,0107      |
--|5 722    |Monster Compendium       |151        |0,0001     |0,01        |
--|5 641    |Water of Life            |142        |0,0001     |0,0088      |
--|5 533    |Trap Chest               |137        |0,0001     |0,0087      |
--|5 331    |Scroll of Magic          |162        |0,0001     |0,0085      |
--|5 699    |Magic Ornament           |282        |0,0002     |0,0082      |
--|4 829    |Magical Lantern          |247        |0,0002     |0,0074      |
--|5 311    |Enemy Traps              |168        |0,0001     |0,0068      |
--|5 621    |Magic Key                |127        |0,0001     |0,0059      |
--|4 812    |Robe of the Magi         |85         |0,0001     |0,0058      |
--|5 712    |Dungeon Map              |108        |0,0001     |0,0054      |
--|4 722    |Runes of Power           |106        |0,0001     |0,0053      |
--|3 000    |Treasure Map             |99         |0,0001     |0,0053      |
--|5 945    |Magic Dust               |82         |0,0001     |0,0052      |
--|8 999    |Druid's Staff            |83         |0,0001     |0,0044      |
--|7 995    |Sea Serpent Scale        |458        |0,0004     |0,0043      |
--|5 200    |Boots of Levitation      |73         |0,0001     |0,004       |
--|7 311    |Chimera Scale            |67         |0,0001     |0,004       |
--|5 735    |Mystic Compass           |83         |0,0001     |0,0039      |
--|5 499    |Antidote Potion          |89         |0,0001     |0,0034      |
--|5 655    |Potion of Intelligence   |50         |0          |0,0034      |
--|5 309    |Treasure Box             |79         |0,0001     |0,0033      |
--|5 399    |Enhanced Weapon          |60         |0          |0,003       |
--|6 051    |Orb of Time              |56         |0          |0,0028      |
--|7 832    |Elf Ears                 |44         |0          |0,0028      |
--|5 812    |Scroll of Summoning      |49         |0          |0,0027      |
--|7 922    |Orc Tusk                 |45         |0          |0,0025      |
--|4 814    |Helm of Insight          |57         |0          |0,0023      |
--|4 121    |Shield of Valor          |38         |0          |0,002       |
--|7 011    |Potion of Fortitude      |31         |0          |0,002       |
--|7 399    |Pegasus Feather          |138        |0,0001     |0,0019      |
--|7 999    |Succubus Kiss            |35         |0          |0,0018      |
--|5 734    |Transformation Potion    |26         |0          |0,0017      |
--|4 816    |Boots of Swiftness       |29         |0          |0,0017      |
--|5 942    |Potion of Transformation |28         |0          |0,0016      |
--|5 977    |Pendant of Healing       |25         |0          |0,0016      |
--|5 251    |Armor of Magic Resistance|21         |0          |0,0015      |
--|5 511    |Scroll of Resurrection   |27         |0          |0,0015      |
--|8 099    |Enchanter's Amulet       |19         |0          |0,0014      |
--|6 211    |Phoenix Feather          |56         |0          |0,0014      |
--|5 814    |Mirror of Divination     |21         |0          |0,0014      |
--|5 912    |Medallion of Magic       |24         |0          |0,0014      |
--|5 983    |Quiver of Endless Arrows |45         |0          |0,0014      |
--|5 948    |Nature's Strength Potion |20         |0          |0,0013      |
--|5 995    |Crown of Kings           |18         |0          |0,0013      |
--|5 611    |Potion of Regeneration   |20         |0          |0,0012      |
--|4 900    |Cloak of Shadows         |15         |0          |0,0011      |
--|5 631    |Fire Resistance Potion   |22         |0          |0,0011      |
--|5 300    |Shield of Protection     |14         |0          |0,001       |
--|7 512    |Fairy Dust               |21         |0          |0,0009      |
--|4 789    |Dragon Cart              |15         |0          |0,0008      |
--|7 994    |Kraken Ink               |13         |0          |0,0008      |
--|5 681    |Stone of Power           |12         |0          |0,0008      |
--|5 944    |Potion of Light          |13         |0          |0,0008      |
--|5 813    |Invisibility Potion      |12         |0          |0,0007      |
--|5 719    |Magic Animal             |11         |0          |0,0007      |
--|7 372    |Hydra Tooth              |10         |0          |0,0007      |
--|5 921    |Potion of Wisdom         |9          |0          |0,0006      |
--|7 538    |Vampire Fang             |10         |0          |0,0006      |
--|5 231    |Staff of Flames          |9          |0          |0,0006      |
--|4 899    |Defender's Guard         |10         |0          |0,0005      |
--|5 946    |Potion of Darkness       |8          |0          |0,0005      |
--|5 013    |Silver Talons            |5          |0          |0,0004      |
--|4 111    |Book of Spells           |6          |0          |0,0004      |
--|5 970    |Book of Curses           |6          |0          |0,0004      |
--|5 542    |Protective Cloak         |9          |0          |0,0004      |
--|5 968    |Mystic Bracelets         |6          |0          |0,0004      |
--|7 299    |Wyvern Claw              |11         |0          |0,0004      |
--|3 501    |Traveler's Supplies      |10         |0          |0,0004      |
--|3 351    |Ethereal Horse           |7          |0          |0,0004      |
--|5 094    |Luminescent Gem          |6          |0          |0,0004      |
--|8 043    |Sorcerer's Stone         |5          |0          |0,0004      |
--|5 947    |Amulet of Time           |6          |0          |0,0004      |
--|5 950    |Potion of Clarity        |5          |0          |0,0003      |
--|4 784    |Ancient Artifact         |8          |0          |0,0003      |
--|5 039    |Gold Coins               |4          |0          |0,0003      |
--|5 045    |Healer's Kit             |4          |0          |0,0003      |
--|5 532    |Shovel of Secrets        |5          |0          |0,0003      |
--|5 713    |Weapon Oil               |7          |0          |0,0003      |
--|5 943    |Weapon Decoration        |5          |0          |0,0003      |
--|5 949    |Magic Orb                |4          |0          |0,0003      |
--|5 965    |Wand of Lightning        |4          |0          |0,0003      |
--|7 273    |Unicorn Horn             |8          |0          |0,0003      |
--|7 298    |Griffin Feather          |6          |0          |0,0003      |
--|8 641    |Prophet's Scroll         |4          |0          |0,0003      |
--|5 969    |Flask of Endless Water   |3          |0          |0,0002      |
--|5 422    |Ring of Regeneration     |3          |0          |0,0002      |
--|5 065    |Crystal of Wisdom        |4          |0          |0,0002      |
--|4 131    |Ring of Strength         |4          |0          |0,0002      |
--|8 299    |Diviner's Tarot Deck     |4          |0          |0,0002      |
--|5 992    |Boots of Haste           |3          |0          |0,0002      |
--|5 599    |Book of Rituals          |2          |0          |0,0001      |
--|6 300    |Magic Carpet             |1          |0          |0,0001      |
--|6 513    |Spectral Shield          |1          |0          |0,0001      |
--|5 571    |Magic Sand               |5          |0          |0,0001      |
--|5 441    |Bow of Magic             |1          |0          |0,0001      |
--|7 210    |Elixir of Night Vision   |1          |0          |0,0001      |
--|7 230    |Dragon Scale             |1          |0          |0,0001      |
--|9 222    |Monk's Prayer Beads      |1          |0          |0,0001      |
--|9 311    |Knight's Shield          |2          |0          |0,0001      |
--|5 310    |Boots of Silence         |1          |0          |0,0001      |
--|5 199    |Gloves of Strength       |1          |0          |0,0001      |
--|7 375    |Mermaid's Tear           |1          |0          |0,0001      |
--|7 395    |Minotaur Horn            |1          |0          |0,0001      |
--|5 192    |Compass of Truth         |3          |0          |0,0001      |
--|5 169    |Talisman of Luck         |4          |0          |0,0001      |
--|5 099    |Cloak of Invisibility    |2          |0          |0,0001      |
--|7 542    |Werewolf Fur             |1          |0          |0,0001      |
--|7 699    |Demon's Horn             |1          |0          |0,0001      |
--|5 085    |Stone of Teleportation   |1          |0          |0,0001      |
--|5 074    |Quill of Enchantment     |3          |0          |0,0001      |
--|7 993    |Medusa's Snake           |2          |0          |0,0001      |
--|5 072    |Map of Realms            |1          |0          |0,0001      |
--|7 997    |Manticore Tail           |2          |0          |0,0001      |
--|5 047    |Bandages of Recovery     |2          |0          |0,0001      |
--|8 011    |Incubus Whisper          |1          |0          |0,0001      |
--|4 215    |Bow of Precision         |1          |0          |0,0001      |
--|8 062    |Warlock's Grimoire       |2          |0          |0,0001      |
--|8 071    |Necromancer's Wand       |2          |0          |0,0001      |
--|9 399    |Paladin's Hammer         |2          |0          |0,0001      |
--|2 741    |Elixir of Mana           |1          |0          |0,0001      |
--|5 976    |Scroll of Fireball       |1          |0          |0,0001      |
--|5 971    |Sword of Ice             |1          |0          |0,0001      |
--|8 398    |Mystic's Rune Stones     |2          |0          |0,0001      |
--|1 711    |Mystic Armor             |1          |0          |0,0001      |
--|5 940    |Cleansing Potion         |3          |0          |0,0001      |
--|5 816    |Potion of Power          |1          |0          |0,0001      |
--|5 811    |Sword of Flames          |1          |0          |0,0001      |
--|5 714    |Protection Potion        |2          |0          |0,0001      |
--Самые покупаемые эпические предметы: 
--1) Book of Legend - 1 004 516 покупок; 76,87 % доля от всех покупок; доля игроков, которые хотя бы один раз покупали этот предмет составляет 88,4%; 
--2) Bag of Holding - 271 875 покупок; 20,81 % от всех покупок; доля игроков, которые хотя бы один раз покупали этот предмет составляет 86,7%; 
--3) Necklace of Wisdom - 13 828 покупок; 1,06 % от всех покупок; доля игроков, которые хотя бы один раз покупали этот предмет составляет 11,8%. 
--Остальные предметы покупают редко в отношении общего количества покупок (менее 1%). 
 

-- Часть 2. Решение ad hoc-задач
-- Задача 1. Зависимость активности игроков от расы персонажа:

WITH registered_users AS (
    SELECT
        u.race_id,
        r.race,
        COUNT(u.id) AS total_users
    FROM fantasy.users u
    JOIN fantasy.race r ON u.race_id = r.race_id
    GROUP BY u.race_id, r.race
),
all_buyers AS (
    SELECT
        u.race_id,
        COUNT(DISTINCT e.id) AS all_buyers
    FROM fantasy.events e
    JOIN fantasy.users u ON e.id = u.id
    WHERE e.amount > 0
    GROUP BY u.race_id
),
paying_buyers AS (
    SELECT
        u.race_id,
        COUNT(DISTINCT e.id) AS paying_users
    FROM fantasy.events e
    JOIN fantasy.users u ON e.id = u.id
    WHERE e.amount > 0 AND u.payer = 1
    GROUP BY u.race_id
),
purchase_stats AS (
    SELECT
        u.race_id,
        COUNT(*) AS total_purchases,
        SUM(e.amount) AS total_amount
    FROM fantasy.events e
    JOIN fantasy.users u ON e.id = u.id
    WHERE e.amount > 0
    GROUP BY u.race_id
)
SELECT
    ru.race,
    ru.total_users,
    COALESCE(ab.all_buyers, 0) AS all_buyers,
    COALESCE(pb.paying_users, 0) AS paying_users,
    ROUND(COALESCE(pb.paying_users, 0)::numeric / ru.total_users, 4) AS paying_users_share,
    ROUND(COALESCE(pb.paying_users, 0)::numeric / NULLIF(ab.all_buyers, 0), 4) AS paying_to_buyers_share,
    ROUND(COALESCE(ps.total_purchases, 0)::numeric / ru.total_users, 2) AS avg_purchases_per_user,
    ROUND(COALESCE(ps.total_amount, 0)::numeric / NULLIF(ps.total_purchases, 0), 2) AS avg_purchase_amount,
    ROUND(COALESCE(ps.total_amount, 0)::numeric / ru.total_users, 2) AS avg_total_amount_per_user
FROM registered_users ru
LEFT JOIN all_buyers ab ON ru.race_id = ab.race_id
LEFT JOIN paying_buyers pb ON ru.race_id = pb.race_id
LEFT JOIN purchase_stats ps ON ru.race_id = ps.race_id
ORDER BY ru.race;

--|race    |total_users|all_buyers|paying_users|paying_users_share|paying_to_buyers_share|avg_purchases_per_user|avg_purchase_amount|avg_total_amount_per_user|
--|--------|-----------|----------|------------|------------------|----------------------|----------------------|-------------------|-------------------------|
--|Angel   |1 327      |820       |137         |0,1032            |0,1671                |66                    |455,64             |30 071,59                |
--|Demon   |1 229      |737       |147         |0,1196            |0,1995                |46,7                  |529,02             |24 703,25                |
--|Elf     |2 501      |1 543     |251         |0,1004            |0,1627                |48,61                 |682,33             |33 168,17                |
--|Hobbit  |3 648      |2 266     |401         |0,1099            |0,177                 |53,5                  |552,91             |29 580,87                |
--|Human   |6 328      |3 921     |706         |0,1116            |0,1801                |75,22                 |403,07             |30 320,64                |
--|Northman|3 562      |2 229     |406         |0,114             |0,1821                |51,38                 |761,48             |39 122,68                |
--|Orc     |3 619      |2 276     |396         |0,1094            |0,174                 |51,41                 |510,92             |26 264,05                |
--Из общего количества зарегистрированных игроков, в среднем около 60% покупают эпические предметы для прохождения, 
--вне зависимости от расы, т.к. сильной разницы нет.
--Доля платящих игроков от покупателей в разрезе расы: колеблется от 16% до 20%, при этом максимальной долей обладает раса Demon 19,95%,
--минимальной долей обладает раса Elf 16,27%. 
--Чаще всего покупают игроки рас Angel(66 покупок на игрока в среднем) и Human(75 покупок на игрока), 
--но у этих рас самые низкий средний чек покупок 455 и 403 рублей соответственно. Вывод: их предметы стоят дешевле, 
--но приходится покупать их чаще для прохождения игры.
--Самыми высокими средними чеками обладают расы Northman (761 руб) и Elf (682 руб), 
--при среднем количестве покупок на игрока около 50(что находится у нижней границы. 
--Значит эти расы покупают реже, но дороже эпические предметы. 
--Также эти расы лидеры по средней выручке на игрока Northman (39 112 руб) и  Elf (33 168 руб). 
--Самым анти-лидером является раса Demon при самой низкой выручке на игрока 24 703 руб., 
--самом низком количестве покупок на игрока 46.7 шт., и самым малым количеством платящих игроков 737 человек 
--(против макс.кол-ва платящих игроков Human 3921 человек).

--Итого: подтверждается ли гипотеза, что прохождение игры за персонажей разных рас 
--требует примерно равного количества покупок эпических предметов - нет, не подтверждается. 

-- Задача 2: Частота покупок
WITH purchase_dates AS (
    SELECT 
        e.id,
        e.date::date AS purchase_date,
        LAG(e.date::date) OVER (PARTITION BY e.id ORDER BY e.date::date) AS prev_purchase_date
    FROM fantasy.events e
    WHERE e.amount > 0
),
days_between AS (
    SELECT 
        id,
        (purchase_date - prev_purchase_date) AS days_between
    FROM purchase_dates
    WHERE prev_purchase_date IS NOT NULL
),
purchase_counts AS (
    SELECT 
        e.id,
        COUNT(*) AS purchase_count -- считаем количество покупок
    FROM fantasy.events e
    WHERE e.amount > 0
    GROUP BY e.id
),
avg_days_between AS (
    SELECT 
        id,
        AVG(days_between) AS avg_days_between -- считаем среднюю разницу дней
    FROM days_between
    GROUP BY id
),
player_stats AS (
    SELECT
        pc.id,
        pc.purchase_count,
        adb.avg_days_between,
        u.payer
    FROM purchase_counts pc
    LEFT JOIN avg_days_between adb ON pc.id = adb.id
    JOIN fantasy.users u ON pc.id = u.id
),
active_players AS (
    SELECT *
    FROM player_stats
    WHERE purchase_count >= 25
),
players_with_group AS (
    SELECT *,
        NTILE(3) OVER (ORDER BY avg_days_between) AS frequency_group
    FROM active_players
),
group_labels AS (
    SELECT
        id,
        purchase_count,
        avg_days_between,
        payer,
        CASE frequency_group
            WHEN 1 THEN 'высокая частота'
            WHEN 2 THEN 'умеренная частота'
            WHEN 3 THEN 'низкая частота'
        END AS frequency_label
    FROM players_with_group
)
SELECT
    frequency_label,
    COUNT(id) AS players_count,
    SUM(payer) AS paying_players_count,
    ROUND(SUM(payer)::numeric / COUNT(id), 4) AS paying_players_share,
    ROUND(AVG(purchase_count), 2) AS avg_purchases_per_player,
    ROUND(AVG(avg_days_between), 2) AS avg_days_between_purchases
FROM group_labels
GROUP BY frequency_label
ORDER BY
    CASE frequency_label
        WHEN 'высокая частота' THEN 1
        WHEN 'умеренная частота' THEN 2
        WHEN 'низкая частота' THEN 3
    END;
--|frequency_label  |players_count|paying_players_count|paying_players_share|avg_purchases_per_player|avg_days_between_purchases|
--|-----------------|-------------|--------------------|--------------------|------------------------|--------------------------|
--|высокая частота  |2 572        |473                 |0,1839              |390,66                  |3,29                      |
--|умеренная частота|2 572        |450                 |0,175               |58,81                   |7,54                      |
--|низкая частота   |2 572        |434                 |0,1687              |33,64                   |13,29                     |
--Игроки делятся на три группы: высокая, умеренная и низкая частота покупок.
--Интервал между покупками: 3 дня, 7 дней и 13 дней соответственно.
--Доля платящих игроков примерно одинакова, с небольшим преимуществом у игроков с высокой частотой(18,4%).
--Игроки с высокой частотой — самая активная и ценная аудитория. Для их удержания можно внедрить 
--бонусы за активность или статусы VIP-игроков.
--Игроков с низкой частотой стоит стимулировать через специальные предложения или акционные кампании 
--для увеличения вовлечённости в покупки.

