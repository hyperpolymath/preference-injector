#!/bin/bash
# SPDX-License-Identifier: MPL-2.0

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT

mkdir -p \
  "$fixture/scripts" \
  "$fixture/src/rescript/providers" \
  "$fixture/src/rescript/crdt" \
  "$fixture/tests/rescript"
cp "$repo_root/scripts/rsr-verify.sh" "$fixture/scripts/"
cp "$repo_root/scripts/rsr-capability-evidence.tsv" "$fixture/scripts/"

write_declaration_only() {
  local path=$1
  local module=$2

  printf 'module %s;\n\n// TODO: implement\n' "$module" > "$path"
}

write_declaration_only "$fixture/src/rescript/providers/FileProvider.affine" FileProvider
write_declaration_only "$fixture/src/rescript/crdt/LWWMap.affine" LWWMap
write_declaration_only "$fixture/src/rescript/crdt/Merge.affine" Merge
write_declaration_only "$fixture/tests/rescript/Provider_test.affine" Provider_test
write_declaration_only "$fixture/tests/rescript/CRDT_test.affine" CRDT_test

git -C "$fixture" init -q
git -C "$fixture" add .

offline_result() {
  (cd "$fixture" && bash scripts/rsr-verify.sh) |
    sed -n '/3. Offline-First/,/4. Documentation/p'
}

assert_contains() {
  local output=$1
  local expected=$2

  if [[ "$output" != *"$expected"* ]]; then
    printf 'Expected output to contain: %s\nActual output:\n%s\n' "$expected" "$output" >&2
    exit 1
  fi
}

result=$(offline_result)
assert_contains "$result" '❌ Bronze: 0/50 points'
assert_contains "$result" '⚠️  Silver: 0/30 points (CRDT sync)'

printf 'module FileProvider;\nlet load = (path) => readPreferences(path);\n' \
  > "$fixture/src/rescript/providers/FileProvider.affine"
result=$(offline_result)
assert_contains "$result" '❌ Bronze: 0/50 points'

printf 'module Provider_test;\ntype Fixture = { path: String };\n' \
  > "$fixture/tests/rescript/Provider_test.affine"
result=$(offline_result)
assert_contains "$result" '❌ Bronze: 0/50 points'

printf 'module Provider_test;\ntestProviderLoadsOffline();\n' \
  > "$fixture/tests/rescript/Provider_test.affine"
result=$(offline_result)
assert_contains "$result" '✅ Bronze: 50/50 points'

printf 'module LWWMap;\nlet merge = (left, right) => mergeEntries(left, right);\n' \
  > "$fixture/src/rescript/crdt/LWWMap.affine"
result=$(offline_result)
assert_contains "$result" '⚠️  Silver: 0/30 points (CRDT sync)'

printf 'module Merge;\nlet converge = (replicas) => mergeAll(replicas);\n' \
  > "$fixture/src/rescript/crdt/Merge.affine"
result=$(offline_result)
assert_contains "$result" '⚠️  Silver: 0/30 points (CRDT sync)'

printf 'module CRDT_test;\ntestReplicasConvergeAfterConcurrentWrites();\n' \
  > "$fixture/tests/rescript/CRDT_test.affine"
result=$(offline_result)
assert_contains "$result" '✅ Silver: 30/30 points'

printf 'rsr-verify capability evidence tests passed\n'
