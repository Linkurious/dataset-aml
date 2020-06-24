# AML Dataset implementation guide
Brief introduction here.

### Prerequisites:
- a  Neo4j 3.5.x server with read/write access
- APOC procedures are enabled in Neo4j (link goes here)
- a  Linkurious Enterprise 2.9.x server with admin access

## Topics:

1. [Importing the data in Neo4j](#1-importing-the-data-in-neo4j)

2. [Adding the datasource in Linkurious Enterprise](#2-adding-the-datasource-in-linkurious-enterprise)

3. [Setting default styles](#3-setting-default-styles)

4. [Setting default captions](#4-setting-default-captions)

5. [Setting queries](#5-setting-queries)

6. [Setting alerts](#6-setting-alerts)

7. [Setting custom actions](#7-setting-custom-actions)

8. [Setting the plugin](#8-setting-the-plugin)

## 1. Importing the data in Neo4j

1. Login to Neo4j Browser with an user having read/write access

2. Enable, if it's not, the `Enable multi statement query editor` option (you can find it in the `Browser settings` panel).\
\
![](assets/img/IMG_01_small.png)

3. Copy the whole content of the `scripts/import.cypher` file and paste it in the Neo4j query field.

4. Run the query and wait.

5. *(Optional)* If you want to check the import results, just run `:sysinfo` as a query and confront the number of nodes/edges with the following table:\
\
![](assets/img/IMG_02.png)

6. Done!



## 2. Adding the datasource in Linkurious Enterprise

1. Open Linkurious Enterpise with an user having admin access.

2. Go to `Admin` -> `Data source management` and click on `ADD A DATA SOURCE`.

3. Fill these fields with the following values:
> GRAPH SERVER
> - **Name**: AML
> - **Vendor**(Graph Server section): Neo4j
> - **URL**: *\<url:port>* (a stable idenfier for your Neo4j server)
> - **Username**: *\<yourUsername\>* (your Neo4j read/write user)
> - **Password**: *\<yourPassword\>* (your Neo4j read/write password)

>Other
> - **Alternative node ID**: uid
> - **Alternative edge ID**: uid

>SEARCH INDEX SERVER
> - **Vendor**: Neo4j Search

4. Click on `SAVE CONFIGURATION`.

5. Start the indexing process by pressing `START` and wait.

6. Done!

## 3. Setting default styles
Instructions here

## 4. Setting default captions
Instructions here

## 5. Setting queries
Instructions here

## 6. Setting alerts
Instructions here

## 7. Setting custom actions
Instructions here

## 8. Setting the plugin
Instructions here