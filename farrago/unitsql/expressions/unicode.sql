-- $Id$
-- Test Unicode data

create schema uni;

-- should fail:  unknown character set
create table uni.t1(
i int not null primary key, v varchar(10) character set "SANSKRIT");

-- should fail:  valid SQL character set, but not supported by Farrago
create table uni.t2(
i int not null primary key, v varchar(10) character set "UTF32");

-- should fail:  valid Java character set, but not supported by Farrago
create table uni.t3(
i int not null primary key, v varchar(10) character set "UTF-8");

-- should succeed:  standard singlebyte
create table uni.t4(
i int not null primary key, v varchar(10) character set "ISO-8859-1");

-- should succeed:  alias for ISO-8859-1
create table uni.t5(
i int not null primary key, v varchar(10) character set "LATIN1");

insert into uni.t5 values (1, 'hi');

select cast(v as varchar(1) character set "LATIN1") from uni.t5;

-- should succeed:  2-byte Unicode
create table uni.t6(
i int not null primary key, v varchar(10) character set "UTF16");

insert into uni.t6 values (1, _UTF16'hi');

select * from uni.t6;

select cast(v as varchar(1) character set "UTF16") from uni.t6;

-- should fail:  unknown character set
select cast(v as varchar(1) character set "SANSKRIT") from uni.t6;

-- FIXME:  single-byte to double-byte currently crashes in Fennel
-- select cast(v as varchar(1) character set "UTF16") from uni.t5;

-- FIXME:  double-byte to single-byte currently crashes in Fennel
-- select cast(v as varchar(1) character set "LATIN1") from uni.t6;