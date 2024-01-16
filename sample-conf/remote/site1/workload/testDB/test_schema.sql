-- Test DB configuration
\set site1 4
\set site2 7

DROP TABLE IF EXISTS site;
CREATE TABLE site (
       id integer);

-- This table must have a 'site' value since in the 'virtual'
-- aggregated database, there must be a way of determining which stock
-- value corresponds to which site
DROP TABLE IF EXISTS mineral_stock;
CREATE TABLE mineral_stock (
  site integer NOT NULL,
  mineral_id character varying NOT NULL,
  mass_in_storage integer NOT NULL
);

DROP TABLE IF EXISTS shipments;
CREATE TABLE shipments (
  site integer NOT NULL,
  shipment_id integer NOT NULL,
  shipment_year integer NOT NULL,
  shipment_month integer NOT NULL,
  origin character varying NOT NULL
);

DROP TABLE IF EXISTS shipment_content;
CREATE TABLE shipment_content (
  shipment_id integer NOT NULL,
  mineral_id character varying NOT NULL,
  mass_delivered integer NOT NULL
);

-- Tables for test queries.  Their structure should be defined here as
-- the broker needs to know their structure, and this file should be
-- common to all parties.  The content of the tables is populated in
-- the setup_test_registries.sql file.  Note that if the online query
-- dynamically defines a table, it does not need to be defined here.
DROP TABLE IF EXISTS test_query_1_table;
CREATE TABLE test_query_1_table AS (
    SELECT * FROM mineral_stock WHERE (site = :site1 OR site = :site2)
);

-- Roles
CREATE ROLE public_attribute;
CREATE ROLE protected_attribute;

-- Attribute permissions
GRANT SELECT(site) ON test_query_1_table TO public_attribute;
GRANT SELECT(mineral_id) ON test_query_1_table TO public_attribute;
GRANT SELECT(mass_in_storage) ON test_query_1_table TO protected_attribute;

GRANT SELECT(mineral_id) ON mineral_stock TO public_attribute;
GRANT SELECT(mass_in_storage) ON mineral_stock TO protected_attribute;

GRANT SELECT(site) ON shipments TO public_attribute;
GRANT SELECT(shipment_id) ON shipments TO public_attribute;
GRANT SELECT(shipment_year) ON shipments TO protected_attribute;
GRANT SELECT(shipment_month) ON shipments TO protected_attribute;
GRANT SELECT(origin) ON shipments TO protected_attribute;

GRANT SELECT(shipment_id) ON shipment_content TO public_attribute;
GRANT SELECT(mineral_id) ON shipment_content TO public_attribute;
GRANT SELECT(mass_delivered) ON shipment_content TO protected_attribute;
