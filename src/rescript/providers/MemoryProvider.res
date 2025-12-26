// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Hyperpolymath

/**
 * In-memory preference provider for runtime preferences
 */

open Types

/** Memory provider state */
type t = {
  name: string,
  priority: preferencePriority,
  mutable preferences: Js.Dict.t<preferenceMetadata>,
}

/** Create a new memory provider */
let make = (~priority: preferencePriority=Normal): t => {
  name: "memory",
  priority,
  preferences: Js.Dict.empty(),
}

/** Create with initial values */
let makeWithValues = (
  ~priority: preferencePriority=Normal,
  ~initialValues: Js.Dict.t<preferenceValue>,
): t => {
  let provider = make(~priority)
  Js.Dict.keys(initialValues)->Array.forEach(key => {
    switch Js.Dict.get(initialValues, key) {
    | Some(value) =>
      Js.Dict.set(
        provider.preferences,
        key,
        {
          key,
          value,
          priority: provider.priority,
          source: provider.name,
          timestamp: Js.Date.make(),
          encrypted: None,
          validated: None,
          ttl: None,
        },
      )
    | None => ()
    }
  })
  provider
}

/** Initialize (no-op for memory provider) */
let initialize = async (_provider: t): promise<unit> => {
  ()
}

/** Get a preference */
let get = async (provider: t, key: string): promise<option<preferenceMetadata>> => {
  Js.Dict.get(provider.preferences, key)
}

/** Get all preferences */
let getAll = async (provider: t): promise<Js.Dict.t<preferenceMetadata>> => {
  provider.preferences
}

/** Set a preference */
let set = async (
  provider: t,
  key: string,
  value: preferenceValue,
  options: option<setOptions>,
): promise<unit> => {
  let metadata: preferenceMetadata = {
    key,
    value,
    priority: switch options {
    | Some(opts) =>
      switch opts.priority {
      | Some(p) => p
      | None => provider.priority
      }
    | None => provider.priority
    },
    source: provider.name,
    timestamp: Js.Date.make(),
    encrypted: switch options {
    | Some(opts) => opts.encrypt
    | None => None
    },
    validated: switch options {
    | Some(opts) => opts.validate
    | None => None
    },
    ttl: switch options {
    | Some(opts) => opts.ttl
    | None => None
    },
  }
  Js.Dict.set(provider.preferences, key, metadata)
}

/** Check if a preference exists */
let has = async (provider: t, key: string): promise<bool> => {
  Js.Dict.get(provider.preferences, key)->Option.isSome
}

/** Delete a preference */
let delete = async (provider: t, key: string): promise<bool> => {
  let existed = Js.Dict.get(provider.preferences, key)->Option.isSome
  if existed {
    // Remove by setting to undefined (JavaScript behavior)
    %raw(`delete provider.preferences[key]`)
  }
  existed
}

/** Clear all preferences */
let clear = async (provider: t): promise<unit> => {
  provider.preferences = Js.Dict.empty()
}

/** Get the number of preferences */
let size = (provider: t): int => {
  Js.Dict.keys(provider.preferences)->Array.length
}

/** Get all preference keys */
let keys = (provider: t): array<string> => {
  Js.Dict.keys(provider.preferences)
}

/** Get all preference values */
let values = (provider: t): array<preferenceValue> => {
  Js.Dict.values(provider.preferences)->Array.map(m => m.value)
}

/** Import preferences from an object */
let import = async (provider: t, data: Js.Dict.t<preferenceValue>): promise<unit> => {
  let keys = Js.Dict.keys(data)
  for i in 0 to Array.length(keys) - 1 {
    let key = keys[i]
    switch key {
    | Some(k) =>
      switch Js.Dict.get(data, k) {
      | Some(value) => await set(provider, k, value, None)
      | None => ()
      }
    | None => ()
    }
  }
}

/** Export preferences to an object */
let export = (provider: t): Js.Dict.t<preferenceValue> => {
  let result = Js.Dict.empty()
  Js.Dict.keys(provider.preferences)->Array.forEach(key => {
    switch Js.Dict.get(provider.preferences, key) {
    | Some(metadata) => Js.Dict.set(result, key, metadata.value)
    | None => ()
    }
  })
  result
}
