create database LB_Assign
use LB_Assign

select * from hrr

--1.Compare an employee's performance rating with the average rating of their peers in the same department.

SELECT 
    e.Employee_Number, 
    e.Department, 
    e.Performance_Rating AS IndividualRating,
    d.AvgRating AS DepartmentAvgRating
FROM 
    Hrr e
INNER JOIN 
    (SELECT 
        Department, 
        AVG(Performance_Rating) AS AvgRating
     FROM 
        Hrr d
     GROUP BY 
        Department) d ON e.Department = d.Department

--2.Analyze the trend of employee attrition over time.

ALTER TABLE hrr
ADD Time_Period INT;

ALTER TABLE hrr
drop column Time_Period

UPDATE hrr
SET Time_Period = [Years_At_Company];

SELECT Time_Period AS Tenure_Years, 
       COUNT(*) AS TotalEmployees, 
       SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS AttritionCount, 
       (SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 1.0 / COUNT(*)) * 100 AS AttritionRate
FROM hrr
GROUP BY Time_Period
ORDER BY Time_Period asc;

--3.Predict the likelihood of an employee leaving based on their age, job role, and performance rating

-- Attrition Rate by Age
SELECT Age, AVG(CASE WHEN Attrition = 'Yes' THEN 1.0 ELSE 0.0 END) * 100 AS AttritionRate
FROM hrr
GROUP BY Age
ORDER BY Age;

-- Attrition Rate by Job Role
SELECT Job_Role, AVG(CASE WHEN Attrition = 'Yes' THEN 1.0 ELSE 0.0 END) * 100 AS AttritionRate
FROM hrr
GROUP BY Job_Role
ORDER BY Job_Role;

-- Attrition Rate by Performance Rating
SELECT Performance_Rating, AVG(CASE WHEN Attrition = 'Yes' THEN 1.0 ELSE 0.0 END) * 100 AS AttritionRate
FROM hrr
GROUP BY Performance_Rating
ORDER BY Performance_Rating;



SELECT Age, Job_Role, Performance_Rating, 
       AVG(CASE WHEN Attrition = 'Yes' THEN 1.0 ELSE 0.0 END) * 100 AS AttritionRate
FROM hrr
GROUP BY Age, Job_Role, Performance_Rating
ORDER BY AttritionRate DESC;

--4.Compare the attrition rate between different departments.

SELECT
    Department,
    COUNT(*) AS TotalEmployees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS EmployeesLeft,
    CAST(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) * 100 AS AttritionRatePercent
FROM
    hrr
GROUP BY
    Department
ORDER BY
    AttritionRatePercent DESC;

--5.Create Notification Alerts: Set up notification alerts in the database system to trigger when specific conditions are met 
--(e.g., sudden increase in attrition rate, take a threshold of >=10%)

drop trigger trg_AttritionRate

SELECT
    (SUM(CASE WHEN Attrition = 'Yes' THEN 1.0 ELSE 0 END) / COUNT(*)) * 100 AS AttritionRatePercentage
FROM
    hrr

CREATE TRIGGER trg_AttritionRate
ON hrr
AFTER INSERT, UPDATE
AS
BEGIN
    
    DECLARE @ThresholdRate FLOAT = 10.0; 
    DECLARE @CurrentAttritionRate FLOAT;
    DECLARE @TotalEmployees INT, @AttritionCount INT;

    
    SELECT @TotalEmployees = COUNT(*) FROM Employees;
    SELECT @AttritionCount = COUNT(*) FROM Employees WHERE Attrition = 'Yes';

   
    IF @TotalEmployees > 0
    BEGIN
        SET @CurrentAttritionRate = (@AttritionCount * 100.0) / @TotalEmployees;

        -- Check if the  attrition rate exceeds the threshold
        IF @CurrentAttritionRate >= @ThresholdRate
        BEGIN
            DECLARE @ErrorMessage VARCHAR(4000) = 'Alert: Attrition rate has reached the max threshold of >=10%%. Current rate: ' + CAST(@CurrentAttritionRate AS VARCHAR(10)) + '%%';
                 RAISERROR(@ErrorMessage, 10, 1);
        END
    END
END

--6.Pivot data to compare the average hourly rate across different education fields.


SELECT 'Average Hourly Rate' AS Metric, [Life Sciences], [Medical], [Marketing], [Technical Degree], [Human Resources], [Other]
FROM
(
    SELECT Education_Field, Hourly_Rate
    FROM hrr
) AS SourceData
PIVOT
(
    AVG(Hourly_Rate)
    FOR Education_Field IN ([Life Sciences], [Medical], [Marketing], [Technical Degree], [Human Resources], [Other])
) AS PivotedData;


    