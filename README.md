# SMCQL Experiment
This repository contains an example application of
[SMCQL](https://github.com/smcql/smcql) developed by Johes Bater.  If
you use this experiment for research, please consider citing the
original paper [[1](#references)].

This code is for research and demonstration purposes only and is
**not** suitable for use in production.

## Experiment Overview
In SMCQL, clients can query data held by two organisations in their
own private databases according to a public schema, via a broker
assumed to be honest.  The query response is returned as if all data
were contained in a single unified database, but SMCQL guarantees that
the broker learns nothing about data held by each organisation
individually beyond what can be deduced by the result of the query,
and that the organisations do not learn anything about each other's
data.

Functionally, the broker decomposes the client's query in a specific
way, compiles from it bytecode to enable SMC, and runs this code over
SSH on the remote systems.  The bytecode enables the remote sites to
perform SMC and return the result to the broker.  Details can be found
in the paper [[1](#references)].

Two different setups are provided:
- **Local**: A single docker container contains a broker and two 'remote'
  databases (all simulated on localhost).  This example is close to
  the one provided in the SMCQL repository.
- **Remote**: Three docker containers, one containing the honest
  broker, and the other two containing a database to be queried by the
  broker.  Each database (one for the broker, and one for each site)
  and the corresponding data are entirely separate, emulating a real
  use case.

## General Configuration
The `sample-conf` directory contains versions of the `conf` directory
from the SMCQL repo for each entity in the experiment: e.g.,
`./sample-conf/local/` is the configuration directory `conf` from the
original repo (used for the local experiment in this repo), with
anything irrelevant for the experiment removed: in the SMCQL repo, the
`conf` directory contains all data for both test sites, but in
'reality' this information should not be accessible to both sites and
the broker.

### Databases
All databases must share the same schema, defined in
`conf/workload/testDB/test_schema.sql`.  Databases in the SMCQL
experiments are:
- `smcql_testDB`: The broker's local database.
- `smcql_testDB_site1`: Site 1's database, which is accessed by the
  broker at runtime.
- `smcql_testDB_site2`: Site 2's database, which is accessed by the
  broker at runtime.

The databases are created via the
`conf/workload/testDB/create_test_dbs.sh` script that runs as part of
the `setup.sh` script.  It performs the following processing:
- Executes `test_schema.sql` to create the same set of (empty) tables
  in `smcql_testDB`, `smcql_testDB_site1` and `smcql_testDB_site2`.
  More specifically, the `test_schema.sql` file defines:
  - Table structure (i.e. column headers and types).
  - Permissions on the rows as public, protected or private (see
    [Queries](#queries) for more details).  If a row's permissions are not set in
    this file, they default to 'private' and cannot be queried.
- Populates the `smcql_testDB_site1` and `smcql_testDB_site2`
  databases using CSV files in the
  `sample-conf/local/workload/testDB/1` and
  `sample-conf/local/workload/testDB/2` directories for the local
  experiment, and `sample-conf/remote/site1/workload/testDB/1` and
  `sample-conf/remote/site1/workload/testDB/2` for the remote
  experiment.
- Executes `setup_test_registries.sql` to populate 'query tables' that
  are used for runtime queries.  Their structure must be defined in
  the `test_schema.sql` file since the broker must know their
  structure, but their content (for each site) is populated in the
  `create-test-dbs.sh` script.  The reason for creating tables for
  specific queries in this file is to minimise the amount of
  computation that is done in SMC (which is several of orders of
  magnitude more expensive than computing in the clear).  For example,
  `WHERE` clauses are not supported as SMCQL queries because they can
  generally be avoided by locally refining the tables on which the
  SMCQL queries will be run.

**NOTE** It is mandated that there be a 'site' table in each of the
site databases, containing a single, unique `site_id` entry.  This
table is used internally by SMCQL.  Additionally, where tables owned
by different sites are aggregated during SQL queries later (e.g. where
selecting all rows from either site where some predicate holds), the
tables must contain a `site` column.

The databases can be inspected by entering the container (e.g. with
`docker exec -it smcql_site1 bash`), changing to the `postgres` user
and running `psql`:

```bash
sudo su - postgres
psql -d smcql_testDB_site1
> \dt
> SELECT * FROM <table name>
```

### Queries
By default, queries are stored in the
`sample-conf/remote/broker/workload/sql` directory (or the
`sample-conf/local/worksload/sql` directory for the local experiment).
Queries can be made to obtain information on:
- Public attributes;
- Aggregated values on protected attributes provided the compiler
  decides there is sufficient privacy in revealing the information;
- Nothing that depends on private attributes.

See notes in subsection above on the contraints on SMCQL queries.

## Building 
Run `./build.sh` to build the docker images.  (Note that running the
`start.sh` script will initiate the build.)  The script builds two
images:
- `smcql`: Used to create containers for the local experiment and for
  the broker in the remote experiment.
- `smcql_remote`: Used to create containers for the remote sites in
  the remote experiment.

The remote sites essentially just need to run a Java
Runtime Environment and a host a database, whereas the broker also
needs to be able to 'compile' SQL queries into SMC executables.

Inside the container, there is a user called `smcql` (who has `sudo`
privileges).  In the broker container, the home directory of the SMCQL
user contains a copy of the SMCQL repository.  

All commands below should be run from within the repository's root
directory, i.e. `/home/smcql/smcql`, from either the local container
(in the local experiment) or the broker container (in the remote
experiment).

The `smcql` user is also a superuser (in both container types) for the
purpose of managing databases.

For simplicity (and because this is just a test experiment), the
`smcql` user has password `smcql` wherever a password is required for
the user (e.g. in the postgres databases).

## Local Experiment
To run this experiment, perform the following steps:
- Run `./start.sh local`.
- Run `docker exec -it smcql_local bash` to enter the container.
- Run `./build_and_execute.sh ./conf/workload/sql/test_query_1.sql
testDB1 testDB2` to run the query `test_query_1.sql`.

## Remote Experiment
The `docker-compose-remote.yml` file creates three containers:
- `smcql_broker`: The honest broker
- `smcql_site1`: Site 1 hosting its database
- `smcql_site2`: Site 2 hosting its database

SSH access is set up from the broker to the remote sites in the
`start.sh` script.

To run this experiment, perform the following steps:
- Run `./start.sh remote`.
- Run `docker exec -it smcql_broker bash` to enter the broker
  container.
- Run `./build_and_execute.sh ./conf/workload/sql/test_query_1.sql
testDB1 testDB2` to run the query `test_query_1.sql`.

## Creating New Experiments
The `setup.sh` script must be run in each of the three containers
(located at `/home/smcql/smcql`) following any changes to:
- The database schema defined in
`sample-conf/*/workload/testDB/test_schema.sql` (which must be the
same for all entities);
- The dynamic query tables constructed in `setup_test_registries.sql`;
  or
- The CSV files containing table data.

# Troubleshooting
- The 'Auth Cancel' error is due to invalid SSH keys.  You can try
  regenerating them in the broker and copying them manually to each
  site using `ssh-copy-id`.
- When running an SMCQL query, if you get an 'array out of bounds'
  exception, then you have requested an SQL query that SMCQL cannot
  parse.  For example, this could be because it contains a `WHERE`
  clause (see notes in the [Databases](#databases) section on how to
  get around this)

# Known Issues
## Config issue
The SMCQL library says that for a remote version, the `testDB1` option
should be replaced with `remoteDB1` (and similarly `testDB1` with
`remoteDB2`).  The choice between `testDB1` and `remoteDB1` apparently
only indicates to the software whether it should read `setup.local` or
`setup.remote`, and in particular does NOT correspond to the names of
the connections in the files under the `connections` directory -- the
files in those directories should always refer to `testDB1` and
`testDB2`.  The `remoteDB1` value on the command line tells the
software to use the `remote-hosts` file to find the configuration,
instead of the `localhosts` file.  However, it appears that rewriting
the `setup.local` `testDB1` and `testDB2` connection configuration
with remote information is the only way to force the software to use
remote databases -- the configuration from the `setup.remote` file
does not seem to be read in correctly even when the command line
arguments state to use `remoteDB1` and `remoteDB2`.  (This appears to
be tracked as Issue \#[4](https://github.com/smcql/smcql/issues/4) in
the SMCQL repo.)

In other words, the files are used as follows:
- In the Local experiment:
  - `sample-conf/broker/connections/localhosts` tells the broker
    connection information for the **local** site hosts.
- In the Remote experiment:
  - `sample-conf/broker/connections/localhosts` tells the broker
    connection information for the **remote** site hosts
- `sample-conf/broker/connections/remote-hosts` is not used.

# References
[1] SMCQL: Secure Query Processing for Private Data Networks, Johes
Bater, Gregory Elliott, Craig Eggen, Satyender Goel, Abel N Kho, and
Jennie Rogers, Proceedings for VLDB Endow, 10(7) pp.673-684.
