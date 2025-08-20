# Credit Card Fraud Detection Database Project

## Project Overview
This project designs and implements a relational database schema and advanced SQL queries to detect fraudulent credit card transactions. It applies various fraud detection techniques, including time-based filters, small transaction patterns, and statistical outlier detection using standard deviation and interquartile range (IQR) methods.

## Features
- Relational schema with tables for card holders, credit cards, merchants, merchant categories, and transactions.
- SQL views to identify:
  - Top 100 highest transactions during early morning hours (7-9 AM).
  - Cardholders with many small transactions (< $2).
  - Merchants prone to small suspicious transactions.
  - Outlier transactions detected by standard deviation and IQR methods.
- Aggregate reports of suspicious transactions per cardholder.

## Usage
1. Create the database and tables by running the SQL schema file.
2. Populate tables with transaction data.
3. Execute provided views to identify potential fraud cases.
4. Query views to generate reports or integrate with data visualization tools.
