# AML Dataset implementation guide
Brief introduction here.

### Prerequisites:
- a  Neo4j 3.5.x server with read/write access
- APOC procedures are enabled in Neo4j (link goes here)
- a  Linkurious Enterprise 2.9.x server with admin access

## Topics:

1. [Importing the data in Neo4j](#importing-the-data-in-neoj)

2. Adding the datasource in Linkurious Enterprise

3. Setting default styles

4. Setting default captions

5. Setting queries

6. Setting alerts

7. Setting custom actions

8. Setting the plugin

## 1. Importing the data in Neo4j

1. Login to Neo4j Browser with a user having read/write access

2. Enable, if it's not, the `Enable multi statement query editor` option (you can find it in the `Browser settings` panel).\
\
![](assets/img/IMG_01_small.png)

3. Copy the whole content of the `scripts/import.cypher` file and paste it in the Neo4j query field.

4. Run the query and wait

5. *(Optional)* If you want to check the import results, just run `:sysinfo` as a query and confront the number of nodes/edges with the following table:\
\
![](assets/img/IMG_02.png)

6. Done!



## 2. Adding the datasource in Linkurious Enterprise
Instructions here

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