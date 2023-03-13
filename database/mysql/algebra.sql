--
DROP DATABASE IF EXISTS algebra;
CREATE DATABASE IF NOT EXISTS algebra;
USE algebra;



-- t1, t2
drop table if exists t1, t2;
create table t1 (x int, y varchar(8));
create table t2 (x int, y varchar(8));

insert into t1 values row(1,'A'),row(2,'B'),row(3,'C'),row(4,'D');
insert into t2 values row(1,'A'),row(3,'C');


-- set union

select * from t1
union
select * from t2
;

-- set difference: t1 - t2

select * from t1
where (x, y) not in (select * from t2);

select * from t1
where not exists (select 1 from t2 where t2.x = t1.x and t2.y = t1.y)
;

select * from t1
left join t2 using (x, y)
where t2.x is null
;

-- intersection

select * from t1 where (x, y) in (select * from t2);

select * from t1
inner join t2 using (x, y)
;

select * from t1
intersect
select * from t2
;


-- cartesion-product

drop table if exists r, s;
create table r (A varchar(4), B int);
create table s (C varchar(4), D int, E varchar(4));

insert into r values row('α',1),row('β',2);

insert into s values row('α',10,'a'),row('β',10,'a'),
row('β',20,'b'),row('γ',10,'b')
;

select * from r, s order by r.a;




-- division
