<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->
<!-- TOPOLOGY.md — Project architecture map and completion dashboard -->
<!-- Last updated: 2026-02-19 -->

# Preference Injector — Project Topology

## System Architecture

```
                        ┌─────────────────────────────────────────┐
                        │              APPLICATION                │
                        │        (Consumer Requesting Prefs)      │
                        └───────────────────┬─────────────────────┘
                                            │ Inject / Query
                                            ▼
                        ┌─────────────────────────────────────────┐
                        │           INJECTOR CORE (RESCRIPT)      │
                        │    (Priority Logic, Conflict Resolutn)  │
                        └──────────┬───────────────────┬──────────┘
                                   │                   │
                                   ▼                   ▼
                        ┌───────────────────────┐  ┌────────────────────────────────┐
                        │ PREFERENCE PROVIDERS  │  │ SECURITY & SYNC                │
                        │ - Memory Provider     │  │ - AES-256-GCM Encryption       │
                        │ - File Provider (JSON)│  │ - Audit Logging                │
                        │ - Env Provider (APP_) │  │ - CRDT Sync (Distributed)      │
                        │ - API Provider (Remote)│ │ - Schema Validation            │
                        └──────────┬────────────┘  └──────────┬─────────────────────┘
                                   │                          │
                                   └────────────┬─────────────┘
                                                ▼
                        ┌─────────────────────────────────────────┐
                        │             RUNTIME (DENO)              │
                        │      (Secure File I/O, API Calls)       │
                        └─────────────────────────────────────────┘

                        ┌─────────────────────────────────────────┐
                        │          REPO INFRASTRUCTURE            │
                        │  Justfile Automation  .machine_readable/  │
                        │  Nickel config (ncl)  0-AI-MANIFEST.a2ml  │
                        └─────────────────────────────────────────┘
```

## Completion Dashboard

```
COMPONENT                          STATUS              NOTES
─────────────────────────────────  ──────────────────  ─────────────────────────────────
CORE INJECTOR
  Priority System                   ██████████ 100%    Conflict resolution verified
  ReScript Type Safety              ██████████ 100%    Exhaustive pattern matching active
  Caching (LRU/TTL)                 ████████░░  80%    Performance tuning refining
  Validation (Schema-based)         ██████████ 100%    Type-safe rules verified

PROVIDERS & SYNC
  Memory / Env Providers            ██████████ 100%    Core providers stable
  File Provider (Watch)             ██████████ 100%    JSON/Env format verified
  API Provider                      ████████░░  80%    Retry/Timeout logic active
  CRDT Support                      ██████░░░░  60%    G-Counter/OR-Set in progress

REPO INFRASTRUCTURE
  Justfile Automation               ██████████ 100%    Standard build/test tasks
  .machine_readable/                ██████████ 100%    STATE tracking active
  Nickel Config                     ██████████ 100%    Validated settings verified

─────────────────────────────────────────────────────────────────────────────
OVERALL:                            █████████░  ~90%   Stable and production-ready
```

## Key Dependencies

```
Nickel Config ───► Injector Core ─────► Priority Queue ─────► Resolution
     │                 │                   │                    │
     ▼                 ▼                   ▼                    ▼
Provider Set ────► Deno Fetch ──────► CRDT Merge ───────► Preference
```

## Update Protocol

This file is maintained by both humans and AI agents. When updating:

1. **After completing a component**: Change its bar and percentage
2. **After adding a component**: Add a new row in the appropriate section
3. **After architectural changes**: Update the ASCII diagram
4. **Date**: Update the `Last updated` comment at the top of this file

Progress bars use: `█` (filled) and `░` (empty), 10 characters wide.
Percentages: 0%, 10%, 20%, ... 100% (in 10% increments).
