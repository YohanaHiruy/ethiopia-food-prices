# Ethiopia Food Prices Analysis

I used SQL and Power BI to explore food prices across Ethiopia using data from the World Food Programme (WFP).

### Power BI Dashboard

[**View / Download Power BI Dashboard (.pbix)**](https://github.com/YohanaHiruy/ethiopia-food-prices/blob/main/Ethiopia%20Food%20Prices.pbix)

![Dashboard Preview](dashboard.png)
### Key findings
- White maize (retail) rose from about **12.58 to 47.28 birr per kg** between 2020 and 2025, roughly **+276%**.
- The fastest-rising foods (2020 to 2025) were **coffee (+562%)** and **barley (+517%)**.
- In 2025, white maize cost about **58 birr/kg in Somali** and **41 in Gambela**, around 41% more.
- In the same market and month, retail white maize was about **19% above wholesale**.

### Data notes
- Prices come in different units, so everything was converted to birr per kg.
- About 1,700 price rows, mostly retail wheat from 2007 to 2015, look mislabelled (the retail price is labelled 100 KG but looks like a per-kg price), so most questions focus on 2020 onward.
- Prices are in birr and not adjusted for inflation, so the results show price changes, not their causes.

### What I explored
- Food price changes over time
- Differences in prices across regions
- Comparison of food commodities
- Retail vs. wholesale prices

### Tools
- MySQL – data analysis
- Power BI – dashboard and visualization
- Power Query – data preparation

### Files
- [Power BI Dashboard](Ethiopia%20Food%20Prices.pbix)
- [SQL Queries](food_price_analysis.sql)
- [Original Dataset](wfp_food_prices_eth.csv)
- [Dashboard Screenshot](dashboard.png)

**Author:** Yohana Hiruy

[GitHub Profile](https://github.com/YohanaHiruy)
