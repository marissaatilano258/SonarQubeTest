-- $Id$
-- Tests for ConvertMultiJoinRule and OptimizeJoinRule

create schema jo;
set schema 'jo';

-- set session personality to LucidDB so all tables
-- will be column-store by default and LucidDB-specific optimization rules
-- are picked up

-- fake jar since we don't actually build a separate jar for LucidDB yet
create jar luciddb_plugin 
library 'class com.lucidera.farrago.LucidDbSessionFactory' 
options(0);

alter session implementation set jar luciddb_plugin;

create table f(f int, f_d1 int, f_d2 int, f_d3 int);
create table d1(d1 int, d1_f int, d1_d2 int, d1_d3 int);
create table d2(d2 int, d2_f int, d2_d1 int, d2_d3 int);
create table d3(d3 int, d3_f int, d3_d1 int, d3_d2 int);

create index if_d1 on f(f_d1);
create index if_d2 on f(f_d2);
create index if_d3 on f(f_d3);
create index id1_f on d1(d1_f);
create index id1_d2 on d1(d1_d2);
create index id1_d3 on d1(d1_d3);
create index id2_f on d2(d2_f);
create index id2_d1 on d2(d2_d1);
create index id2_d3 on d2(d2_d3);
create index id3_f on d3(d3_f);
create index id3_d1 on d3(d3_d1);
create index id3_d2 on d3(d3_d2);

insert into f values(0, 0, 0, 0);
insert into d1 values(1, 0, 1, 1);
insert into d2 values(2, 0, 1, 2);
insert into d3 values(3, 0, 1, 2);

!set outputformat csv

--------------------------------------------------------------------
-- Test different combinations of patterns into ConvertMultiJoinRule
--------------------------------------------------------------------

-- MJ/MJ
explain plan for select f, d1, d2, d3
    from (select * from f, d1 where f.f_d1 = d1.d1_f) j1,
        (select * from d2, d3 where d2.d2_d3 = d3.d3_d2) j2
    where j1.f_d2 = j2.d2_f;

-- MJ/RS
explain plan for select f, d1, d2
    from (select * from f, d1 where f.f_d1 = d1.d1_f) j, d2
    where j.f_d2 = d2.d2_f;

-- MJ/FRS
explain plan for select f, d1, d2
    from (select * from f, d1 where f.f_d1 = d1.d1_f) j, d2
    where j.f_d2 = d2.d2_f and d2.d2 + 0 = 2;

-- RS/MJ
explain plan for select f, d1, d2
    from f, (select * from d1, d2 where d1.d1_d2 = d2.d2_d1) j
    where f.f_d1 = j.d1_f;

-- RS/RS
explain plan for select f, d1 from f, d1 where f.f_d1 = d1.d1_f;

-- RS/FRS
explain plan for select f, d1 from f, d1
    where f.f_d1 = d1.d1_f and d1.d1 + 0 = 1;

-- FRS/MJ
explain plan for select f, d1, d2
    from f, (select * from d1, d2 where d1.d1_d2 = d2.d2_d1) j
    where f.f_d1 = j.d1_f and f.f + 0 = 0;

-- FRS/RS
explain plan for select f, d1 from f, d1
    where f.f_d1 = d1.d1_f and f.f + 0 = 0;

-- FRS/FRS
explain plan for select f, d1 from f, d1
    where f.f_d1 = d1.d1_f and f.f + 0 = 0 and d1.d1 + 0 = 1;

------------------------------------------------------
-- different join combinations, including corner cases
------------------------------------------------------
-- no join filters
explain plan for select f, d1, d2, d3 
    from f, d1, d2, d3;

-- non-comparsion expression
explain plan for select f, d1 from f, d1
    where f.f_d1 = d1.d1_f or f.f_d2 = d1.d1_f;

-- filter involving > 2 tables
explain plan for select f, d1, d2 from f, d1, d2
    where f.f_d1 + d1.d1_f = d2.d2_f;

-- filter with 2 tables but both on one side of the comparison operator
explain plan for select f, d1 from f, d1
    where f.f_d1 + d1.d1_f = 0;

-- non-equality operator
explain plan for select f, d1 from f, d1
    where f.f_d1 >= d1.d1_f;

-- all possible join combinations
explain plan for select f, d1, d2, d3
    from f, d1, d2, d3
    where
        f.f_d1 = d1.d1_f and f.f_d2 = d2.d2_f and f.f_d3 = d3.d3_f and
        d1.d1_d2 = d2.d2_d1 and d1.d1_d3 = d3.d3_d1 and
        d2.d2_d3 = d3.d3_d2;

------------------------
-- run the queries above
------------------------
!set outputformat table

select f, d1, d2, d3
    from (select * from f, d1 where f.f_d1 = d1.d1_f) j1,
        (select * from d2, d3 where d2.d2_d3 = d3.d3_d2) j2
    where j1.f_d2 = j2.d2_f;

select f, d1, d2
    from (select * from f, d1 where f.f_d1 = d1.d1_f) j, d2
    where j.f_d2 = d2.d2_f;

select f, d1, d2
    from (select * from f, d1 where f.f_d1 = d1.d1_f) j, d2
    where j.f_d2 = d2.d2_f and d2.d2 + 0 = 2;

select f, d1, d2
    from f, (select * from d1, d2 where d1.d1_d2 = d2.d2_d1) j
    where f.f_d1 = j.d1_f;

select f, d1 from f, d1 where f.f_d1 = d1.d1_f;

select f, d1 from f, d1 where f.f_d1 = d1.d1_f and d1.d1 + 0 = 1;

select f, d1, d2
    from f, (select * from d1, d2 where d1.d1_d2 = d2.d2_d1) j
    where f.f_d1 = j.d1_f and f.f + 0 = 0;

select f, d1 from f, d1 where f.f_d1 = d1.d1_f and f.f + 0 = 0;

select f, d1 from f, d1
    where f.f_d1 = d1.d1_f and f.f + 0 = 0 and d1.d1 + 0 = 1;

select f, d1, d2, d3 
    from f, d1, d2, d3;

select f, d1 from f, d1
    where f.f_d1 = d1.d1_f or f.f_d2 = d1.d1_f;

select f, d1, d2 from f, d1, d2
    where f.f_d1 + d1.d1_f = d2.d2_f;

select f, d1 from f, d1
    where f.f_d1 + d1.d1_f = 0;

select f, d1 from f, d1
    where f.f_d1 >= d1.d1_f;

select f, d1, d2, d3
    from f, d1, d2, d3
    where
        f.f_d1 = d1.d1_f and f.f_d2 = d2.d2_f and f.f_d3 = d3.d3_f and
        d1.d1_d2 = d2.d2_d1 and d1.d1_d3 = d3.d3_d1 and
        d2.d2_d3 = d3.d3_d2;
