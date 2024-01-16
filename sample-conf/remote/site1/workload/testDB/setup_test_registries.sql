-- This file contains tables constructed after the tables defined in
-- the schema have been populated with data.  The idea is that the
-- queries in this file are the 'local' computation performed by each
-- remote site before the computationally-expensive MPC.

-- The structure of the tables in this file should be defined in
-- test_schema.sql since the broker must know the structure so that
-- they can be used in queries.  The broker's tables are empty before
-- the online query is run.

DROP TABLE IF EXISTS test_query_1_table;
CREATE TABLE test_query_1_table AS (
    SELECT * FROM mineral_stock WHERE (site = 4 OR site = 7) AND mineral_id = 'Au'
);
