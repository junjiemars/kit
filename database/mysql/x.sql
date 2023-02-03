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


