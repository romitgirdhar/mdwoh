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

orders = spark.read.format("csv").options(inferSchema='true', header='true').load("/mnt/raw/orders")