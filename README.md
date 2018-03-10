# PostgreSQL Hands-On · NICAR 2018 Chicago

## Description
In this session, we cover some lesser-known but incredibly useful features of PostgreSQL, a free, open-source relational database system named 2017 DBMS of the Year by DB-Engines. You’ll learn how to analyze spatial data with PostGIS, automate tasks with triggers, create functions (which can use languages such as Python and R), and discover PostgreSQL’s powerful full-text search engine.

This repo includes data, sample queries, and a [PDF of slides](https://github.com/anthonydb/postgresql-intro-nicar18/blob/master/NICAR-2018-PostgreSQL.pdf). The material is drawn from the more advanced chapters of this author's book [Practical SQL](https://www.nostarch.com/practicalsql). You can find all the code examples and data for the book [here](https://github.com/anthonydb/practical-sql).

## Topics
* A few basic queries
* Stats functions
* Spatial queries with PostGIS
* Full-text search
* Creating functions

## Setup
If you're trying this at home, here's how to get rolling (you will need to have PostgreSQL installed, along with the PostGIS extension).

* Download this repo to your computer.
* To create tables and load data, execute the queries in the file [pg_create_import.sql](https://github.com/anthonydb/postgresql-intro-nicar18/blob/master/pg_create_import.sql) using pgAdmin, the psql command-line tool, or another GUI. Note that you will need to load a Census shapefile using a command-line utility noted at the end of the file.
* You can then run the queries in [pg_demo_queries.sql](https://github.com/anthonydb/postgresql-intro-nicar18/blob/master/pg_demo_queries.sql)
