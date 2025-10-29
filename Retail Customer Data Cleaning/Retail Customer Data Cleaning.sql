

-- Explore the Raw Data
SELECT TOP 10 * FROM dbo.Customers_Raw;

-- Check null counts per column
SELECT 
    SUM(CASE WHEN Email IS NULL THEN 1 ELSE 0 END) AS NullEmails,
    SUM(CASE WHEN TotalSpend IS NULL THEN 1 ELSE 0 END) AS NullSpending,
    SUM(CASE WHEN DateJoined IS NULL THEN 1 ELSE 0 END) AS NullJoinDates,
    SUM(CASE WHEN LastPurchaseDate IS NULL THEN 1 ELSE 0 END) AS NullPurchases
FROM dbo.Customers_Raw;

-- Remove Duplicate
WITH Duplicates AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY FullName, Phone ORDER BY CustomerID) AS rn
    FROM dbo.Customers_Raw
)
DELETE FROM Duplicates WHERE rn > 1;

-- Standardize Names & States Columns
UPDATE dbo.Customers_Raw
SET FullName = CONCAT(UPPER(LEFT(FullName,1)), LOWER(SUBSTRING(FullName,2,LEN(FullName)))),
    State = CONCAT(UPPER(LEFT(State,1)), LOWER(SUBSTRING(State,2,LEN(State))));

-- Emails to lowercase
UPDATE dbo.Customers_Raw
SET Email = LOWER(Email);

-- Standardize Phone Numbers
UPDATE dbo.Customers_Raw
SET Phone = CASE 
               WHEN CAST(Phone AS VARCHAR(20)) LIKE '0%' 
                    THEN '+234' + SUBSTRING(CAST(Phone AS VARCHAR(20)), 2, LEN(CAST(Phone AS VARCHAR(20))))
               WHEN CAST(Phone AS VARCHAR(20)) LIKE '+234%' 
                    THEN CAST(Phone AS VARCHAR(20))
               ELSE CAST(Phone AS VARCHAR(20))
            END;

-- Clean Gender Field
UPDATE dbo.Customers_Raw
SET Gender = CASE 
                WHEN Gender IN ('M','m','Male','MALE') THEN 'Male'
                WHEN Gender IN ('F','f','Female','FEMALE') THEN 'Female'
                ELSE NULL
             END;


				-- Handle Missing Values
-- Replace NULL TotalSpend with 0
UPDATE dbo.Customers_Raw
SET TotalSpend = 0
WHERE TotalSpend IS NULL;

-- Replace NULL DateJoined with a placeholder
UPDATE dbo.Customers_Raw
SET DateJoined = '2023-01-01'
WHERE DateJoined IS NULL;

-- Replace missing LoyaltyStatus with 'Bronze'
UPDATE dbo.Customers_Raw
SET LoyaltyStatus = 'Bronze'
WHERE LoyaltyStatus IS NULL;

-- Validate Email Format
DELETE FROM dbo.Customers_Raw
WHERE Email IS NULL OR Email NOT LIKE '%@%.%';


-- Create Cleaned Table
SELECT *
INTO dbo.Customers_Cleaned
FROM dbo.Customers_Raw;


			-- Validation & Summary Checks
-- Compare before vs after
SELECT 
    (SELECT COUNT(*) FROM dbo.Customers_Raw) AS CleanedRows;

-- Example quality check
SELECT Gender, COUNT(*) AS CountByGender
FROM dbo.Customers_Cleaned
GROUP BY Gender;

SELECT State, COUNT(*) AS CustomersPerState
FROM dbo.Customers_Cleaned
GROUP BY State
ORDER BY CustomersPerState DESC;

