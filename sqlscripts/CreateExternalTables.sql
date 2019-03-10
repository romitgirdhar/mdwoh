
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'P0pc0rn4ndC0k3!';

CREATE DATABASE SCOPED CREDENTIAL msi_cred WITH IDENTITY = 'Managed Service Identity';

CREATE EXTERNAL DATA SOURCE ext_datasource_with_abfss 
	WITH (TYPE = hadoop, LOCATION = 'abfss://conformed@adlg2team4southridge.dfs.core.windows.net', CREDENTIAL = msi_cred);

CREATE EXTERNAL FILE FORMAT parquetfile1  
WITH (  
    FORMAT_TYPE = PARQUET  
);

-- ORDERS
CREATE EXTERNAL TABLE ExtOrders(   
    OrderID nvarchar(max), 
	CustomerID nvarchar(max), 
	OrderDate datetime, 
	TotalCost float, 
	CreatedDate datetime, 
	UpdatedDate datetime, 
	ShipDate datetime, 
	OriginSystem nvarchar(max), 
	SaleType nvarchar(max) 
)  
WITH (  
        LOCATION='/orders',  
        DATA_SOURCE = ext_datasource_with_abfss,  
        FILE_FORMAT = parquetfile1  
    )  
;  

--CUSTOMERS
CREATE EXTERNAL TABLE ExtCustomers(   
	CustomerID nvarchar(max), LastName nvarchar(max), FirstName nvarchar(max), PhoneNumber BIGINT, CreatedDate datetime, UpdatedDate datetime, OriginSystem nvarchar(max)
)  
WITH (  
        LOCATION='/customers',  
        DATA_SOURCE = ext_datasource_with_abfss,  
        FILE_FORMAT = parquetfile1  
    )  
;  
-- ADDRESSES
CREATE EXTERNAL TABLE ExtAddresses(   
	AddressID nvarchar(max), CustomerID nvarchar(max), AddressLine1 nvarchar(max), AddressLine2 nvarchar(max), City nvarchar(max), State nvarchar(max), ZipCode INT, CreatedDate datetime, UpdatedDate datetime	
)  
WITH (  
        LOCATION='/addresses',  
        DATA_SOURCE = ext_datasource_with_abfss,  
        FILE_FORMAT = parquetfile1  
    )  
;  

-- ORDER DETAILS

-- `OrderDetailID` STRING, `OrderID` STRING, `MovieID` STRING, `Quantity` INT, `UnitCost` DOUBLE, `LineNumber` INT, `CreatedDate` TIMESTAMP, `UpdatedDate` TIMESTAMP
CREATE EXTERNAL TABLE ExtOrderDetails(   
	OrderDetailID nvarchar(max), OrderID nvarchar(max), MovieID nvarchar(max), Quantity INT, UnitCost float, LineNumber INT, CreatedDate datetime, UpdatedDate datetime
)  
WITH (  
        LOCATION='/orderdetails',  
        DATA_SOURCE = ext_datasource_with_abfss,  
        FILE_FORMAT = parquetfile1  
    )  
;  


select top 10 * from ExtAddresses
select top 10 * from ExtCustomers
select top 10 * from ExtOrderDetails
select top 10 * from ExtOrders


-- date
-- customers
-- location
-- movies 


create table DimDate (
	DateSK int not null identity(1,1) ,
	DateValue datetime ,--INDEX IX_DV NONCLUSTERED,
	DateYear smallint,
	DateMonth smallint,
	DateDay  smallint,
	DateDayOfWeek smallint,
	DateDayOfYear smallint,
	DateWeekOfYear smallint

)
WITH 
( DISTRIBUTION = HASH(DateValue),
  CLUSTERED COLUMNSTORE INDEX
 )


 
create table DimCustomers (
	CustomerSK int not null identity(1,1) ,
	CustomerID uniqueidentifier,
	LastName nvarchar(100),
	FirstName nvarchar(100),
	AddressLine1 nvarchar(100),
	AddressLine2 nvarchar(100),
	City nvarchar(100),
	State nvarchar(2),
	ZipCode nvarchar(5),
	PhoneNumber nvarchar(10),
	RecordStartDate datetime,
	RecordEndDate datetime,
	ActiveFlag bit 
)
WITH 
( DISTRIBUTION = HASH(CustomerID),
  CLUSTERED COLUMNSTORE INDEX
 )


 create table DimMovies (
	MovieSK int not null identity(1,1) ,
	MovieID uniqueidentifier,
	MovieTitle nvarchar(255),
	MovieRunTimeMin int
)
WITH 
( DISTRIBUTION = HASH(MovieID),
  CLUSTERED COLUMNSTORE INDEX
 )


create table FactSales (
	SalesSK int not null identity(1,1) ,
	OrderID uniqueidentifier,
	LineNumber smallint,
	OrderDateSK int,
	ShipDateSK int,
	CustomerSK int,
	LocationSK int,
	MovieSK int,
	DaysToShip smallint,
	Quantity smallint,
	UnitCost float,
	ExtendedCost float
)
WITH 
( DISTRIBUTION = HASH(OrderID),
  CLUSTERED COLUMNSTORE INDEX
 )


 insert into DimCustomers  select distinct ec.customerID, ec.LastName, ec.FirstName , ea.AddressLine1, ea.AddressLine2
	, ea.City, ea.State, ea.ZipCode, ec.PhoneNumber, '','',1
 from 
 ExtCustomers ec
	 inner join ExtAddresses ea
	 on ec.CustomerID = ea.CustomerID

	 insert into DimMovies (MovieID) select distinct MovieID from ExtOrderDetails

	 insert into DimDate (DateValue) 
	 select Count( distinct a.uDate ), count(*)
	 from 
	(	 select distinct ShipDate as uDate from ExtOrders
		 UNION
		 select distinct OrderDate uDate from ExtOrders
	) a

	insert into FactSales

	select eo.OrderID, eod.LineNumber, od1.DateSK, sd1.DateSK, dc.CustomerSK, ''
		, dm.MovieSK, 0, eod.Quantity, eod.UnitCost, (eod.UnitCost*eod.Quantity)
	from ExtOrders eo
		inner join ExtOrderDetails eod on eo.OrderID = eod.OrderID 
		left outer join DimDate od1 on eo.OrderDate = od1.DateValue
		left outer join DimDate sd1 on eo.ShipDate = sd1.DateValue
		left outer join DimCustomers dc on eo.CustomerID = dc.CustomerID
		left outer join DimMovies dm on eod.MovieID = dm.MovieID
	where eo.OrderID = 'D4A9508D-EB98-4EC6-8169-0F80FDEA2E35'
	
		select count(*) from ExtOrderDetails


		select count(*) from FactSales


		select count(distinct MovieID) , count(*) from DimMovies
		select count(distinct DateValue), count(*)  from DimDate
		select count(distinct CustomerID) , count(*) from DimCustomers

		select count(distinct MovieID) from DimOrder


	select a.uDate , count(*) as cnt
	 from 
	(	 select distinct ShipDate as uDate from ExtOrders
		 UNION
		 select distinct OrderDate uDate from ExtOrders
	) a
	group by a.UDate
	order by cnt desc


	select OrderID, LineNumber, Count(*) as Cnt
	from FactSales
	group by OrderID, LineNumber
	order by Cnt Desc


-- 	D4A9508D-EB98-4EC6-8169-0F80FDEA2E35

select * from FactSales
where OrderID = 'D4A9508D-EB98-4EC6-8169-0F80FDEA2E35'
	and LineNumber = 1 and MovieSK 


