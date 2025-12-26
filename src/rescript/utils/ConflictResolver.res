// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Hyperpolymath

/**
 * Conflict resolution utilities for handling multiple preference sources
 */

open Types

/** Compare two priorities, return positive if a > b */
let comparePriority = (a: preferencePriority, b: preferencePriority): int => {
  priorityToInt(a) - priorityToInt(b)
}

/** Compare two timestamps, return positive if a > b */
let compareTimestamp = (a: Js.Date.t, b: Js.Date.t): float => {
  Js.Date.getTime(a) -. Js.Date.getTime(b)
}

/** Deep merge two preference objects */
let rec mergeValues = (a: preferenceValue, b: preferenceValue): preferenceValue => {
  switch (a, b) {
  | (Object(objA), Object(objB)) => {
      let merged = Js.Dict.empty()
      // Copy all from objA
      Js.Dict.keys(objA)->Array.forEach(key => {
        switch Js.Dict.get(objA, key) {
        | Some(v) => Js.Dict.set(merged, key, v)
        | None => ()
        }
      })
      // Merge in objB, recursively merging objects
      Js.Dict.keys(objB)->Array.forEach(key => {
        let valueB = Js.Dict.get(objB, key)
        let valueA = Js.Dict.get(merged, key)
        switch (valueA, valueB) {
        | (Some(vA), Some(vB)) => Js.Dict.set(merged, key, mergeValues(vA, vB))
        | (None, Some(vB)) => Js.Dict.set(merged, key, vB)
        | _ => ()
        }
      })
      Object(merged)
    }
  | (Array(arrA), Array(arrB)) => Array(Array.concat(arrA, arrB))
  | (_, b) => b
  }
}

/** Resolve conflicts between multiple preference values */
let resolve = (
  metadatas: array<preferenceMetadata>,
  strategy: conflictResolution,
): result<preferenceMetadata, Errors.preferenceError> => {
  if Array.length(metadatas) == 0 {
    Error(Errors.makeNotFoundError(~key="unknown"))
  } else if Array.length(metadatas) == 1 {
    switch metadatas[0] {
    | Some(m) => Ok(m)
    | None => Error(Errors.makeNotFoundError(~key="unknown"))
    }
  } else {
    switch strategy {
    | HighestPriority => {
        let sorted =
          metadatas->Array.toSorted((a, b) => Float.fromInt(comparePriority(b.priority, a.priority)))
        switch sorted[0] {
        | Some(m) => Ok(m)
        | None => Error(Errors.makeNotFoundError(~key="unknown"))
        }
      }

    | LowestPriority => {
        let sorted =
          metadatas->Array.toSorted((a, b) => Float.fromInt(comparePriority(a.priority, b.priority)))
        switch sorted[0] {
        | Some(m) => Ok(m)
        | None => Error(Errors.makeNotFoundError(~key="unknown"))
        }
      }

    | Override => {
        // Use the most recent value
        let sorted = metadatas->Array.toSorted((a, b) => compareTimestamp(b.timestamp, a.timestamp))
        switch sorted[0] {
        | Some(m) => Ok(m)
        | None => Error(Errors.makeNotFoundError(~key="unknown"))
        }
      }

    | Merge => {
        // Start with first and merge in the rest
        let sorted =
          metadatas->Array.toSorted((a, b) => Float.fromInt(comparePriority(a.priority, b.priority)))
        switch sorted[0] {
        | Some(base) => {
            let mergedValue =
              sorted
              ->Array.sliceToEnd(~start=1)
              ->Array.reduce(base.value, (acc, m) => mergeValues(acc, m.value))
            Ok({
              ...base,
              value: mergedValue,
              timestamp: Js.Date.make(),
            })
          }
        | None => Error(Errors.makeNotFoundError(~key="unknown"))
        }
      }

    | Error => {
        let providers = metadatas->Array.map(m => m.source)
        switch metadatas[0] {
        | Some(m) => Result.Error(Errors.makeConflictError(~key=m.key, ~providers))
        | None => Result.Error(Errors.makeNotFoundError(~key="unknown"))
        }
      }
    }
  }
}

/** Get the highest priority metadata */
let getHighestPriority = (metadatas: array<preferenceMetadata>): option<preferenceMetadata> => {
  if Array.length(metadatas) == 0 {
    None
  } else {
    let sorted =
      metadatas->Array.toSorted((a, b) => Float.fromInt(comparePriority(b.priority, a.priority)))
    sorted[0]
  }
}

/** Get the most recent metadata */
let getMostRecent = (metadatas: array<preferenceMetadata>): option<preferenceMetadata> => {
  if Array.length(metadatas) == 0 {
    None
  } else {
    let sorted = metadatas->Array.toSorted((a, b) => compareTimestamp(b.timestamp, a.timestamp))
    sorted[0]
  }
}
