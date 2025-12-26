// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Hyperpolymath

/**
 * Audit logging for preference operations
 */

open Types

/** Module type for audit logger implementations */
module type AuditLogger = {
  type t
  let make: unit => t
  let log: (t, auditLogEntry) => unit
  let getEntries: (t, option<auditFilter>) => array<auditLogEntry>
  let clear: t => unit
}

/** Check if an entry matches the filter */
let matchesFilter = (entry: auditLogEntry, filter: auditFilter): bool => {
  let actionMatches = switch filter.action {
  | Some(action) => entry.action == action
  | None => true
  }

  let keyMatches = switch filter.key {
  | Some(key) => entry.key == key
  | None => true
  }

  let providerMatches = switch filter.provider {
  | Some(provider) => entry.provider == provider
  | None => true
  }

  let userIdMatches = switch filter.userId {
  | Some(userId) => entry.userId == Some(userId)
  | None => true
  }

  let startDateMatches = switch filter.startDate {
  | Some(startDate) => Js.Date.getTime(entry.timestamp) >= Js.Date.getTime(startDate)
  | None => true
  }

  let endDateMatches = switch filter.endDate {
  | Some(endDate) => Js.Date.getTime(entry.timestamp) <= Js.Date.getTime(endDate)
  | None => true
  }

  actionMatches && keyMatches && providerMatches && userIdMatches && startDateMatches && endDateMatches
}

/** In-memory audit logger */
module InMemoryLogger: AuditLogger = {
  type t = {
    mutable entries: array<auditLogEntry>,
    maxEntries: int,
  }

  let make = () => {
    entries: [],
    maxEntries: 10000,
  }

  let makeWithMax = (~maxEntries: int) => {
    entries: [],
    maxEntries,
  }

  let log = (logger: t, entry: auditLogEntry): unit => {
    logger.entries = Array.concat(logger.entries, [entry])
    if Array.length(logger.entries) > logger.maxEntries {
      logger.entries = logger.entries->Array.sliceToEnd(~start=1)
    }
  }

  let getEntries = (logger: t, filter: option<auditFilter>): array<auditLogEntry> => {
    switch filter {
    | None => logger.entries
    | Some(f) => logger.entries->Array.filter(entry => matchesFilter(entry, f))
    }
  }

  let clear = (logger: t): unit => {
    logger.entries = []
  }
}

/** Console audit logger (logs to console) */
module ConsoleLogger: AuditLogger = {
  type t = {mutable entries: array<auditLogEntry>}

  let make = () => {
    entries: [],
  }

  let log = (logger: t, entry: auditLogEntry): unit => {
    logger.entries = Array.concat(logger.entries, [entry])
    let actionStr = auditActionToString(entry.action)
    Js.Console.log(`[AUDIT] ${actionStr} - Key: ${entry.key} - Provider: ${entry.provider}`)
  }

  let getEntries = (logger: t, filter: option<auditFilter>): array<auditLogEntry> => {
    switch filter {
    | None => logger.entries
    | Some(f) => logger.entries->Array.filter(entry => matchesFilter(entry, f))
    }
  }

  let clear = (logger: t): unit => {
    logger.entries = []
  }
}

/** No-op audit logger */
module NoOpLogger: AuditLogger = {
  type t = unit

  let make = () => ()

  let log = (_logger: t, _entry: auditLogEntry): unit => ()

  let getEntries = (_logger: t, _filter: option<auditFilter>): array<auditLogEntry> => []

  let clear = (_logger: t): unit => ()
}
