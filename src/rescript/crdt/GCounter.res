// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Hyperpolymath

/**
 * G-Counter (Grow-only Counter) CRDT
 * Supports increment operations only, guarantees eventual consistency
 */

open Types

/** G-Counter state */
type t = {
  nodeId: string,
  mutable counts: Js.Dict.t<int>,
}

/** Create a new G-Counter */
let make = (~nodeId: string): t => {
  nodeId,
  counts: Js.Dict.empty(),
}

/** Get the current value */
let value = (counter: t): int => {
  Js.Dict.values(counter.counts)->Array.reduce(0, (acc, v) => acc + v)
}

/** Increment the counter */
let increment = (counter: t, ~amount: int=1): unit => {
  let current = switch Js.Dict.get(counter.counts, counter.nodeId) {
  | Some(v) => v
  | None => 0
  }
  Js.Dict.set(counter.counts, counter.nodeId, current + amount)
}

/** Merge with another G-Counter */
let merge = (a: t, b: t): t => {
  let result = make(~nodeId=a.nodeId)
  let aKeys = Js.Dict.keys(a.counts)
  let bKeys = Js.Dict.keys(b.counts)
  let allKeys = Array.concat(aKeys, bKeys->Array.filter(k => !Array.includes(aKeys, k)))

  allKeys->Array.forEach(key => {
    let aVal = switch Js.Dict.get(a.counts, key) {
    | Some(v) => v
    | None => 0
    }
    let bVal = switch Js.Dict.get(b.counts, key) {
    | Some(v) => v
    | None => 0
    }
    Js.Dict.set(result.counts, key, max(aVal, bVal))
  })

  result
}

/** Compare two G-Counters for equality */
let equals = (a: t, b: t): bool => {
  let aKeys = Js.Dict.keys(a.counts)
  let bKeys = Js.Dict.keys(b.counts)

  if Array.length(aKeys) != Array.length(bKeys) {
    false
  } else {
    aKeys->Array.every(key => {
      let aVal = Js.Dict.get(a.counts, key)
      let bVal = Js.Dict.get(b.counts, key)
      aVal == bVal
    })
  }
}

/** Serialize to JSON */
let toJson = (counter: t): Js.Json.t => {
  let obj = Js.Dict.empty()
  Js.Dict.set(obj, "nodeId", Js.Json.string(counter.nodeId))
  let countsObj = Js.Dict.empty()
  Js.Dict.keys(counter.counts)->Array.forEach(key => {
    switch Js.Dict.get(counter.counts, key) {
    | Some(v) => Js.Dict.set(countsObj, key, Js.Json.number(Float.fromInt(v)))
    | None => ()
    }
  })
  Js.Dict.set(obj, "counts", Js.Json.object_(countsObj))
  Js.Json.object_(obj)
}

/** Deserialize from JSON */
let fromJson = (json: Js.Json.t): option<t> => {
  switch Js.Json.classify(json) {
  | Js.Json.JSONObject(obj) =>
    switch (Js.Dict.get(obj, "nodeId"), Js.Dict.get(obj, "counts")) {
    | (Some(nodeIdJson), Some(countsJson)) =>
      switch (Js.Json.classify(nodeIdJson), Js.Json.classify(countsJson)) {
      | (Js.Json.JSONString(nodeId), Js.Json.JSONObject(countsObj)) => {
          let counter = make(~nodeId)
          Js.Dict.keys(countsObj)->Array.forEach(key => {
            switch Js.Dict.get(countsObj, key) {
            | Some(v) =>
              switch Js.Json.classify(v) {
              | Js.Json.JSONNumber(n) => Js.Dict.set(counter.counts, key, Float.toInt(n))
              | _ => ()
              }
            | None => ()
            }
          })
          Some(counter)
        }
      | _ => None
      }
    | _ => None
    }
  | _ => None
  }
}
