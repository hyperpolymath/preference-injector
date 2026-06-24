<!--
SPDX-License-Identifier: CC-BY-SA-4.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->
# TEST-NEEDS.md — preference-injector

## CRG Grade: C — ACHIEVED 2026-04-04

## Current Test State

| Category | Count | Notes |
|----------|-------|-------|
| ReScript unit tests | 2 | `tests/rescript/{Injector,Validator}_test.res` |
| Test framework | Present | ReScript built-in testing |
| CI pipeline | Present | `.gitlab-ci.yml` and Bitbucket integration |

## What's Covered

- [x] ReScript unit test suite
- [x] Injector validation tests
- [x] Validator logic tests
- [x] CI integration (GitLab, Bitbucket)

## Still Missing (for CRG B+)

- [ ] Property-based testing
- [ ] Integration tests with Nickel config
- [ ] Performance benchmarks
- [ ] End-to-end preference flow tests

## Run Tests

```bash
cd /var/mnt/eclipse/repos/preference-injector && rescript build && npm test
```
