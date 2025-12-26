// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Hyperpolymath

/**
 * Caching implementations for preference storage
 */

open Types

/** Cache entry with timestamp for TTL tracking */
type cacheEntry = {
  metadata: preferenceMetadata,
  cachedAt: float,
  ttl: option<int>,
}

/** Module type for cache implementations */
module type Cache = {
  type t
  let make: unit => t
  let get: (t, string) => option<preferenceMetadata>
  let set: (t, string, preferenceMetadata, option<int>) => unit
  let has: (t, string) => bool
  let delete: (t, string) => bool
  let clear: t => unit
  let size: t => int
}

/** LRU Cache with optional TTL support */
module LRUCache: Cache = {
  type t = {
    mutable entries: Js.Dict.t<cacheEntry>,
    mutable accessOrder: array<string>,
    maxSize: int,
    defaultTTL: int,
  }

  let make = () => {
    entries: Js.Dict.empty(),
    accessOrder: [],
    maxSize: 1000,
    defaultTTL: 3600000,
  }

  let makeWithConfig = (~maxSize: int, ~defaultTTL: int) => {
    entries: Js.Dict.empty(),
    accessOrder: [],
    maxSize,
    defaultTTL,
  }

  let isExpired = (entry: cacheEntry): bool => {
    let now = Js.Date.now()
    switch entry.ttl {
    | Some(ttl) => now -. entry.cachedAt > Float.fromInt(ttl)
    | None => false
    }
  }

  let updateAccessOrder = (cache: t, key: string): unit => {
    cache.accessOrder = cache.accessOrder->Array.filter(k => k != key)
    cache.accessOrder = Array.concat(cache.accessOrder, [key])
  }

  let evictOldest = (cache: t): unit => {
    if Array.length(cache.accessOrder) > 0 {
      let oldest = cache.accessOrder[0]
      switch oldest {
      | Some(key) => {
          Js.Dict.set(cache.entries, key, %raw(`undefined`))
          cache.accessOrder = cache.accessOrder->Array.sliceToEnd(~start=1)
        }
      | None => ()
      }
    }
  }

  let get = (cache: t, key: string): option<preferenceMetadata> => {
    switch Js.Dict.get(cache.entries, key) {
    | Some(entry) =>
      if isExpired(entry) {
        Js.Dict.set(cache.entries, key, %raw(`undefined`))
        cache.accessOrder = cache.accessOrder->Array.filter(k => k != key)
        None
      } else {
        updateAccessOrder(cache, key)
        Some(entry.metadata)
      }
    | None => None
    }
  }

  let set = (cache: t, key: string, metadata: preferenceMetadata, ttl: option<int>): unit => {
    if Array.length(cache.accessOrder) >= cache.maxSize {
      evictOldest(cache)
    }

    let entry: cacheEntry = {
      metadata,
      cachedAt: Js.Date.now(),
      ttl: switch ttl {
      | Some(t) => Some(t)
      | None => Some(cache.defaultTTL)
      },
    }

    Js.Dict.set(cache.entries, key, entry)
    updateAccessOrder(cache, key)
  }

  let has = (cache: t, key: string): bool => {
    switch Js.Dict.get(cache.entries, key) {
    | Some(entry) => !isExpired(entry)
    | None => false
    }
  }

  let delete = (cache: t, key: string): bool => {
    let existed = Js.Dict.get(cache.entries, key)->Option.isSome
    if existed {
      Js.Dict.set(cache.entries, key, %raw(`undefined`))
      cache.accessOrder = cache.accessOrder->Array.filter(k => k != key)
    }
    existed
  }

  let clear = (cache: t): unit => {
    cache.entries = Js.Dict.empty()
    cache.accessOrder = []
  }

  let size = (cache: t): int => {
    Array.length(cache.accessOrder)
  }
}

/** TTL-only Cache (no LRU eviction) */
module TTLCache: Cache = {
  type t = {
    mutable entries: Js.Dict.t<cacheEntry>,
    defaultTTL: int,
  }

  let make = () => {
    entries: Js.Dict.empty(),
    defaultTTL: 3600000,
  }

  let makeWithTTL = (~defaultTTL: int) => {
    entries: Js.Dict.empty(),
    defaultTTL,
  }

  let isExpired = (entry: cacheEntry): bool => {
    let now = Js.Date.now()
    switch entry.ttl {
    | Some(ttl) => now -. entry.cachedAt > Float.fromInt(ttl)
    | None => false
    }
  }

  let get = (cache: t, key: string): option<preferenceMetadata> => {
    switch Js.Dict.get(cache.entries, key) {
    | Some(entry) =>
      if isExpired(entry) {
        Js.Dict.set(cache.entries, key, %raw(`undefined`))
        None
      } else {
        Some(entry.metadata)
      }
    | None => None
    }
  }

  let set = (cache: t, key: string, metadata: preferenceMetadata, ttl: option<int>): unit => {
    let entry: cacheEntry = {
      metadata,
      cachedAt: Js.Date.now(),
      ttl: switch ttl {
      | Some(t) => Some(t)
      | None => Some(cache.defaultTTL)
      },
    }
    Js.Dict.set(cache.entries, key, entry)
  }

  let has = (cache: t, key: string): bool => {
    switch Js.Dict.get(cache.entries, key) {
    | Some(entry) => !isExpired(entry)
    | None => false
    }
  }

  let delete = (cache: t, key: string): bool => {
    let existed = Js.Dict.get(cache.entries, key)->Option.isSome
    if existed {
      Js.Dict.set(cache.entries, key, %raw(`undefined`))
    }
    existed
  }

  let clear = (cache: t): unit => {
    cache.entries = Js.Dict.empty()
  }

  let size = (cache: t): int => {
    Js.Dict.keys(cache.entries)->Array.length
  }
}

/** No-op cache that doesn't store anything */
module NoOpCache: Cache = {
  type t = unit

  let make = () => ()

  let get = (_cache: t, _key: string): option<preferenceMetadata> => None

  let set = (_cache: t, _key: string, _metadata: preferenceMetadata, _ttl: option<int>): unit => ()

  let has = (_cache: t, _key: string): bool => false

  let delete = (_cache: t, _key: string): bool => false

  let clear = (_cache: t): unit => ()

  let size = (_cache: t): int => 0
}
