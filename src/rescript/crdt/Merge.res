// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Hyperpolymath

/**
 * Generic merge utilities for CRDT operations
 */

open Types

/** Merge strategy for preference values */
type mergeStrategy =
  | LastWriteWins
  | HighestPriority
  | DeepMerge
  | Custom((preferenceValue, preferenceValue) => preferenceValue)

/** Deep merge two preference values */
let rec deepMerge = (a: preferenceValue, b: preferenceValue): preferenceValue => {
  switch (a, b) {
  | (Object(objA), Object(objB)) => {
      let result = Js.Dict.empty()
      // Copy all from objA
      Js.Dict.keys(objA)->Array.forEach(key => {
        switch Js.Dict.get(objA, key) {
        | Some(v) => Js.Dict.set(result, key, v)
        | None => ()
        }
      })
      // Merge in objB
      Js.Dict.keys(objB)->Array.forEach(key => {
        let valueB = Js.Dict.get(objB, key)
        let valueA = Js.Dict.get(result, key)
        switch (valueA, valueB) {
        | (Some(vA), Some(vB)) => Js.Dict.set(result, key, deepMerge(vA, vB))
        | (None, Some(vB)) => Js.Dict.set(result, key, vB)
        | _ => ()
        }
      })
      Object(result)
    }
  | (Array(arrA), Array(arrB)) =>
    // Concatenate arrays, removing duplicates for primitives
    let combined = Array.concat(arrA, arrB)
    Array(combined)
  | (_, b) => b // For primitives, b wins
  }
}

/** Merge two preference metadatas with strategy */
let mergeMetadata = (
  a: preferenceMetadata,
  b: preferenceMetadata,
  strategy: mergeStrategy,
): preferenceMetadata => {
  let mergedValue = switch strategy {
  | LastWriteWins =>
    if Js.Date.getTime(b.timestamp) > Js.Date.getTime(a.timestamp) {
      b.value
    } else {
      a.value
    }
  | HighestPriority =>
    if priorityToInt(b.priority) > priorityToInt(a.priority) {
      b.value
    } else {
      a.value
    }
  | DeepMerge => deepMerge(a.value, b.value)
  | Custom(fn) => fn(a.value, b.value)
  }

  {
    key: a.key,
    value: mergedValue,
    priority: if priorityToInt(b.priority) > priorityToInt(a.priority) {
      b.priority
    } else {
      a.priority
    },
    source: "merged",
    timestamp: Js.Date.make(),
    encrypted: switch (a.encrypted, b.encrypted) {
    | (Some(true), _) | (_, Some(true)) => Some(true)
    | _ => None
    },
    validated: None,
    ttl: switch (a.ttl, b.ttl) {
    | (Some(ta), Some(tb)) => Some(min(ta, tb))
    | (Some(t), None) | (None, Some(t)) => Some(t)
    | (None, None) => None
    },
  }
}

/** Merge multiple metadatas */
let mergeAll = (
  metadatas: array<preferenceMetadata>,
  strategy: mergeStrategy,
): option<preferenceMetadata> => {
  if Array.length(metadatas) == 0 {
    None
  } else {
    switch metadatas[0] {
    | Some(first) =>
      Some(
        metadatas
        ->Array.sliceToEnd(~start=1)
        ->Array.reduce(first, (acc, m) => mergeMetadata(acc, m, strategy)),
      )
    | None => None
    }
  }
}

/** Sync state between nodes */
type syncState = {
  nodeId: string,
  mutable vectorClock: vectorClock,
  mutable pendingOps: array<operation<preferenceValue>>,
}

/** Create sync state */
let makeSyncState = (~nodeId: string): syncState => {
  nodeId,
  vectorClock: Js.Dict.empty(),
  pendingOps: [],
}

/** Record an operation */
let recordOperation = (state: syncState, op: operation<preferenceValue>): unit => {
  state.pendingOps = Array.concat(state.pendingOps, [op])
  state.vectorClock = incrementClock(state.vectorClock, state.nodeId)
}

/** Get pending operations since a vector clock */
let getPendingOps = (state: syncState, since: vectorClock): array<operation<preferenceValue>> => {
  // Return all pending ops if the since clock is behind
  if compareVectorClocks(state.vectorClock, since) > 0 {
    state.pendingOps
  } else {
    []
  }
}

/** Clear pending operations */
let clearPendingOps = (state: syncState): unit => {
  state.pendingOps = []
}
