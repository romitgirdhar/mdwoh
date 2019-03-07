
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

