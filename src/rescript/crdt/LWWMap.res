// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Hyperpolymath

/**
 * LWW-Map (Last-Writer-Wins Map) CRDT
 * A map where each entry is an LWW-Register
 */

open Types

/** Map entry with timestamp */
type entry<'value> = {
  value: 'value,
  timestamp: float,
}

/** LWW-Map state */
type t<'value> = {
  nodeId: string,
  mutable entries: Js.Dict.t<entry<'value>>,
}

/** Create a new LWW-Map */
let make = (~nodeId: string): t<'value> => {
  nodeId,
  entries: Js.Dict.empty(),
}

/** Get a value by key */
let get = (map: t<'value>, key: string): option<'value> => {
  switch Js.Dict.get(map.entries, key) {
  | Some(entry) => Some(entry.value)
  | None => None
  }
}

/** Set a value */
let set = (map: t<'value>, key: string, value: 'value): unit => {
  Js.Dict.set(
    map.entries,
    key,
    {
      value,
      timestamp: Js.Date.now(),
    },
  )
}

/** Set with explicit timestamp */
let setWithTimestamp = (map: t<'value>, key: string, value: 'value, timestamp: float): unit => {
  switch Js.Dict.get(map.entries, key) {
  | Some(existing) if existing.timestamp >= timestamp => ()
  | _ => Js.Dict.set(map.entries, key, {value, timestamp})
  }
}

/** Delete a key (uses tombstone with current timestamp) */
let delete = (map: t<'value>, key: string): bool => {
  let existed = Js.Dict.get(map.entries, key)->Option.isSome
  if existed {
    %raw(`delete map.entries[key]`)
  }
  existed
}

/** Check if key exists */
let has = (map: t<'value>, key: string): bool => {
  Js.Dict.get(map.entries, key)->Option.isSome
}

/** Get all keys */
let keys = (map: t<'value>): array<string> => {
  Js.Dict.keys(map.entries)
}

/** Get all values */
let values = (map: t<'value>): array<'value> => {
  Js.Dict.values(map.entries)->Array.map(e => e.value)
}

/** Get size */
let size = (map: t<'value>): int => {
  Array.length(Js.Dict.keys(map.entries))
}

/** Merge with another LWW-Map */
let merge = (a: t<'value>, b: t<'value>): t<'value> => {
  let result = make(~nodeId=a.nodeId)

  // Copy all from a
  Js.Dict.keys(a.entries)->Array.forEach(key => {
    switch Js.Dict.get(a.entries, key) {
    | Some(entry) => Js.Dict.set(result.entries, key, entry)
    | None => ()
    }
  })

  // Merge in b, keeping later timestamps
  Js.Dict.keys(b.entries)->Array.forEach(key => {
    switch Js.Dict.get(b.entries, key) {
    | Some(bEntry) =>
      switch Js.Dict.get(result.entries, key) {
      | Some(aEntry) if aEntry.timestamp >= bEntry.timestamp => ()
      | _ => Js.Dict.set(result.entries, key, bEntry)
      }
    | None => ()
    }
  })

  result
}

/** Convert to a plain dictionary */
let toDict = (map: t<'value>): Js.Dict.t<'value> => {
  let result = Js.Dict.empty()
  Js.Dict.keys(map.entries)->Array.forEach(key => {
    switch Js.Dict.get(map.entries, key) {
    | Some(entry) => Js.Dict.set(result, key, entry.value)
    | None => ()
    }
  })
  result
}
