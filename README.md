# sql-convert

Convert **TrinityCore Master** world data into ready-to-apply SQL for an
older 3.3.5a target — **AzerothCore**, or **TrinityCore 3.3.5**.

Each query is a `SELECT` that reads the TrinityCore Master database and, with
`CONCAT()`, builds the text of the target `INSERT IGNORE` statements — one
result row is one statement. Running a query needs only the TrinityCore
Master database; the statements it produces are self-contained and replay on
the target database with no source database present.

## Layout

    config.sql          Conversion parameters (@map_id, @creature_level, ...).
    azerothcore/        SELECT queries for the AzerothCore target.
    trinitycore335/     SELECT queries for the TrinityCore 3.3.5 target.
    convert.sh          Runs a query against the source DB, writes out/.
    out/                Generated INSERT files, grouped by target.

A query file is `NN_<table>.sql` (`NN` fixes the apply order). An optional
`NN_<table>.preamble.sql` is static SQL prepended to that table's output —
DDL or variables the target database needs before the rows.

## Use

1. Edit `config.sql` — set the map and the per-table options.
2. Set the source-DB connection (environment variables, defaults shown):

       DB_HOST=127.0.0.1  DB_USER=wowserver  DB_PASS=wowserver  DB_NAME=legion_db

3. Convert one table, or all of them:

       ./convert.sh azerothcore creature_template
       ./convert.sh azerothcore all

4. Apply `out/azerothcore/*.sql` on the target database in filename order.

## Targets

`azerothcore` is implemented. `trinitycore335` reserves the same layout for
the TrinityCore 3.3.5 target — its column mapping differs from AzerothCore's,
so the queries are target-specific.
