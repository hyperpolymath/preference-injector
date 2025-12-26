// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Hyperpolymath

/**
 * PN-Counter (Positive-Negative Counter) CRDT
 * Supports both increment and decrement operations
 */

/** PN-Counter state using two G-Counters */
type t = {
  nodeId: string,
  positive: GCounter.t,
  negative: GCounter.t,
}

/** Create a new PN-Counter */
let make = (~nodeId: string): t => {
  nodeId,
  positive: GCounter.make(~nodeId),
  negative: GCounter.make(~nodeId),
}

/** Get the current value */
let value = (counter: t): int => {
  GCounter.value(counter.positive) - GCounter.value(counter.negative)
}

/** Increment the counter */
let increment = (counter: t, ~amount: int=1): unit => {
  GCounter.increment(counter.positive, ~amount)
}

/** Decrement the counter */
let decrement = (counter: t, ~amount: int=1): unit => {
  GCounter.increment(counter.negative, ~amount)
}

/** Merge with another PN-Counter */
let merge = (a: t, b: t): t => {
  {
    nodeId: a.nodeId,
    positive: GCounter.merge(a.positive, b.positive),
    negative: GCounter.merge(a.negative, b.negative),
  }
}

/** Compare two PN-Counters for equality */
let equals = (a: t, b: t): bool => {
  GCounter.equals(a.positive, b.positive) && GCounter.equals(a.negative, b.negative)
}

/** Serialize to JSON */
let toJson = (counter: t): Js.Json.t => {
  let obj = Js.Dict.empty()
  Js.Dict.set(obj, "nodeId", Js.Json.string(counter.nodeId))
  Js.Dict.set(obj, "positive", GCounter.toJson(counter.positive))
  Js.Dict.set(obj, "negative", GCounter.toJson(counter.negative))
  Js.Json.object_(obj)
}

/** Deserialize from JSON */
let fromJson = (json: Js.Json.t): option<t> => {
  switch Js.Json.classify(json) {
  | Js.Json.JSONObject(obj) =>
    switch (
      Js.Dict.get(obj, "nodeId"),
      Js.Dict.get(obj, "positive"),
      Js.Dict.get(obj, "negative"),
    ) {
    | (Some(nodeIdJson), Some(positiveJson), Some(negativeJson)) =>
      switch Js.Json.classify(nodeIdJson) {
      | Js.Json.JSONString(nodeId) =>
        switch (GCounter.fromJson(positiveJson), GCounter.fromJson(negativeJson)) {
        | (Some(positive), Some(negative)) => Some({nodeId, positive, negative})
        | _ => None
        }
      | _ => None
      }
    | _ => None
    }
  | _ => None
  }
}
