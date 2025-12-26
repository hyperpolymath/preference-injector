// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Hyperpolymath

/**
 * OR-Set (Observed-Remove Set) CRDT
 * A set that supports both add and remove operations
 */

/** Unique tag for elements */
type tag = string

/** Element with tags */
type element<'value> = {
  value: 'value,
  tags: array<tag>,
}

/** OR-Set state */
type t<'value> = {
  nodeId: string,
  mutable elements: array<element<'value>>,
  mutable tagCounter: int,
}

/** Generate a unique tag */
let generateTag = (set: t<'value>): tag => {
  set.tagCounter = set.tagCounter + 1
  `${set.nodeId}:${Int.toString(set.tagCounter)}`
}

/** Create a new OR-Set */
let make = (~nodeId: string): t<'value> => {
  nodeId,
  elements: [],
  tagCounter: 0,
}

/** Check if a value exists in the set */
let contains = (set: t<'value>, value: 'value): bool => {
  set.elements->Array.some(e => e.value == value && Array.length(e.tags) > 0)
}

/** Add a value to the set */
let add = (set: t<'value>, value: 'value): unit => {
  let tag = generateTag(set)
  let existing = set.elements->Array.findIndex(e => e.value == value)
  if existing >= 0 {
    // Add tag to existing element
    switch set.elements[existing] {
    | Some(elem) =>
      set.elements = set.elements->Array.mapWithIndex((e, i) => {
        if i == existing {
          {value: e.value, tags: Array.concat(e.tags, [tag])}
        } else {
          e
        }
      })
    | None => ()
    }
  } else {
    // Add new element
    set.elements = Array.concat(set.elements, [{value, tags: [tag]}])
  }
}

/** Remove a value from the set (removes all its tags) */
let remove = (set: t<'value>, value: 'value): bool => {
  let existed = contains(set, value)
  set.elements =
    set.elements
    ->Array.map(e => {
      if e.value == value {
        {value: e.value, tags: []}
      } else {
        e
      }
    })
    ->Array.filter(e => Array.length(e.tags) > 0)
  existed
}

/** Get all values in the set */
let values = (set: t<'value>): array<'value> => {
  set.elements->Array.filter(e => Array.length(e.tags) > 0)->Array.map(e => e.value)
}

/** Get size of the set */
let size = (set: t<'value>): int => {
  Array.length(values(set))
}

/** Clear the set */
let clear = (set: t<'value>): unit => {
  set.elements = []
}

/** Merge with another OR-Set */
let merge = (a: t<'value>, b: t<'value>): t<'value> => {
  let result = make(~nodeId=a.nodeId)
  result.tagCounter = max(a.tagCounter, b.tagCounter)

  // Collect all unique values
  let allValues =
    Array.concat(
      a.elements->Array.map(e => e.value),
      b.elements->Array.map(e => e.value),
    )->Array.reduce([], (acc, v) => {
      if acc->Array.some(x => x == v) {
        acc
      } else {
        Array.concat(acc, [v])
      }
    })

  // For each value, merge tags from both sets
  allValues->Array.forEach(value => {
    let aTags = switch a.elements->Array.find(e => e.value == value) {
    | Some(e) => e.tags
    | None => []
    }
    let bTags = switch b.elements->Array.find(e => e.value == value) {
    | Some(e) => e.tags
    | None => []
    }

    // Union of tags
    let mergedTags =
      Array.concat(aTags, bTags)->Array.reduce([], (acc, t) => {
        if acc->Array.some(x => x == t) {
          acc
        } else {
          Array.concat(acc, [t])
        }
      })

    if Array.length(mergedTags) > 0 {
      result.elements = Array.concat(result.elements, [{value, tags: mergedTags}])
    }
  })

  result
}

/** Convert to array */
let toArray = (set: t<'value>): array<'value> => {
  values(set)
}
