-- Now we create the `virtual' tables to be queried.  The 'site'
-- expression is what indicates to each entity that they need to
-- perform MPC to provide the answer to the query

-- Alternatively, these tables can be created implicitly at runtime
-- (i.e. in the query)

DROP TABLE IF EXISTS test_query_1_table;
CREATE TABLE test_query_1_table AS (
    SELECT * FROM mineral_stock WHERE (site = 4 OR site = 7) AND mineral_id = 'Au'
);
