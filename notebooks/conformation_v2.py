# Databricks notebook source
#Mount the ADLS Gen2 
configs = {"fs.azure.account.auth.type": "OAuth",
           "fs.azure.account.oauth.provider.type": "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider",
           "fs.azure.account.oauth2.client.id": "eb0cd891-c710-40b6-9059-65b226ab3998",
           "fs.azure.account.oauth2.client.secret": dbutils.secrets.get(scope = "t4adbscope", key = "aad-adls-sp"),
           "fs.azure.account.oauth2.client.endpoint":                       "https://login.microsoftonline.com/OTAPRD549ops.onmicrosoft.com/oauth2/token"}

# Optionally, you can add <your-directory-name> to the source URI of your mount point.
dbutils.fs.mount(
  source = "abfss://southbridgeraw@adlg2team4southridge.dfs.core.windows.net/",
  mount_point = "/mnt/raw",
  extra_configs = configs)

dbutils.fs.mount(
  source = "abfss://conformed@adlg2team4southridge.dfs.core.windows.net/",
  mount_point = "/mnt/conformed",
  extra_configs = configs)




# COMMAND ----------

# MAGIC %fs ls /mnt/conformed

# COMMAND ----------

#Process all raw orders
from pyspark.sql.functions import *
from pyspark.sql.types import *
import uuid

uuidUdf = udf(lambda : str(uuid.uuid4()), StringType())

#load southridge orders
sr_orders = spark.read.format("csv").options(inferSchema='true', header='true').load("/mnt/raw/orders")
sr_orders = sr_orders.withColumn(
  "ShipDateTemp", sr_orders.ShipDate.cast(TimestampType())).drop(
  "ShipDate").withColumnRenamed(
  "ShipDateTemp", "ShipDate").withColumn(
  "OriginSystem", lit("southridge")).withColumn(
  "SaleType", lit("sale"))
  
sr_orderdetails = spark.read.format("csv").options(inferSchema='true', header='true').load("/mnt/raw/order details")

def toTimestamp(cName):
 return from_unixtime(unix_timestamp(cName.cast("string"), "yyyyMMdd")).cast("timestamp")

#load vander orders
vander_txs = spark.read.format("csv").options(inferSchema='true', header='true').load("/mnt/raw/raw/vander/Transactions")

vander_orders = vander_txs.select(
  col("TransactionID").alias("OrderID"), 
  col("CustomerID"), 
  toTimestamp(col("RentalDate")).alias("OrderDate"),
  (vander_txs.RentalCost + vander_txs.LateFee).alias("TotalCost"),
  col("CreatedDate"), 
  col("UpdatedDate"),
  toTimestamp(col("RentalDate")).alias("ShipDate"))
  
vander_orders = vander_orders.withColumn("OriginSystem", lit("vander")).withColumn("SaleType", lit("rental"))

vander_rentaldetails = vander_txs.select(
  uuidUdf().alias("OrderDetailsID"), 
  col("TransactionID").alias("OrderID"), "MovieID", 
  lit(1).alias("Quantity"), 
  col("RentalCost").cast(DoubleType()).alias("UnitCost"), 
  lit(1).alias("LineNumber"), 
  "CreatedDate", 
  "UpdatedDate")

vander_latedetails = vander_txs.filter(vander_txs.LateFee>0).select(
  uuidUdf().alias("OrderDetailsID"), 
  col("TransactionID").alias("OrderID"), 
  "MovieID", 
  lit(1).alias("Quantity"), 
  col("LateFee").cast(DoubleType()).alias("UnitCost"), 
  lit(2).alias("LineNumber"), 
  "CreatedDate", 
  "UpdatedDate")

vander_orderdetails = vander_rentaldetails.union(vander_latedetails).orderBy("OrderID", "LineNumber")

#load fourthcoffee orders
fourth_txs = spark.read.format("csv").options(inferSchema='true', header='true').load("/mnt/raw/raw/four coffee/transactions")

fourth_orders = fourth_txs.select(
  col("TransactionID").alias("OrderID"), 
  col("CustomerID"), 
  toTimestamp(col("RentalDate")).alias("OrderDate"),
  (fourth_txs.RentalCost + fourth_txs.LateFee).alias("TotalCost"),
  col("CreatedDate"), 
  col("UpdatedDate"), 
  toTimestamp(col("RentalDate")).alias("ShipDate"))

fourth_orders = fourth_orders.withColumn("OriginSystem", lit("fourth_coffee")).withColumn("SaleType", lit("rental"))

fourth_rentaldetails = fourth_txs.select(
  uuidUdf().alias("OrderDetailsID"), 
  col("TransactionID").alias("OrderID"), 
  "MovieID", 
  lit(1).alias("Quantity"), 
  col("RentalCost").cast(DoubleType()).alias("UnitCost"), 
  lit(1).alias("LineNumber"), 
  "CreatedDate", 
  "UpdatedDate")

fourth_latedetails = fourth_txs.filter(fourth_txs.LateFee>0).select(
  uuidUdf().alias("OrderDetailsID"), 
  col("TransactionID").alias("OrderID"), 
  "MovieID", 
  lit(1).alias("Quantity"), 
  col("LateFee").cast(DoubleType()).alias("UnitCost"), 
  lit(2).alias("LineNumber"), 
  "CreatedDate", 
  "UpdatedDate")

fourth_orderdetails = fourth_rentaldetails.union(fourth_latedetails).orderBy("OrderID", "LineNumber")

#union all 3 data sources
conform_orders=sr_orders.union(vander_orders).union(fourth_orders)
conform_orderdetails=sr_orderdetails.union(vander_orderdetails).union(fourth_orderdetails)

#write out conformed data
conform_orders.write.saveAsTable("c_orders", format='parquet', mode='overwrite', path='/mnt/conformed/orders' )
conform_orderdetails.write.saveAsTable("c_orderdetails", format='parquet', mode='overwrite', path='/mnt/conformed/orderdetails' )


# COMMAND ----------

# MAGIC %sql select * from c_orders o
# MAGIC inner join c_customers c on o.CustomerID = c.CustomerID

# COMMAND ----------

