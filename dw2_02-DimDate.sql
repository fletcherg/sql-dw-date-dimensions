--
-- Create date dimension
--
-- Includes financial information (thanks http://www.bradleyschacht.com/date-dimension-script-with-fiscal-year/)
-- 

IF EXISTS(
  SELECT * 
  FROM sys.tables t
  JOIN sys.schemas s
    ON t.SCHEMA_ID = s.schema_id
  WHERE 
      t.name = N'Date' AND t.type='U' 
  AND s.NAME = 'Dimension'
)
  DROP TABLE [Dimension].[date];
GO

 
-- Standard options for creating tables
SET ANSI_NULLS ON
GO
 
SET QUOTED_IDENTIFIER ON
GO
 
-- Create your dimension table
-- Adjust to your own needs
Create Table dimension.date
(
    [Date_id]						int,
    [Date]						date,
    [Date String]					varchar(10),
	[Date String US]				varchar(10),
    [Calendar Day]					int,
	[Calendar Day Suffix]				varchar(4),
    [Calendar Day of Year]				int,
    [Calendar Day of Week]				int,
    [Calendar Day of Week Name]				varchar(10),
	[Calendar Day of Week Name Short]		varchar(3),
    [Calendar Week]					int,
    [Calendar Month]					int,
    [Calendar Month Name]				varchar(10),
	[Calendar Month Name Short]			varchar(3),
    [Calendar Quarter]					int,
	[Calendar Quarter Name]				varchar(9),
    [Calendar Year]					int,
    [Calendar Is Weekend]				bit,
    [Calendar Is Leap Year]				bit
	CONSTRAINT PK_Dates PRIMARY KEY CLUSTERED (Date_ID)
)
 
-- Declare and set variables for loop
Declare
@StartDate datetime,
@EndDate datetime,
@Date datetime
 
Set @StartDate = '2015/01/01'
Set @EndDate = '2018/12/31'
Set @Date = @StartDate
 
-- Loop through dates
WHILE @Date <=@EndDate
BEGIN
    -- Check for leap year
    DECLARE @IsLeapYear BIT
    IF ((Year(@Date) % 4 = 0) AND (Year(@Date) % 100 != 0 OR Year(@Date) % 400 = 0))
    BEGIN
        SELECT @IsLeapYear = 1
    END
    ELSE
    BEGIN
        SELECT @IsLeapYear = 0
    END
 
    -- Check for weekend
    DECLARE @IsWeekend BIT
    IF (DATEPART(dw, @Date) = 1 OR DATEPART(dw, @Date) = 7)
    BEGIN
        SELECT @IsWeekend = 1
    END
    ELSE
    BEGIN
        SELECT @IsWeekend = 0
    END
 
    -- Insert record in dimension table
    INSERT Into [dimension].[date]
    (
	[Date_id],
    	[Date],
    	[Date String],
	[Date String US],
    	[Calendar Day],
	[Calendar Day Suffix],
    	[Calendar Day of Year],
    	[Calendar Day of Week],
   	[Calendar Day of Week Name],
	[Calendar Day of Week Name Short],
    	[Calendar Week],
    	[Calendar Month],
    	[Calendar Month Name],
	[Calendar Month Name Short],
    	[Calendar Quarter],
	[Calendar Quarter Name],
    	[Calendar Year],
    	[Calendar Is Weekend],
    	[Calendar Is Leap Year]
    )
    SELECT
    
	CONVERT(VARCHAR,@Date,112),
    @Date,
    CONVERT(varchar(10), @Date, 103),
	CONVERT(varchar(10), @Date, 101),
    Day(@Date),
	CASE 
			WHEN DATEPART(DD,@Date) IN (11,12,13) THEN CAST(DATEPART(DD,@Date) AS VARCHAR) + 'th'
			WHEN RIGHT(DATEPART(DD,@Date),1) = 1 THEN CAST(DATEPART(DD,@Date) AS VARCHAR) + 'st'
			WHEN RIGHT(DATEPART(DD,@Date),1) = 2 THEN CAST(DATEPART(DD,@Date) AS VARCHAR) + 'nd'
			WHEN RIGHT(DATEPART(DD,@Date),1) = 3 THEN CAST(DATEPART(DD,@Date) AS VARCHAR) + 'rd'
			ELSE CAST(DATEPART(DD,@Date) AS VARCHAR) + 'th' 
			END AS [Calendar Day Suffix],
    DATEPART(dy, @Date),
    DATEPART(dw, @Date),
    DATENAME(dw, @Date),
	FORMAT(@date,'ddd'),
    DATEPART(wk, @Date),
    DATEPART(mm, @Date),
    DATENAME(mm, @Date),
	FORMAT(@date,'MMM'),
    DATENAME(qq, @Date),
	CASE DATEPART(QQ, @Date)
			WHEN 1 THEN 'First'
			WHEN 2 THEN 'Second'
			WHEN 3 THEN 'Third'
			WHEN 4 THEN 'Fourth'
			END AS [Calendar Quarter Name],
    Year(@Date),
    @IsWeekend,
    @IsLeapYear
    
 
    -- Goto next day
    Set @Date = @Date + 1
END
GO

/*Add Fiscal date columns */
ALTER TABLE [Dimension].[Date] ADD
	[Fiscal Day Of Year]				varchar(3),
	[Fiscal Week Of Year]				varchar(3),
	[Fiscal Month]					varchar(2), 
	[Fiscal Quarter]				char(1),
	[Fiscal Quarter Name]				varchar(9),
	[Fiscal Year]					char(4),
	[Fiscal Year Name]				char(7),
	[Fiscal Month Year]				char(10),
	[Fiscal MMYYYY]					char(6),
	[Fiscal First Day Of Month]			date,
	[Fiscal Last Day Of Month]			date,
	[Fiscal First Day Of Quarter]			date,
	[Fiscal Last Day Of Quarter]			date,
	[Fiscal First Day Of Year]			date,
	[Fiscal Last Day Of Year]			date
	GO

/*******************************************************************************************************************************************************
The following section needs to be populated for defining the fiscal calendar
*******************************************************************************************************************************************************/

DECLARE
	@dtFiscalYearStart SMALLDATETIME = 'January 01, 1995',
	@FiscalYear int = 1995,
	@LastYear int = 2025,
	@FirstLeapYearInPeriod int = 1996

/*******************************************************************************************************************************************************/

DECLARE
	@iTemp INT,
	@LeapWeek INT,
	@CurrentDate DATETIME,
	@FiscalDayOfYear INT,
	@FiscalWeekOfYear INT,
	@FiscalMonth INT,
	@FiscalQuarter INT,
	@FiscalQuarterName VARCHAR(10),
	@FiscalYearName VARCHAR(7),
	@LeapYear INT,
	@FiscalFirstDayOfYear DATE,
	@FiscalFirstDayOfQuarter DATE,
	@FiscalFirstDayOfMonth DATE,
	@FiscalLastDayOfYear DATE,
	@FiscalLastDayOfQuarter DATE,
	@FiscalLastDayOfMonth DATE

/*Holds the years that have 455 in last quarter*/
DECLARE @LeapTable TABLE (leapyear INT)

/*TABLE to contain the fiscal year calendar*/
DECLARE @tb TABLE(
	PeriodDate DATETIME,
	[Fiscal Day Of Year] VARCHAR(3),
	[Fiscal Week Of Year] VARCHAR(3),
	[Fiscal Month] VARCHAR(2), 
	[Fiscal Quarter] VARCHAR(1),
	[Fiscal Quarter Name] VARCHAR(9),
	[Fiscal Year] VARCHAR(4),
	[Fiscal Year Name] VARCHAR(7),
	[Fiscal Month Year] VARCHAR(10),
	[Fiscal MMYYYY] VARCHAR(6),
	[Fiscal First Day Of Month] DATE,
	[Fiscal Last Day Of Month] DATE,
	[Fiscal First Day Of Quarter] DATE,
	[Fiscal Last Day Of Quarter] DATE,
	[Fiscal First Day Of Year] DATE,
	[Fiscal Last Day Of Year] DATE)

/*Populate the table with all leap years*/
SET @LeapYear = @FirstLeapYearInPeriod
WHILE (@LeapYear < @LastYear)
	BEGIN
		INSERT INTO @leapTable VALUES (@LeapYear)
		SET @LeapYear = @LeapYear + 5
	END

/*Initiate parameters before loop*/
SET @CurrentDate = @dtFiscalYearStart
SET @FiscalDayOfYear = 1
SET @FiscalWeekOfYear = 1
SET @FiscalMonth = 1
SET @FiscalQuarter = 1
SET @FiscalWeekOfYear = 1

IF (EXISTS (SELECT * FROM @LeapTable WHERE @FiscalYear = leapyear))
	BEGIN
		SET @LeapWeek = 1
	END
	ELSE
	BEGIN
		SET @LeapWeek = 0
	END

/*******************************************************************************************************************************************************/

/* Loop on days in interval*/
WHILE (DATEPART(yy,@CurrentDate) <= @LastYear)
BEGIN
	
/*SET fiscal Month*/
	SELECT @FiscalMonth = CASE 
		/*Use this section for a 4-5-4 calendar.  Every leap year the result will be a 4-5-5*/
		WHEN @FiscalWeekOfYear BETWEEN 1 AND 4 THEN 1 /*4 weeks*/
		WHEN @FiscalWeekOfYear BETWEEN 5 AND 9 THEN 2 /*5 weeks*/
		WHEN @FiscalWeekOfYear BETWEEN 10 AND 13 THEN 3 /*4 weeks*/
		WHEN @FiscalWeekOfYear BETWEEN 14 AND 17 THEN 4 /*4 weeks*/
		WHEN @FiscalWeekOfYear BETWEEN 18 AND 22 THEN 5 /*5 weeks*/
		WHEN @FiscalWeekOfYear BETWEEN 23 AND 26 THEN 6 /*4 weeks*/
		WHEN @FiscalWeekOfYear BETWEEN 27 AND 30 THEN 7 /*4 weeks*/
		WHEN @FiscalWeekOfYear BETWEEN 31 AND 35 THEN 8 /*5 weeks*/
		WHEN @FiscalWeekOfYear BETWEEN 36 AND 39 THEN 9 /*4 weeks*/
		WHEN @FiscalWeekOfYear BETWEEN 40 AND 43 THEN 10 /*4 weeks*/
		WHEN @FiscalWeekOfYear BETWEEN 44 AND (48+@LeapWeek) THEN 11 /*5 weeks*/
		WHEN @FiscalWeekOfYear BETWEEN (49+@LeapWeek) AND (52+@LeapWeek) THEN 12 /*4 weeks (5 weeks on leap year)*/
		
		/*Use this section for a 4-4-5 calendar.  Every leap year the result will be a 4-5-5*/
		/*
		WHEN @FiscalWeekOfYear BETWEEN 1 AND 4 THEN 1 /*4 weeks*/
		WHEN @FiscalWeekOfYear BETWEEN 5 AND 8 THEN 2 /*4 weeks*/
		WHEN @FiscalWeekOfYear BETWEEN 9 AND 13 THEN 3 /*5 weeks*/
		WHEN @FiscalWeekOfYear BETWEEN 14 AND 17 THEN 4 /*4 weeks*/
		WHEN @FiscalWeekOfYear BETWEEN 18 AND 21 THEN 5 /*4 weeks*/
		WHEN @FiscalWeekOfYear BETWEEN 22 AND 26 THEN 6 /*5 weeks*/
		WHEN @FiscalWeekOfYear BETWEEN 27 AND 30 THEN 7 /*4 weeks*/
		WHEN @FiscalWeekOfYear BETWEEN 31 AND 34 THEN 8 /*4 weeks*/
		WHEN @FiscalWeekOfYear BETWEEN 35 AND 39 THEN 9 /*5 weeks*/
		WHEN @FiscalWeekOfYear BETWEEN 40 AND 43 THEN 10 /*4 weeks*/
		WHEN @FiscalWeekOfYear BETWEEN 44 AND (47+@leapWeek) THEN 11 /*4 weeks (5 weeks on leap year)*/
		WHEN @FiscalWeekOfYear BETWEEN (48+@leapWeek) AND (52+@leapWeek) THEN 12 /*5 weeks*/
		*/
	END

	/*SET Fiscal Quarter*/
	SELECT @FiscalQuarter = CASE 
		WHEN @FiscalMonth BETWEEN 1 AND 3 THEN 1
		WHEN @FiscalMonth BETWEEN 4 AND 6 THEN 2
		WHEN @FiscalMonth BETWEEN 7 AND 9 THEN 3
		WHEN @FiscalMonth BETWEEN 10 AND 12 THEN 4
	END
	
	SELECT @FiscalQuarterName = CASE 
		WHEN @FiscalMonth BETWEEN 1 AND 3 THEN 'First'
		WHEN @FiscalMonth BETWEEN 4 AND 6 THEN 'Second'
		WHEN @FiscalMonth BETWEEN 7 AND 9 THEN 'Third'
		WHEN @FiscalMonth BETWEEN 10 AND 12 THEN 'Fourth'
	END
	
	/*Set Fiscal Year Name*/
	SELECT @FiscalYearName = 'FY ' + CONVERT(VARCHAR, @FiscalYear)

	INSERT INTO @tb (PeriodDate, [Fiscal Day Of Year], [Fiscal Week Of Year], [fiscal Month], [Fiscal Quarter], [Fiscal Quarter Name], [Fiscal Year], [Fiscal Year Name]) VALUES 
	(@CurrentDate, @FiscalDayOfYear, @FiscalWeekOfYear, @FiscalMonth, @FiscalQuarter, @FiscalQuarterName, @FiscalYear, @FiscalYearName)

	/*SET next day*/
	SET @CurrentDate = DATEADD(dd, 1, @CurrentDate)
	SET @FiscalDayOfYear = @FiscalDayOfYear + 1
	SET @FiscalWeekOfYear = ((@FiscalDayOfYear-1) / 7) + 1


	IF (@FiscalWeekOfYear > (52+@LeapWeek))
	BEGIN
		/*Reset a new year*/
		SET @FiscalDayOfYear = 1
		SET @FiscalWeekOfYear = 1
		SET @FiscalYear = @FiscalYear + 1
		IF ( EXISTS (SELECT * FROM @leapTable WHERE @FiscalYear = leapyear))
		BEGIN
			SET @LeapWeek = 1
		END
		ELSE
		BEGIN
			SET @LeapWeek = 0
		END
	END
END

/*******************************************************************************************************************************************************/

/*Set first and last days of the fiscal months*/
UPDATE @tb
SET
	[Fiscal First Day Of Month] = minmax.StartDate,
	[Fiscal Last Day Of Month] = minmax.EndDate
FROM
@tb t,
	(
	SELECT [Fiscal Month], [Fiscal Quarter], [Fiscal Year], MIN(PeriodDate) AS StartDate, MAX(PeriodDate) AS EndDate
	FROM @tb
	GROUP BY [Fiscal Month], [Fiscal Quarter], [Fiscal Year]
	) minmax
WHERE
	t.[Fiscal Month] = minmax.[Fiscal Month] AND
	t.[Fiscal Quarter] = minmax.[Fiscal Quarter] AND
	t.[Fiscal Year] = minmax.[Fiscal Year] 

/*Set first and last days of the fiscal quarters*/
UPDATE @tb
SET
	[Fiscal First Day Of Quarter] = minmax.StartDate,
	[Fiscal Last Day Of Quarter] = minmax.EndDate
FROM
@tb t,
	(
	SELECT [Fiscal Quarter], [Fiscal Year], min(PeriodDate) as StartDate, max(PeriodDate) as EndDate
	FROM @tb
	GROUP BY [Fiscal Quarter], [Fiscal Year]
	) minmax
WHERE
	t.[Fiscal Quarter] = minmax.[Fiscal Quarter] AND
	t.[Fiscal Year] = minmax.[Fiscal Year] 

/*Set first and last days of the fiscal years*/
UPDATE @tb
SET
	[Fiscal First Day Of Year] = minmax.StartDate,
	[Fiscal Last Day Of Year] = minmax.EndDate
FROM
@tb t,
	(
	SELECT [Fiscal Year], min(PeriodDate) as StartDate, max(PeriodDate) as EndDate
	FROM @tb
	GROUP BY [Fiscal Year]
	) minmax
WHERE
	t.[Fiscal Year] = minmax.[Fiscal Year]

/*Set FiscalYearMonth*/
UPDATE @tb
SET
	[Fiscal Month Year] = 
		CASE [Fiscal Month]
		WHEN 1 THEN 'Jan'
		WHEN 2 THEN 'Feb'
		WHEN 3 THEN 'Mar'
		WHEN 4 THEN 'Apr'
		WHEN 5 THEN 'May'
		WHEN 6 THEN 'Jun'
		WHEN 7 THEN 'Jul'
		WHEN 8 THEN 'Aug'
		WHEN 9 THEN 'Sep'
		WHEN 10 THEN 'Oct'
		WHEN 11 THEN 'Nov'
		WHEN 12 THEN 'Dec'
		END + '-' + CONVERT(VARCHAR, [Fiscal Year])

/*Set FiscalMMYYYY*/
UPDATE @tb
SET
	[Fiscal MMYYYY] = RIGHT('0' + CONVERT(VARCHAR, [Fiscal Month]),2) + CONVERT(VARCHAR, [Fiscal Year])

/*******************************************************************************************************************************************************/
UPDATE [Dimension].[Date]
	SET
	[Fiscal Day Of Year] = a.[Fiscal Day Of Year]
	, [Fiscal Week Of Year] = a.[Fiscal Week Of Year]
	, [Fiscal Month] = a.[Fiscal Month]
	, [Fiscal Quarter] = a.[Fiscal Quarter]
	, [Fiscal Quarter Name] = a.[Fiscal Quarter Name]
	, [Fiscal Year] = a.[Fiscal Year]
	, [Fiscal Year Name] = a.[Fiscal Year Name]
	, [Fiscal Month Year] = a.[Fiscal Month Year]
	, [Fiscal MMYYYY] = a.[Fiscal MMYYYY]
	, [Fiscal First Day Of Month] = a.[Fiscal First Day Of Month]
	, [Fiscal Last Day Of Month] = a.[Fiscal Last Day Of Month]
	, [Fiscal First Day Of Quarter] = a.[Fiscal First Day Of Quarter]
	, [Fiscal Last Day Of Quarter] = a.[Fiscal Last Day Of Quarter]
	, [Fiscal First Day Of Year] = a.[Fiscal First Day Of Year]
	, [Fiscal Last Day Of Year] = a.[Fiscal Last Day Of Year]
FROM @tb a
	INNER JOIN [Dimension].[Date] b ON a.PeriodDate = b.[Date]

/*******************************************************************************************************************************************************/
SELECT * From [dimension].[date]
