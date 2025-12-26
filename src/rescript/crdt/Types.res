// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Hyperpolymath

/**
 * CRDT type definitions for distributed preference synchronization
 */

/** Vector clock for causality tracking */
type vectorClock = Js.Dict.t<int>

/** CRDT operation type */
type operation<'value> =
  | Increment(string, int)
  | Decrement(string, int)
  | Set(string, 'value, float)
  | Add(string, 'value)
  | Remove(string, 'value)

/** CRDT state with metadata */
type crdtState<'state> = {
  nodeId: string,
  state: 'state,
  vectorClock: vectorClock,
  timestamp: float,
}

/** Merge result */
type mergeResult<'state> = {
  merged: 'state,
  conflicts: array<string>,
}

/** Compare vector clocks */
let compareVectorClocks = (a: vectorClock, b: vectorClock): int => {
  let aKeys = Js.Dict.keys(a)
  let bKeys = Js.Dict.keys(b)
  let allKeys = Array.concat(aKeys, bKeys->Array.filter(k => !Array.includes(aKeys, k)))

  let aGreater = ref(false)
  let bGreater = ref(false)

  allKeys->Array.forEach(key => {
    let aVal = switch Js.Dict.get(a, key) {
    | Some(v) => v
    | None => 0
    }
    let bVal = switch Js.Dict.get(b, key) {
    | Some(v) => v
    | None => 0
    }
    if aVal > bVal {
      aGreater := true
    }
    if bVal > aVal {
      bGreater := true
    }
  })

  if aGreater.contents && !bGreater.contents {
    1
  } else if bGreater.contents && !aGreater.contents {
    -1
  } else {
    0
  }
}

/** Merge two vector clocks */
let mergeVectorClocks = (a: vectorClock, b: vectorClock): vectorClock => {
  let result = Js.Dict.empty()
  let aKeys = Js.Dict.keys(a)
  let bKeys = Js.Dict.keys(b)
  let allKeys = Array.concat(aKeys, bKeys->Array.filter(k => !Array.includes(aKeys, k)))

  allKeys->Array.forEach(key => {
    let aVal = switch Js.Dict.get(a, key) {
    | Some(v) => v
    | None => 0
    }
    let bVal = switch Js.Dict.get(b, key) {
    | Some(v) => v
    | None => 0
    }
    Js.Dict.set(result, key, max(aVal, bVal))
  })

  result
}

/** Increment a vector clock for a node */
let incrementClock = (clock: vectorClock, nodeId: string): vectorClock => {
  let result = Js.Dict.empty()
  Js.Dict.keys(clock)->Array.forEach(key => {
    switch Js.Dict.get(clock, key) {
    | Some(v) => Js.Dict.set(result, key, v)
    | None => ()
    }
  })
  let current = switch Js.Dict.get(result, nodeId) {
  | Some(v) => v
  | None => 0
  }
  Js.Dict.set(result, nodeId, current + 1)
  result
}
