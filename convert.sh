#!/usr/bin/env bash
# sql-convert — run a target/table query against the TrinityCore Master
# database and write the INSERT statements it builds to out/<target>/.
#
#   ./convert.sh <target> <table|all>
#     target   azerothcore | trinitycore335
#     table    a table name (e.g. creature_template), or 'all'
set -euo pipefail
cd "$(dirname "$0")"

# Connection to the TrinityCore Master database; overridable via environment.
DB_HOST="${DB_HOST:-127.0.0.1}"
DB_USER="${DB_USER:-wowserver}"
DB_PASS="${DB_PASS:-wowserver}"
DB_NAME="${DB_NAME:-legion_db}"

target="${1:-}"
table="${2:-all}"

# Rejects an unknown target before touching the database.
if [[ "$target" != "azerothcore" && "$target" != "trinitycore335" ]]; then
  echo "usage: ./convert.sh <azerothcore|trinitycore335> <table|all>" >&2
  exit 1
fi

# Collects the query files to run, in filename order; .preamble.sql is static
# output, not a query, so it is skipped.
shopt -s nullglob
queries=()
if [[ "$table" == "all" ]]; then
  for q in "$target"/[0-9]*.sql; do
    [[ "$q" == *.preamble.sql ]] || queries+=("$q")
  done
else
  for q in "$target"/*_"$table".sql; do
    [[ "$q" == *.preamble.sql ]] || queries+=("$q")
  done
fi
if [[ ${#queries[@]} -eq 0 ]]; then
  echo "no query for table '$table' in '$target/'" >&2
  exit 1
fi

mkdir -p "out/$target"
echo "sql-convert  ${DB_USER}@${DB_HOST}/${DB_NAME}  ->  out/$target/"

for q in "${queries[@]}"; do
  name="$(basename "$q" .sql)"
  out="out/$target/$name.sql"

  # config.sql sets the @-variables; the query's result rows are the INSERT
  # statements. --raw keeps embedded newlines, -N drops the column header.
  result="$(cat config.sql "$q" \
            | MYSQL_PWD="$DB_PASS" mysql -h"$DB_HOST" -u"$DB_USER" \
                  -N --raw --batch "$DB_NAME")"

  # A query may ship a preamble: static SQL the target DB runs before the rows.
  if [[ -f "$target/$name.preamble.sql" ]]; then
    cat "$target/$name.preamble.sql" > "$out"
    printf '\n%s\n' "$result" >> "$out"
  else
    printf '%s\n' "$result" > "$out"
  fi

  count="$(grep -c 'INSERT IGNORE' "$out" || true)"
  echo "  $name  ->  $out  ($count statements)"
done
