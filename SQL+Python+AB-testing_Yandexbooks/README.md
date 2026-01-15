# Проект: Яндекс-книги расчет метрик, проверка гипотез, A/B тест

## Цель проекта 

Цель проекта: Комплексный анализ пользовательского поведения в сервисе Яндекс Книги — от расчёта ключевых метрик с помощью SQL до проверки статистических гипотез на Python — с последующим оформлением выводов в аналитической записке.  

## Структура проекта
   1. Расчет метрик в SQL:
      - Расчёт MAU авторов;
      - Расчёт MAU произведений;
      - Расчёт Retention Rate;
      - Расчёт LTV;
      - Расчёт средней выручки прослушанного часа — аналог среднего чека.
    
   2. Проверка гипотезы в Python и составление аналитической записки
      <font color='#777778'>Цель проекта - проверить гипотезу: пользователи из Санкт-Петербурга проводят в среднем больше
времени за чтением и прослушиванием книг в приложении, чем пользователи из Москвы.

Задачи проекта: рассчитать параметры теста, оценить корректность его проведения и
проанализировать результаты эксперимента.</font>


## Описание данных

Проект анализирует пользовательскую активность в сервисе Яндекс Книги за период **с 1 сентября по 11 декабря 2024 года**.

## Таблица `bookmate.audition`
| Поле | Тип | Описание |
|------|-----|----------|
| `audition_id` | int | Уникальный ID сессии |
| `puid` | int | ID пользователя |
| `usage_platform_ru` | string | Платформа (iOS/Android/Web) |
| `msk_business_dt_str` | string | Дата события (МСК) |
| `app_version` | string | Версия приложения |
| `adult_content_flg` | bool | Контент 18+ (True/False) |
| `hours` | float | Длительность сессии (часы) |
| `hours_sessions_long` | float | Длительность длинных сессий (часы) |
| `kids_content_flg` | bool | Детский контент (True/False) |
| `main_content_id` | int | ID контента |
| `usage_geo_id` | int | ID местоположения |

## Таблица `bookmate.content`
| Поле | Тип | Описание |
|------|-----|----------|
| `main_content_id` | int | ID контента |
| `main_author_id` | int | ID автора |
| `main_content_type` | string | Тип контента |
| `main_content_name` | string | Название контента |
| `main_content_duration_hours` | float | Длительность контента (часы) |
| `published_topic_title_list` | string | Жанры (список через запятую) |

## Таблица `bookmate.author`
| Поле | Тип | Описание |
|------|-----|----------|
| `main_author_id` | int | ID автора |
| `main_author_name` | string | Имя автора |

## Таблица `bookmate.geo`
| Поле | Тип | Описание |
|------|-----|----------|
| `usage_geo_id` | int | ID местоположения |
| `usage_geo_id_name` | string | Город/регион |
| `usage_country_name` | string | Страна |

---

## Используемый стек
- **Python** (Pandas, Matplotlib, Numpy, Scipy, proportions_ztest, ttest_ind, proportion_effectsize, NormalIndPower, ceil)
- **Jupyter Notebook**
- **EDA**
- **A/B-testing**

## Статус проекта
✅ Завершен

---

## Инструкция по запуску
Jupiter Notebook 7 версии и выше
**Импорт библиотек** 
- import pandas as pd
- import matplotlib.pyplot as plt
- import numpy as np
- from scipy import stats as st
- from scipy.stats import ttest_ind
- from scipy.stats import mannwhitneyu
- import matplotlib.pyplot as plt
- from statsmodels.stats.proportion import proportions_ztest

---


