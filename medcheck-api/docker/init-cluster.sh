#!/bin/sh
set -eu

HOST="roach1:26257"
DB_NAME="medcheck"
CLUSTER_NAME="medcheck-cluster"

echo "[init] Waiting for CockroachDB nodes..."
until cockroach init --insecure --cluster-name="$CLUSTER_NAME" --host="$HOST" >/tmp/cockroach-init.log 2>&1; do
  if grep -qi "already" /tmp/cockroach-init.log; then
    break
  fi
  sleep 2
done

echo "[init] Cluster initialized."

echo "[init] Waiting for SQL availability..."
until cockroach sql --insecure --host="$HOST" --execute="SELECT 1" >/dev/null 2>&1; do
  sleep 2
done

echo "[init] Ensuring database exists..."
cockroach sql --insecure --host="$HOST" --execute="CREATE DATABASE IF NOT EXISTS ${DB_NAME};"

echo "[init] Cluster ready. Apply the private database schema separately before using the API."
