-- =========================================
-- 1. Drop tables if already exist (clean re-run)
-- =========================================
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS credit_card;
DROP TABLE IF EXISTS card_holder;
DROP TABLE IF EXISTS merchant;
DROP TABLE IF EXISTS merchant_category;

-- =========================================
-- 2. Card Holder Table
-- =========================================
CREATE TABLE card_holder (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

-- =========================================
-- 3. Credit Card Table
-- =========================================
CREATE TABLE credit_card (
    card VARCHAR(20) PRIMARY KEY,
    id_card_holder INT NOT NULL,
    CONSTRAINT fk_credit_card_id_card_holder 
        FOREIGN KEY (id_card_holder) REFERENCES card_holder(id)
        ON DELETE CASCADE,
    CONSTRAINT check_credit_card_length 
        CHECK (CHAR_LENGTH(card) <= 20)
);

-- =========================================
-- 4. Merchant Category Table
-- =========================================
CREATE TABLE merchant_category (
    id INT AUTO_INCREMENT PRIMARY KEY,
    category VARCHAR(100) NOT NULL
);

-- =========================================
-- 5. Merchant Table
-- =========================================
CREATE TABLE merchant (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    id_merchant_category INT NOT NULL,
    CONSTRAINT fk_merchant_id_merchant_category 
        FOREIGN KEY (id_merchant_category) REFERENCES merchant_category(id)
        ON DELETE CASCADE
);

-- =========================================
-- 6. Transactions Table
-- =========================================
CREATE TABLE transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    date DATETIME NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    card VARCHAR(20) NOT NULL,
    id_merchant INT NOT NULL,
    CONSTRAINT fk_transactions_card 
        FOREIGN KEY (card) REFERENCES credit_card(card)
        ON DELETE CASCADE,
    CONSTRAINT fk_transactions_id_merchant 
        FOREIGN KEY (id_merchant) REFERENCES merchant(id)
        ON DELETE CASCADE
);
SELECT * FROM transactions;
-- =========================================
-- 7. Fraud Analysis Queries
-- =========================================

-- (a) Top 100 highest transactions between 7-9 AM
CREATE OR REPLACE VIEW v_high_morning_transactions AS
SELECT t.id, t.date, t.amount, c.id_card_holder, m.name AS merchant
FROM transactions t
JOIN credit_card c ON t.card = c.card
JOIN merchant m ON t.id_merchant = m.id
WHERE HOUR(t.date) BETWEEN 7 AND 9
ORDER BY t.amount DESC
LIMIT 100;

SELECT * FROM v_high_morning_transactions;

-- (b) Count of transactions < $2.00 per cardholder
CREATE OR REPLACE VIEW v_small_tx_per_cardholder AS
SELECT c.id_card_holder, COUNT(*) AS small_tx_count
FROM transactions t
JOIN credit_card c ON t.card = c.card
WHERE t.amount < 2.00
GROUP BY c.id_card_holder;

SELECT * FROM v_small_tx_per_cardholder;

-- (c) Top 5 merchants with highest number of small (<$2) transactions
CREATE OR REPLACE VIEW v_top_small_tx_merchants AS
SELECT m.id, m.name, COUNT(*) AS small_tx_count
FROM transactions t
JOIN merchant m ON t.id_merchant = m.id
WHERE t.amount < 2.00
GROUP BY m.id, m.name
ORDER BY small_tx_count DESC
LIMIT 5;

SELECT * FROM v_top_small_tx_merchants;

-- =========================================
-- 8. Outlier Detection
-- =========================================

-- Standard Deviation Method
CREATE OR REPLACE VIEW v_outlier_stddev AS
SELECT t.*, 
       (SELECT AVG(amount) FROM transactions) AS avg_amt,
       (SELECT STD(amount) FROM transactions) AS std_amt
FROM transactions t
WHERE t.amount > (SELECT AVG(amount) + 3 * STD(amount) FROM transactions)
   OR t.amount < (SELECT AVG(amount) - 3 * STD(amount) FROM transactions);

SELECT * FROM v_outlier_stddev;

-- Interquartile Range Method
CREATE OR REPLACE VIEW v_outlier_iqr AS
SELECT t.*
FROM transactions t
JOIN (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(amount ORDER BY amount), ',', FLOOR(0.25 * COUNT(*) )), ',', -1) AS Q1,
        SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(amount ORDER BY amount), ',', FLOOR(0.75 * COUNT(*) )), ',', -1) AS Q3
    FROM transactions
) q
WHERE t.amount < (q.Q1 - 1.5*(q.Q3 - q.Q1))
   OR t.amount > (q.Q3 + 1.5*(q.Q3 - q.Q1));

SELECT * FROM v_outlier_iqr;

-- =========================================
-- 9. Fraudulent Customers Report (Reusable View)
-- =========================================
CREATE OR REPLACE VIEW v_fraudulent_customers AS
SELECT ch.name AS cardholder_name, COUNT(*) AS suspicious_tx_count
FROM transactions t
JOIN credit_card cc ON t.card = cc.card
JOIN card_holder ch ON cc.id_card_holder = ch.id
WHERE t.id IN (
    SELECT id FROM v_high_morning_transactions
    UNION
    SELECT id FROM v_outlier_stddev
    UNION
    SELECT id FROM v_outlier_iqr
)
GROUP BY ch.name
ORDER BY suspicious_tx_count DESC;

SELECT * FROM v_fraudulent_customers;
