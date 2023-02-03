use xxx;



-- data type: timestamp
show global variables like '%timestamp%';
help timestamp;

explicit_defaults_for_timestamp


DROP TABLE IF EXISTS t1;
CREATE TABLE t1 (
  k  VARCHAR(32)				NOT NULL				COMMENT 'XXX',
  n  VARCHAR(32)				DEFAULT NULL		COMMENT 'XXX',
  ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  dt DATETIME  DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY(k)
);

insert into t1(k,n) values('1', 'x');
insert into t1(k,n,ts,dt) values('2','xx',null,null);
insert into t1(k) values('3');

update t1 set n = 'xx' where k='2';
update t1 set n = 'xx' where k='2';
update t1 set n = '__' where k='2';

select * from t1;

select k1,ts from t1 where ts > '2023-02-03 16:22:19';


select current_timestamp();



-- join

DROP TABLE IF EXISTS j1;
CREATE TABLE j1 (
  k  VARCHAR(32)				NOT NULL				COMMENT 'XXX',
  n  VARCHAR(32)				DEFAULT NULL		COMMENT 'XXX',
  PRIMARY KEY(k)
);
DROP TABLE IF EXISTS j2;
CREATE TABLE j2 (
  k2  VARCHAR(32)				NOT NULL				COMMENT 'XXX',
  n2  VARCHAR(32)				DEFAULT NULL		COMMENT 'XXX',
  PRIMARY KEY(k2)
);

insert into j1 values('1','x');
insert into j1 values('2','xx');
insert into j2 values('1','y');
insert into j2 values('2','yy');
insert into j2 values('3','yyy');


select * from j1;

select * from j2;

select j1.*, j2.* from j1 join j2;
select j1.*, j2.* from j1 cross join j2;
select j1.*, j2.* from j1 inner join j2;
select j1.*, j2.* from j1, j2;
select j1.*, j2.* from j1 inner join j2 on j1.k = j2.k2;
select j1.*, j2.* from j1, j2 where j1.k = j2.k2;

select j1.*, j2.* from j1 left join j2 on j1.k = j2.k2;



