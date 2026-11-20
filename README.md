# Ethiopia Food Prices Analysis (SQL)

> I did a SQL analysis of 66,125 food price observations from the World Food Programme (WFP) for Ethiopia, 2000-2026: how fast prices have risen, which foods and regions are most expensive, and how reliable the data is.

## Key Findings

| Question | Finding |
|---|---|
| How much has white maize risen since 2020? | Retail price rose from **12.58 to 47.28 birr per kg** (2020 to 2025), about **+276%** |
| Which foods rose fastest (2020 to 2025)? | **Coffee +562%**, **Barley +517%**, Pasta +339%, Chickpeas +329%, Wheat +325% |
| Which rose slowest? | Bananas +151%, Tomatoes +159%, Kale +184% |
| Do regions differ? | In 2025, white maize cost **40.70 birr/kg in Gambela** and **57.58 in Somali**, about **41% higher** |
| How big is the retail markup? | Retail white maize was about **19% above wholesale** in the same market and month (225 matched pairs, 10 markets, 2006-2021) |
| Biggest monthly jumps? | White maize rose **18.5% in June 2021** (16.21 to 19.21 birr/kg), then 15.4% in July 2021 and 15.2% in September 2024 |

All prices are nominal (in birr), so they include inflation and the weaker birr.

## Data

- **Source:** WFP food prices for Ethiopia (Humanitarian Data Exchange)
- **Size:** 66,125 rows, 16 columns, 129 markets, 96 commodities, January 2000 to September 2026
- **Tool:** MySQL 8.0

## What the SQL covers

- Data quality checks (row counts, duplicates, mixed units)
- A cleaning **view** (`food_clean`) that puts all prices on a per-kg basis
- Aggregations with `GROUP BY` and `HAVING`
- Conditional aggregation with `CASE WHEN`
- **Self-joins** to match retail and wholesale prices in the same market and month
- A **CTE** and the **window function `LAG()`** to measure month-to-month change

## Data quality notes

- **Mixed units:** prices are in KG, 100 KG, Head, L and Day. The analysis keeps only KG and 100 KG rows (49,163 rows, 77 commodities) and divides 100 KG prices by 100.
- **Likely mislabelled units:** 1,708 rows have a price under 1 birr per kg, mostly retail wheat from 2007 to 2015. In Diredawa in January 2010, for example, the retail wheat price is 6.0 labelled "100 KG", while the wholesale price in the same market and month is 580 per 100 KG. The retail value looks like a per-kg price. Very few rows are affected from 2020 onward, so the 2020-2025 questions are not materially affected.
- **Changing coverage:** the number of markets reporting changes from year to year, so averages may partly reflect which markets were included.

## Limitations

- Prices are nominal, not adjusted for inflation.
- Regional differences are descriptive. The data does not explain why prices differ.
- Addis Ababa has no retail data for 2025, so it is not in the regional comparison.
- The retail vs wholesale comparison is limited to white maize, because wheat is affected by the unit problem above.


## Author

Yohana Hiruy | [LinkedIn](https://www.linkedin.com/in/yohana-hiruy-55b225380) | johanhgf5@gmail.com
