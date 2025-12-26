// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Hyperpolymath

/**
 * Core preference injector with support for multiple providers,
 * caching, validation, encryption, and auditing
 */

open Types

/** Provider interface for use with the injector */
type provider = {
  name: string,
  priority: preferencePriority,
  initialize: unit => promise<unit>,
  get: string => promise<option<preferenceMetadata>>,
  getAll: unit => promise<Js.Dict.t<preferenceMetadata>>,
  set: (string, preferenceValue, option<setOptions>) => promise<unit>,
  has: string => promise<bool>,
  delete: string => promise<bool>,
  clear: unit => promise<unit>,
}

/** Event listener type */
type eventListener = preferenceChangeEvent => unit

/** Injector state */
type t = {
  mutable providers: array<provider>,
  conflictResolution: conflictResolution,
  mutable cache: Cache.LRUCache.t,
  mutable validator: Validator.t,
  mutable auditLogger: Audit.InMemoryLogger.t,
  mutable encryptionKey: option<string>,
  mutable initialized: bool,
  mutable eventListeners: Js.Dict.t<array<eventListener>>,
  enableCache: bool,
  enableAudit: bool,
}

/** Create a new injector */
let make = (~config: option<injectorConfig>=?): t => {
  let cfg = switch config {
  | Some(c) => c
  | None => {
      conflictResolution: None,
      enableCache: None,
      cacheTTL: None,
      enableValidation: None,
      enableEncryption: None,
      enableAudit: None,
      encryptionKey: None,
    }
  }

  {
    providers: [],
    conflictResolution: switch cfg.conflictResolution {
    | Some(cr) => cr
    | None => HighestPriority
    },
    cache: Cache.LRUCache.make(),
    validator: Validator.make(),
    auditLogger: Audit.InMemoryLogger.make(),
    encryptionKey: cfg.encryptionKey,
    initialized: false,
    eventListeners: Js.Dict.empty(),
    enableCache: switch cfg.enableCache {
    | Some(c) => c
    | None => false
    },
    enableAudit: switch cfg.enableAudit {
    | Some(a) => a
    | None => false
    },
  }
}

/** Initialize all providers */
let initialize = async (injector: t): promise<unit> => {
  if !injector.initialized {
    let _ = await Promise.all(injector.providers->Array.map(p => p.initialize()))
    injector.initialized = true
  }
}

/** Add a provider */
let addProvider = (injector: t, provider: provider): unit => {
  injector.providers = Array.concat(injector.providers, [provider])
}

/** Remove a provider by name */
let removeProvider = (injector: t, name: string): bool => {
  let originalLen = Array.length(injector.providers)
  injector.providers = injector.providers->Array.filter(p => p.name != name)
  Array.length(injector.providers) < originalLen
}

/** Log an audit entry */
let logAudit = (injector: t, action: auditAction, key: string, value: option<preferenceValue>, oldValue: option<preferenceValue>, provider: string): unit => {
  if injector.enableAudit {
    Audit.InMemoryLogger.log(
      injector.auditLogger,
      {
        timestamp: Js.Date.make(),
        action,
        key,
        value,
        oldValue,
        provider,
        userId: None,
      },
    )
  }
}

/** Emit an event */
let emitEvent = (injector: t, event: preferenceChangeEvent): unit => {
  let eventKey = switch event.eventType {
  | Changed => "changed"
  | Added => "added"
  | Removed => "removed"
  | Cleared => "cleared"
  }
  switch Js.Dict.get(injector.eventListeners, eventKey) {
  | Some(listeners) =>
    listeners->Array.forEach(listener => {
      try {
        listener(event)
      } catch {
      | _ => Js.Console.error("Error in event listener")
      }
    })
  | None => ()
  }
}

/** Get a preference value */
let get = async (injector: t, key: string, options: option<getOptions>): promise<
  result<preferenceValue, Errors.preferenceError>,
> => {
  let useCache = switch options {
  | Some(opts) =>
    switch opts.useCache {
    | Some(c) => c
    | None => true
    }
  | None => true
  }

  // Check cache first
  if injector.enableCache && useCache {
    switch Cache.LRUCache.get(injector.cache, key) {
    | Some(cached) => {
        logAudit(injector, Get, key, Some(cached.value), None, "cache")
        Ok(cached.value)
      }
    | None => ()
    }
  }

  // Gather from all providers
  let results = []
  for i in 0 to Array.length(injector.providers) - 1 {
    switch injector.providers[i] {
    | Some(provider) => {
        let metadata = await provider.get(key)
        switch metadata {
        | Some(m) => ignore(Array.concat(results, [m]))
        | None => ()
        }
      }
    | None => ()
    }
  }

  if Array.length(results) == 0 {
    switch options {
    | Some(opts) =>
      switch opts.defaultValue {
      | Some(dv) => Ok(dv)
      | None => Error(Errors.makeNotFoundError(~key))
      }
    | None => Error(Errors.makeNotFoundError(~key))
    }
  } else {
    switch ConflictResolver.resolve(results, injector.conflictResolution) {
    | Ok(resolved) => {
        // Update cache
        if injector.enableCache && useCache {
          Cache.LRUCache.set(injector.cache, key, resolved, resolved.ttl)
        }
        logAudit(injector, Get, key, Some(resolved.value), None, resolved.source)
        Ok(resolved.value)
      }
    | Error(e) => Error(e)
    }
  }
}

/** Set a preference value */
let set = async (injector: t, key: string, value: preferenceValue, options: option<setOptions>): promise<
  result<unit, Errors.preferenceError>,
> => {
  // Validate if needed
  let shouldValidate = switch options {
  | Some(opts) =>
    switch opts.validate {
    | Some(v) => v
    | None => true
    }
  | None => true
  }

  if shouldValidate {
    let validationResult = Validator.validate(injector.validator, key, value)
    if !validationResult.valid {
      return Error(
        Errors.makeValidationError(
          ~key,
          ~errors=validationResult.errors->Array.map(e => {"rule": e.rule, "message": e.message}),
        ),
      )
    }
  }

  // Get old value for audit
  let oldValue = switch await get(injector, key, Some({defaultValue: None, decrypt: None, useCache: Some(false)})) {
  | Ok(v) => Some(v)
  | Error(_) => None
  }

  // Set in all providers
  for i in 0 to Array.length(injector.providers) - 1 {
    switch injector.providers[i] {
    | Some(provider) => await provider.set(key, value, options)
    | None => ()
    }
  }

  // Clear from cache
  if injector.enableCache {
    ignore(Cache.LRUCache.delete(injector.cache, key))
  }

  logAudit(injector, Set, key, Some(value), oldValue, "injector")

  // Emit event
  emitEvent(
    injector,
    {
      eventType: switch oldValue {
      | Some(_) => Changed
      | None => Added
      },
      key,
      newValue: Some(value),
      oldValue,
      provider: "injector",
      timestamp: Js.Date.make(),
    },
  )

  Ok()
}

/** Check if a preference exists */
let has = async (injector: t, key: string): promise<bool> => {
  let found = ref(false)
  for i in 0 to Array.length(injector.providers) - 1 {
    if !found.contents {
      switch injector.providers[i] {
      | Some(provider) => {
          let exists = await provider.has(key)
          if exists {
            found := true
          }
        }
      | None => ()
      }
    }
  }
  found.contents
}

/** Delete a preference */
let delete = async (injector: t, key: string): promise<bool> => {
  // Get old value for audit
  let oldValue = switch await get(injector, key, Some({defaultValue: None, decrypt: None, useCache: Some(false)})) {
  | Ok(v) => Some(v)
  | Error(_) => None
  }

  let deleted = ref(false)
  for i in 0 to Array.length(injector.providers) - 1 {
    switch injector.providers[i] {
    | Some(provider) => {
        let result = await provider.delete(key)
        if result {
          deleted := true
        }
      }
    | None => ()
    }
  }

  if deleted.contents {
    if injector.enableCache {
      ignore(Cache.LRUCache.delete(injector.cache, key))
    }
    logAudit(injector, Delete, key, None, oldValue, "injector")
    emitEvent(
      injector,
      {
        eventType: Removed,
        key,
        newValue: None,
        oldValue,
        provider: "injector",
        timestamp: Js.Date.make(),
      },
    )
  }

  deleted.contents
}

/** Clear all preferences */
let clear = async (injector: t): promise<unit> => {
  for i in 0 to Array.length(injector.providers) - 1 {
    switch injector.providers[i] {
    | Some(provider) => await provider.clear()
    | None => ()
    }
  }

  if injector.enableCache {
    Cache.LRUCache.clear(injector.cache)
  }

  logAudit(injector, Clear, "*", None, None, "injector")
  emitEvent(
    injector,
    {
      eventType: Cleared,
      key: "*",
      newValue: None,
      oldValue: None,
      provider: "injector",
      timestamp: Js.Date.make(),
    },
  )
}

/** Get all preferences */
let getAll = async (injector: t): promise<Js.Dict.t<preferenceValue>> => {
  let allPrefs = Js.Dict.empty()

  for i in 0 to Array.length(injector.providers) - 1 {
    switch injector.providers[i] {
    | Some(provider) => {
        let providerPrefs = await provider.getAll()
        Js.Dict.keys(providerPrefs)->Array.forEach(key => {
          switch Js.Dict.get(providerPrefs, key) {
          | Some(metadata) =>
            // Only set if not already set (priority based on provider order)
            if Js.Dict.get(allPrefs, key)->Option.isNone {
              Js.Dict.set(allPrefs, key, metadata.value)
            }
          | None => ()
          }
        })
      }
    | None => ()
    }
  }

  allPrefs
}

/** Add an event listener */
let on = (injector: t, event: preferenceEvent, listener: eventListener): unit => {
  let eventKey = switch event {
  | Changed => "changed"
  | Added => "added"
  | Removed => "removed"
  | Cleared => "cleared"
  }
  let existing = switch Js.Dict.get(injector.eventListeners, eventKey) {
  | Some(listeners) => listeners
  | None => []
  }
  Js.Dict.set(injector.eventListeners, eventKey, Array.concat(existing, [listener]))
}

/** Remove an event listener */
let off = (injector: t, event: preferenceEvent, listener: eventListener): unit => {
  let eventKey = switch event {
  | Changed => "changed"
  | Added => "added"
  | Removed => "removed"
  | Cleared => "cleared"
  }
  switch Js.Dict.get(injector.eventListeners, eventKey) {
  | Some(listeners) =>
    Js.Dict.set(injector.eventListeners, eventKey, listeners->Array.filter(l => l != listener))
  | None => ()
  }
}

/** Get the validator */
let getValidator = (injector: t): Validator.t => injector.validator

/** Get the audit logger */
let getAuditLogger = (injector: t): Audit.InMemoryLogger.t => injector.auditLogger

/** Get the cache */
let getCache = (injector: t): Cache.LRUCache.t => injector.cache

/** Add a validation rule */
let addValidationRule = (injector: t, key: string, rule: Validator.validationRule): unit => {
  Validator.addRule(injector.validator, key, rule)
}
