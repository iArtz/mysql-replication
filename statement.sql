-- @block create table Master
-- @conn Legacy
create table if not exists code(code int);
-- @block insert values to code table Master
-- @conn Legacy
insert into code
values(100),
  (200);
-- @block select data from code table Master
-- @conn Legacy
select *
from code;
-- @block create table Master
-- @conn Cloud
create table if not exists code(code int);
-- @block select data from code table Slave
-- @conn Cloud
select *
from code;
-- @block insert values to code table Slave
-- @conn Cloud
INSERT INTO code
VALUES(300),
  (400);
-- @block drop code table on legacy
-- @conn Legacy
DROP TABLE IF EXISTS code;
-- @block create DATABASE
-- @conn Legacy
CREATE DATABASE repl;