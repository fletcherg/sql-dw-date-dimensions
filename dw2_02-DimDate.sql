--
-- Create date dimension
--

IF Exists(Select Name from sysobjects where name = 'dimension.date')
BEGIN
    Drop Table dimension.date
END
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
    Dateid int,
    Date date,
    DateString varchar(10),
	DateStringUS varchar(10),
    CalendarDay int,
    CalendarDayofYear int,
    CalendarDayofWeek int,
    CalendarDayofWeekName varchar(10),
	CalendarDayofWeekNameShort varchar(3),
    CalendarWeek int,
    CalendarMonth int,
    CalendarMonthName varchar(10),
	CalendarMonthNameShort varchar(3),
    CalendarQuarter int,
    CalendarYear int,
    CalendarIsWeekend bit,
    CalendarIsLeapYear bit
)
 
-- Declare and set variables for loop
Declare
@StartDate datetime,
@EndDate datetime,
@Date datetime
 
Set @StartDate = '2000/01/01'
Set @EndDate = '2020/12/31'
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
    INSERT Into dimension.date
    (
	[Dateid],
    [Date],
    [DateString],
	[DateStringUS],
    [CalendarDay],
    [CalendarDayofYear],
    [CalendarDayofWeek],
    [CalendarDayofWeekName],
	[CalendarDayofWeekNameShort],
    [CalendarWeek],
    [CalendarMonth],
    [CalendarMonthName],
	[CalendarMonthNameShort],
    [CalendarQuarter],
    [CalendarYear],
    [CalendarIsWeekend],
    [CalendarIsLeapYear]
    )
    Values
    (
	CONVERT(VARCHAR,@Date,112),
    @Date,
    CONVERT(varchar(10), @Date, 103),
	CONVERT(varchar(10), @Date, 101),
    Day(@Date),
    DATEPART(dy, @Date),
    DATEPART(dw, @Date),
    DATENAME(dw, @Date),
	FORMAT(@date,'ddd'),
    DATEPART(wk, @Date),
    DATEPART(mm, @Date),
    DATENAME(mm, @Date),
	FORMAT(@date,'MMM'),
    DATENAME(qq, @Date),
    Year(@Date),
    @IsWeekend,
    @IsLeapYear
    )
 
    -- Goto next day
    Set @Date = @Date + 1
END
GO