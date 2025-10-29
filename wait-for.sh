#!/bin/sh
# wait-for.sh — waits for MySQL to be ready

set -e

host="$1"
shift

echo "Waiting for MySQL at $host..."

until mysqladmin ping -h "$host" --silent; do
  >&2 echo "MySQL is unavailable - sleeping"
  sleep 2
done

>&2 echo "MySQL is up - executing command"
exec "$@"
