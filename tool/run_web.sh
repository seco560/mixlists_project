#!/usr/bin/env bash
# Wrapper for `flutter run -d chrome` that makes sure the sqflite_common_ffi_web
# assets (web/sqlite3.wasm, web/sqflite_sw.js) exist before launching, since the
# app won't be able to open its database on web without them.
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ ! -f web/sqlite3.wasm || ! -f web/sqflite_sw.js ]]; then
  echo "sqflite web assets missing, generating them..."
  dart run sqflite_common_ffi_web:setup
fi

flutter run -d chrome "$@"
