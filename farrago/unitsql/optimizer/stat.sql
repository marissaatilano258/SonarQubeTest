-- $Id$
-- This script tests statistics generation procedures

!set verbose true

--
-- Setup a link to an empty tpcd schema
--
create schema tpcd;

set schema 'tpcd';

create foreign data wrapper local_file_wrapper
library 'class com.lucidera.farrago.namespace.flatfile.FlatFileDataWrapper'
language java;

create server tpcd_server
foreign data wrapper local_file_wrapper
options (
    directory 'unitsql/optimizer/data/tpcd',
    file_extension 'tbl',
    with_header 'no', 
    log_directory 'testlog');

import foreign schema bcp 
limit to (
    "CUSTOMER","LINEITEM","NATION","ORDERS",
    "PART","PARTSUPP","REGION","SUPPLIER")
from server tpcd_server
into tpcd;


---------------------------------------------------------------------------
-- 1. Fake statistics generation                                         --
--                                                                       --
-- Here we just generate a few data; would need some adjustment          --
-- for usage with actual tpcd queries (column names, generated values)   --
---------------------------------------------------------------------------

--
-- 1.1 Row counts, fine for foreign tables
--
call sys_boot.mgmt.stat_set_row_count('LOCALDB','TPCD','CUSTOMER',15000);
call sys_boot.mgmt.stat_set_row_count('LOCALDB','TPCD','LINEITEM',600572);
call sys_boot.mgmt.stat_set_row_count('LOCALDB','TPCD','NATION',25);
call sys_boot.mgmt.stat_set_row_count('LOCALDB','TPCD','ORDERS',150000);
call sys_boot.mgmt.stat_set_row_count('LOCALDB','TPCD','PART',20000);
call sys_boot.mgmt.stat_set_row_count('LOCALDB','TPCD','PARTSUPP',80000);
call sys_boot.mgmt.stat_set_row_count('LOCALDB','TPCD','REGION',5);
call sys_boot.mgmt.stat_set_row_count('LOCALDB','TPCD','SUPPLIER',1000);

select * from sys_boot.mgmt.row_counts_view order by 1, 2;

--
-- 1.2 Page counts. We can neither index foreign tables or retrieve the 
--     page counts of foreign indexes, so make a dummy table
--
create table dummy_region (
    R_REGIONKEY  INTEGER PRIMARY KEY,
    R_NAME       VARCHAR(25) NOT NULL,
    R_COMMENT    VARCHAR(152));

call sys_boot.mgmt.stat_set_page_count(
    'LOCALDB','TPCD','SYS$CONSTRAINT_INDEX$DUMMY_REGION$SYS$PRIMARY_KEY',1);

select * from sys_boot.mgmt.page_counts_view order by 1, 2, 3;

--
-- 1.3 Column histograms, also fine for foreign tables
--

-- C_CUSTKEY
call sys_boot.mgmt.stat_set_column_histogram(
    'LOCALDB','TPCD','CUSTOMER','F1',15000,10,1500,0,'0123456789');

-- C_NATIONKEY
call sys_boot.mgmt.stat_set_column_histogram(
    'LOCALDB','TPCD','CUSTOMER','F4',25,10,25,0,'ABCDEFGHIJKLMNOPQRSTUVWXYZ');

select * from sys_boot.mgmt.histograms_view order by 1, 2;

-- query the distinct column C_CUSTKEY
select * from sys_boot.mgmt.diffable_histogram_bars 
where "startingValue" < 'A' order by 1, 2;

-- query the low cardinality column C_NATIONKEY
select * from sys_boot.mgmt.diffable_histogram_bars 
where "startingValue" > '99' order by 1, 2;

--
-- 1.4 Update a histogram with more data
--
call sys_boot.mgmt.stat_set_column_histogram(
    'LOCALDB','TPCD','CUSTOMER','F1',15000,100,15000,0,'0123456789');

select * from sys_boot.mgmt.histograms_view order by 1, 2;

select * from sys_boot.mgmt.diffable_histogram_bars 
where "startingValue" < 'A' order by 1, 2;

drop schema tpcd cascade;


---------------------------------------------------------------------------
-- 2. Compute statistics                                                 --
---------------------------------------------------------------------------

create schema stat;
set schema 'stat';

-- create a few tables
create table depts(
    deptno integer not null primary key,
    name varchar(128) not null constraint depts_unique_name unique);

create table emps(
    empno integer not null,
    name varchar(128) not null,
    deptno integer not null,
    gender char(1) default 'M',
    city varchar(128),
    empid integer not null unique,
    age integer,
    public_key varbinary(50),
    slacker boolean,
    manager boolean not null,
    primary key(deptno,empno))
    create index emps_ux on emps(name);

--
-- 2.1 bad catalog name
-- 
-- NOTE: this throws a Java exception, with line numbers apt to change
-- analyze table silly.sales.emps compute statistics for all columns;

--
-- 2.2 empty tables
--
analyze table depts compute statistics for all columns;
analyze table emps compute statistics for columns (empno, name);

select * from sys_boot.mgmt.row_counts_view order by 1, 2;
select * from sys_boot.mgmt.histograms_view order by 1, 2;
select * from sys_boot.mgmt.diffable_histogram_bars order by 1, 2;

--
-- 2.3 loaded tables
--
insert into depts select * from sales.depts;
insert into emps select * from sales.emps;

analyze table depts compute statistics for all columns;
analyze table emps compute statistics for columns (empno, name);

select * from sys_boot.mgmt.row_counts_view order by 1, 2;
select * from sys_boot.mgmt.histograms_view order by 1, 2;
select * from sys_boot.mgmt.diffable_histogram_bars order by 1, 2;

--
-- 2.4 reanalyze
--
insert into emps values
    (130,'Barney',10,'M',null,11,55,null,true,true);

analyze table emps compute statistics for columns (empno, name);

select * from sys_boot.mgmt.row_counts_view order by 1, 2;
select * from sys_boot.mgmt.histograms_view order by 1, 2;
select * from sys_boot.mgmt.diffable_histogram_bars order by 1, 2;

--
-- 2.5 more types
--
analyze table emps compute statistics for all columns;

select * from sys_boot.mgmt.row_counts_view order by 1, 2;
select * from sys_boot.mgmt.histograms_view order by 1, 2;
select * from sys_boot.mgmt.diffable_histogram_bars order by 1, 2;

--
-- 2.6 note: sampling has not been implemented, only test syntax
--
analyze table depts estimate statistics for all columns sample 10 percent;

--
-- 2.7 analyze a foreign table
--
drop schema stat cascade;
create schema stat;
set schema 'stat';

create foreign data wrapper stat_file_wrapper
library 'class com.lucidera.farrago.namespace.flatfile.FlatFileDataWrapper'
language java;

create server stat_server
foreign data wrapper stat_file_wrapper
options (
    directory 'unitsql/med/flatfiles',
    file_extension 'csv',
    with_header 'yes', 
    log_directory 'testlog');

create foreign table stat_file(
    id int not null,
    name varchar(50) not null,
    extra_field char(1) not null)
server stat_server
options (filename 'example');

analyze table stat_file compute statistics for all columns;

select * from sys_boot.mgmt.row_counts_view order by 1, 2;
select * from sys_boot.mgmt.histograms_view order by 1, 2;
select * from sys_boot.mgmt.diffable_histogram_bars order by 1, 2;