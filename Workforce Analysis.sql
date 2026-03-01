

--------------------------------------------- CREATE DATABASE------------------------------------
CREATE DATABASE WorkforceAnalysis;

USE WorkforceAnalysis;



------------------------------------------- CREATE TABLE-----------------------------------------
CREATE TABLE Salaries (
    work_year INT,
    experience_level VARCHAR(5),
    employment_type VARCHAR(5),
    job_title VARCHAR(255),
    salary BIGINT,
    salary_currency VARCHAR(10),
    salary_in_usd BIGINT,
    employee_residence VARCHAR(10),
    remote_ratio INT,
    company_location VARCHAR(10),
    company_size VARCHAR(5)
);



------------------------------------------ IMPORTING DATA ----------------------------------------

SELECT SERVERPROPERTY('InstanceDefaultDataPath') AS DataPath;


BULK INSERT Salaries
FROM 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\salaries (2).csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK,
    CODEPAGE = '65001'
);



USE WorkforceAnalysis;

----------------------------------------TASK 1-----------------------------------------
--Investigating Job Market Based on Company Size (2021)

SELECT company_size,
       COUNT(*) AS Total_Employees
FROM Salaries
WHERE work_year = 2021
GROUP BY company_size
ORDER BY Total_Employees DESC;




------------------------------------ TASK 2---------------------------------------------
--Top 3 job titles with highest average salary
WITH Eligible_Countries AS
(
    SELECT company_location
    FROM Salaries
    WHERE work_year = 2023
    GROUP BY company_location
    HAVING COUNT(*) > 50
)

SELECT TOP 3 job_title,
       AVG(salary_in_usd) AS Avg_Salary,
       COUNT(*) AS Total_PT_Employees
FROM Salaries
WHERE employment_type = 'PT'
  AND work_year = 2023
  AND company_location IN (SELECT company_location FROM Eligible_Countries)
GROUP BY job_title
ORDER BY Avg_Salary DESC;




------------------------------------- TASK 3----------------------------------------------
--Identify countries where: Average salary of Mid-Level (MI) employees in 2023 is greater than Overall average Mid-Level salary in 2023


SELECT AVG(salary_in_usd)
FROM Salaries
WHERE experience_level = 'MI'
  AND work_year = 2023


SELECT company_location,
       AVG(salary_in_usd) AS Country_Avg_Salary
FROM Salaries
WHERE experience_level = 'MI'
  AND work_year = 2023
GROUP BY company_location
HAVING AVG(salary_in_usd) >
(
    SELECT AVG(salary_in_usd)
    FROM Salaries
    WHERE experience_level = 'MI'
      AND work_year = 2023
)
ORDER BY Country_Avg_Salary DESC;




-----------------------------------------TASK 4------------------------------------------------
--Country paying highest average salary,Country paying lowest average salary For Senior-Level (SE) employees In 2023

WITH Senior_Salary AS
(
    SELECT company_location,
           AVG(salary_in_usd) AS Avg_Salary
    FROM Salaries
    WHERE experience_level = 'SE'
      AND work_year = 2023
    GROUP BY company_location
)

SELECT *
FROM Senior_Salary
WHERE Avg_Salary = (SELECT MAX(Avg_Salary) FROM Senior_Salary)
   OR Avg_Salary = (SELECT MIN(Avg_Salary) FROM Senior_Salary);




----------------------------------------TASK 5 -----------------------------------------------
--Salary growth rates by job title:

WITH Salary_Comparison AS
(
    SELECT job_title,
           AVG(CASE WHEN work_year = 2023 THEN salary_in_usd END) AS Avg_2023,
           AVG(CASE WHEN work_year = 2024 THEN salary_in_usd END) AS Avg_2024
    FROM Salaries
    WHERE work_year IN (2023, 2024)
    GROUP BY job_title
)

SELECT job_title,
       Avg_2023,
       Avg_2024,
       ((Avg_2024 - Avg_2023) * 100.0 / Avg_2023) AS Growth_Percentage
FROM Salary_Comparison
WHERE Avg_2023 IS NOT NULL 
  AND Avg_2024 IS NOT NULL
ORDER BY Growth_Percentage DESC;




-------------------------------------- TASK 6 -------------------------------------------
--Top three countries with the highest salary growth for entrylevel roles from 2020 to 2023:
WITH EntryLevelGrowth AS
(
    SELECT company_location,
           COUNT(*) AS Total_Employees,
           AVG(CASE WHEN work_year = 2020 THEN salary_in_usd END) AS Avg_2020,
           AVG(CASE WHEN work_year = 2023 THEN salary_in_usd END) AS Avg_2023
    FROM Salaries
    WHERE experience_level = 'EN'
      AND work_year IN (2020, 2023)
    GROUP BY company_location
    HAVING COUNT(*) > 50
)

SELECT TOP 3 company_location,
       Avg_2020,
       Avg_2023,
       ((Avg_2023 - Avg_2020) * 100.0 / Avg_2020) AS Growth_Percentage
FROM EntryLevelGrowth
WHERE Avg_2020 IS NOT NULL
  AND Avg_2023 IS NOT NULL
ORDER BY Growth_Percentage DESC;





---------------------------------------- TASK 7---------------------------------------------
SELECT *
FROM Salaries
WHERE salary_in_usd > 90000
  AND employee_residence IN ('US','AU');



  UPDATE Salaries
SET remote_ratio = 100
WHERE salary_in_usd > 90000
  AND employee_residence IN ('US','AU');






  ------------------------------------- TASK 8 ----------------------------------------------
  --Salary updates based on percentage increases by level in 2024:

UPDATE Salaries
SET salary_in_usd = 
    CASE 
        WHEN experience_level = 'SE' THEN salary_in_usd * 1.22
        WHEN experience_level = 'MI' THEN salary_in_usd * 1.30
        WHEN experience_level = 'EN' THEN salary_in_usd * 1.15
        WHEN experience_level = 'EX' THEN salary_in_usd * 1.18
        ELSE salary_in_usd
    END
WHERE work_year = 2024;



--------------------------------- TASK 9 ---------------------------------------------------
--Year with the highest average salary for each job title:

WITH AvgSalaryPerYear AS
(
    SELECT job_title,
           work_year,
           AVG(salary_in_usd) AS Avg_Salary
    FROM Salaries
    GROUP BY job_title, work_year
)

SELECT A.job_title,
       A.work_year AS Highest_Paying_Year,
       A.Avg_Salary
FROM AvgSalaryPerYear A
WHERE A.Avg_Salary = 
(
    SELECT MAX(B.Avg_Salary)
    FROM AvgSalaryPerYear B
    WHERE A.job_title = B.job_title
)
ORDER BY A.job_title;





---------------------------------- TASK 10-----------------------------------------------------
--Percentage of employment types for different job titles:

SELECT job_title,

       COUNT(*) AS Total_Employees,

       SUM(CASE WHEN employment_type = 'FT' THEN 1 ELSE 0 END) * 100.0 
       / COUNT(*) AS FullTime_Percentage,

       SUM(CASE WHEN employment_type = 'PT' THEN 1 ELSE 0 END) * 100.0 
       / COUNT(*) AS PartTime_Percentage

FROM Salaries
GROUP BY job_title
ORDER BY job_title;



------------------------------ TASK 11--------------------------------------------------------
--COUNTRIES OFFERING FULL REMOTE WORK FOR MANAGERS WITH SALARIES OVER $90,000:


SELECT employee_residence,
       COUNT(*) AS Total_Managers,
       AVG(salary_in_usd) AS Avg_Salary
FROM Salaries
WHERE job_title LIKE '%Manager%'
  AND salary_in_usd > 90000
  AND remote_ratio = 100
GROUP BY employee_residence
ORDER BY Avg_Salary DESC;




------------------------------- TASK 12 -------------------------------------------------------
--Top 5 countries with the most large companies:

SELECT TOP 5 
       company_location,
       COUNT(*) AS Large_Company_Count
FROM Salaries
WHERE company_size = 'L'
GROUP BY company_location
ORDER BY Large_Company_Count DESC;




------------------------------ TASK 13 --------------------------------------------------------
--Percentage of employees with fully remote roles earning more than $100,000:

SELECT 
    COUNT(CASE 
            WHEN remote_ratio = 100 
             AND salary_in_usd > 100000 
            THEN 1 
         END) * 100.0 / COUNT(*) 
    AS Percentage_FullyRemote_Over100K
FROM Salaries;




--------------------------- TASK 14 ---------------------------------------------------------
--Locations where entry-level average salaries exceed market average for entry level:

SELECT company_location,
       AVG(salary_in_usd) AS Location_Avg_Salary
FROM Salaries
WHERE experience_level = 'EN'
GROUP BY company_location
HAVING AVG(salary_in_usd) >
(
    SELECT AVG(salary_in_usd)
    FROM Salaries
    WHERE experience_level = 'EN'
)
ORDER BY Location_Avg_Salary DESC;




-------------------------- TASK 15 ----------------------------------------------------------
--Countries paying the maximum average salary for each job title:

WITH AvgSalaryByCountry AS
(
    SELECT job_title,
           employee_residence,
           AVG(salary_in_usd) AS Avg_Salary
    FROM Salaries
    GROUP BY job_title, employee_residence
),
RankedSalaries AS
(
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY job_title
               ORDER BY Avg_Salary DESC
           ) AS rn
    FROM AvgSalaryByCountry
)

SELECT job_title,
       employee_residence AS Highest_Paying_Country,
       Avg_Salary
FROM RankedSalaries
WHERE rn = 1
ORDER BY job_title;




---------------------------------- TASK 16 --------------------------------------------------------
--Countries with sustained salary growth over three years:

WITH CountryYearAvg AS
(
    SELECT company_location,
           work_year,
           AVG(salary_in_usd) AS Avg_Salary
    FROM Salaries
    WHERE work_year IN (2021, 2022, 2023)
    GROUP BY company_location, work_year
),
PivotedData AS
(
    SELECT company_location,
           MAX(CASE WHEN work_year = 2021 THEN Avg_Salary END) AS Avg_2021,
           MAX(CASE WHEN work_year = 2022 THEN Avg_Salary END) AS Avg_2022,
           MAX(CASE WHEN work_year = 2023 THEN Avg_Salary END) AS Avg_2023
    FROM CountryYearAvg
    GROUP BY company_location
)

SELECT company_location,
       Avg_2021,
       Avg_2022,
       Avg_2023
FROM PivotedData
WHERE Avg_2021 IS NOT NULL
  AND Avg_2022 IS NOT NULL
  AND Avg_2023 IS NOT NULL
  AND Avg_2021 < Avg_2022
  AND Avg_2022 < Avg_2023
ORDER BY Avg_2023 DESC;



----------------------------------- TASK 17-----------------------------------------------
--PERCENTAGE OF FULLY REMOTE WORK BY EXPERIENCE LEVEL (2021 VS 2024):

WITH RemoteData AS
(
    SELECT experience_level,
           work_year,
           COUNT(*) AS Total_Employees,
           SUM(CASE WHEN remote_ratio = 100 THEN 1 ELSE 0 END) AS Fully_Remote_Count
    FROM Salaries
    WHERE work_year IN (2021, 2024)
    GROUP BY experience_level, work_year
)

SELECT experience_level,

       MAX(CASE WHEN work_year = 2021 
                THEN (Fully_Remote_Count * 100.0 / Total_Employees) 
           END) AS Remote_Percentage_2021,

       MAX(CASE WHEN work_year = 2024 
                THEN (Fully_Remote_Count * 100.0 / Total_Employees) 
           END) AS Remote_Percentage_2024

FROM RemoteData
GROUP BY experience_level
ORDER BY experience_level;




------------------------------------------ TASK 18 -----------------------------------------------
--Average salary increase percentage by experience level and job title (2023 to 2024):

WITH SalaryComparison AS
(
    SELECT experience_level,
           job_title,
           AVG(CASE WHEN work_year = 2023 THEN salary_in_usd END) AS Avg_2023,
           AVG(CASE WHEN work_year = 2024 THEN salary_in_usd END) AS Avg_2024
    FROM Salaries
    WHERE work_year IN (2023, 2024)
    GROUP BY experience_level, job_title
)

SELECT experience_level,
       job_title,
       Avg_2023,
       Avg_2024,
       ((Avg_2024 - Avg_2023) * 100.0 / Avg_2023) AS Salary_Growth_Percentage
FROM SalaryComparison
WHERE Avg_2023 IS NOT NULL
  AND Avg_2024 IS NOT NULL
ORDER BY experience_level, Salary_Growth_Percentage DESC;




---------------------------------------------- TASK 19 ---------------------------------------------------
--Role-based access control for employees based on experience level:


--1 Create Security Schema
CREATE SCHEMA Security;


--2 Create Security Predicate Function
CREATE FUNCTION Security.fn_ExperienceLevelFilter (@experience_level AS NVARCHAR(2))
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
SELECT 1 AS Result
WHERE @experience_level = USER_NAME();


--3  Create Security Policy
CREATE SECURITY POLICY ExperienceLevelPolicy
ADD FILTER PREDICATE Security.fn_ExperienceLevelFilter(experience_level)
ON dbo.Salaries
WITH (STATE = ON);


--4  Create Users for Each Level
CREATE USER EN WITHOUT LOGIN;
CREATE USER MI WITHOUT LOGIN;
CREATE USER SE WITHOUT LOGIN;
CREATE USER EX WITHOUT LOGIN;


--5  Grant SELECT Permission
GRANT SELECT ON Salaries TO EN;
GRANT SELECT ON Salaries TO MI;
GRANT SELECT ON Salaries TO SE;
GRANT SELECT ON Salaries TO EX;



------------------------------------------ TASK 20 ----------------------------------------------------
--Guiding clients in switching domains based on salary insights:


--1 — Find Higher Paying Roles Within Same Experience Level

WITH RoleAvgSalary AS
(
    SELECT experience_level,
           job_title,
           AVG(salary_in_usd) AS Avg_Salary
    FROM Salaries
    GROUP BY experience_level, job_title
)

SELECT A.experience_level,
       A.job_title AS Current_Role,
       B.job_title AS Recommended_Role,
       B.Avg_Salary AS Higher_Avg_Salary
FROM RoleAvgSalary A
JOIN RoleAvgSalary B
    ON A.experience_level = B.experience_level
WHERE B.Avg_Salary > A.Avg_Salary
ORDER BY A.experience_level, B.Avg_Salary DESC;



--2 — Identify Fast-Growing Roles (2023 → 2024)

WITH GrowthData AS
(
    SELECT experience_level,
           job_title,
           AVG(CASE WHEN work_year = 2023 THEN salary_in_usd END) AS Avg_2023,
           AVG(CASE WHEN work_year = 2024 THEN salary_in_usd END) AS Avg_2024
    FROM Salaries
    WHERE work_year IN (2023, 2024)
    GROUP BY experience_level, job_title
)

SELECT experience_level,
       job_title,
       ((Avg_2024 - Avg_2023) * 100.0 / Avg_2023) AS Growth_Percentage
FROM GrowthData
WHERE Avg_2023 IS NOT NULL 
  AND Avg_2024 IS NOT NULL
ORDER BY Growth_Percentage DESC;


--3 — Location-Based Salary Premium

SELECT company_location,
       job_title,
       AVG(salary_in_usd) AS Avg_Salary
FROM Salaries
GROUP BY company_location, job_title
ORDER BY Avg_Salary DESC;




