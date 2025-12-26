// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Hyperpolymath

/**
 * LWW-Register (Last-Writer-Wins Register) CRDT
 * Uses timestamps to resolve conflicts - last write wins
 */

open Types

/** LWW-Register state */
type t<'value> = {
  nodeId: string,
  mutable value: 'value,
  mutable timestamp: float,
}

/** Create a new LWW-Register */
let make = (~nodeId: string, ~initialValue: 'value): t<'value> => {
  nodeId,
  value: initialValue,
  timestamp: Js.Date.now(),
}

/** Get the current value */
let get = (register: t<'value>): 'value => {
  register.value
}

/** Set a new value */
let set = (register: t<'value>, value: 'value): unit => {
  register.value = value
  register.timestamp = Js.Date.now()
}

/** Set with explicit timestamp */
let setWithTimestamp = (register: t<'value>, value: 'value, timestamp: float): unit => {
  if timestamp > register.timestamp {
    register.value = value
    register.timestamp = timestamp
  }
}

/** Merge with another LWW-Register */
let merge = (a: t<'value>, b: t<'value>): t<'value> => {
  if b.timestamp > a.timestamp {
    {
      nodeId: a.nodeId,
      value: b.value,
      timestamp: b.timestamp,
    }
  } else {
    {
      nodeId: a.nodeId,
      value: a.value,
      timestamp: a.timestamp,
    }
  }
}

/** Compare two registers */
let equals = (a: t<'value>, b: t<'value>): bool => {
  a.value == b.value && a.timestamp == b.timestamp
}

/** Get the timestamp */
let getTimestamp = (register: t<'value>): float => {
  register.timestamp
}
