#!/bin/bash
set -e

echo "[*] Running database migrations..."
./rebecca-cli migrate up

echo "[*] Starting Rebecca Server..."
exec ./rebecca-server
