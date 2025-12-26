// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Hyperpolymath

/**
 * Environment variable preference provider
 */

open Types

/** Environment provider configuration */
type config = {
  prefix: option<string>,
  priority: preferencePriority,
  parseValues: bool,
}

/** Environment provider state */
type t = {
  name: string,
  config: config,
  mutable cache: Js.Dict.t<preferenceMetadata>,
}

/** Default configuration */
let defaultConfig: config = {
  prefix: None,
  priority: Highest,
  parseValues: true,
}

/** Create a new environment provider */
let make = (~config: option<config>=?): t => {
  name: "env",
  config: switch config {
  | Some(c) => c
  | None => defaultConfig
  },
  cache: Js.Dict.empty(),
}

/** Get environment variable (Deno-compatible) */
@val @scope("Deno") external getEnv: string => option<string> = "env.get"

/** Get all environment variables */
@val @scope("Deno") external getAllEnv: unit => Js.Dict.t<string> = "env.toObject"

/** Parse a string value to a preference value */
let parseValue = (str: string): preferenceValue => {
  // Try boolean
  if str == "true" {
    Bool(true)
  } else if str == "false" {
    Bool(false)
  } else if str == "null" {
    Null
  } else {
    // Try number
    let num = Float.fromString(str)
    switch num {
    | Some(n) => Number(n)
    | None =>
      // Try JSON
      try {
        let parsed = Js.Json.parseExn(str)
        // Convert JSON to preference value
        switch Js.Json.classify(parsed) {
        | Js.Json.JSONString(s) => String(s)
        | Js.Json.JSONNumber(n) => Number(n)
        | Js.Json.JSONTrue => Bool(true)
        | Js.Json.JSONFalse => Bool(false)
        | Js.Json.JSONNull => Null
        | _ => String(str)
        }
      } catch {
      | _ => String(str)
      }
    }
  }
}

/** Convert environment key to preference key */
let envKeyToPrefKey = (provider: t, envKey: string): option<string> => {
  switch provider.config.prefix {
  | Some(prefix) =>
    if String.startsWith(envKey, ~search=prefix) {
      let key = String.sliceToEnd(envKey, ~start=String.length(prefix))
      Some(String.toLowerCase(key))
    } else {
      None
    }
  | None => Some(String.toLowerCase(envKey))
  }
}

/** Convert preference key to environment key */
let prefKeyToEnvKey = (provider: t, prefKey: string): string => {
  let upper = String.toUpperCase(prefKey)
  switch provider.config.prefix {
  | Some(prefix) => prefix ++ upper
  | None => upper
  }
}

/** Initialize the provider */
let initialize = async (provider: t): promise<unit> => {
  // Load all matching environment variables into cache
  try {
    let envVars = getAllEnv()
    Js.Dict.keys(envVars)->Array.forEach(envKey => {
      switch envKeyToPrefKey(provider, envKey) {
      | Some(prefKey) =>
        switch Js.Dict.get(envVars, envKey) {
        | Some(strValue) => {
            let value = if provider.config.parseValues {
              parseValue(strValue)
            } else {
              String(strValue)
            }
            Js.Dict.set(
              provider.cache,
              prefKey,
              {
                key: prefKey,
                value,
                priority: provider.config.priority,
                source: provider.name,
                timestamp: Js.Date.make(),
                encrypted: None,
                validated: None,
                ttl: None,
              },
            )
          }
        | None => ()
        }
      | None => ()
      }
    })
  } catch {
  | _ => () // Environment access may fail in some contexts
  }
}

/** Get a preference */
let get = async (provider: t, key: string): promise<option<preferenceMetadata>> => {
  // Check cache first
  switch Js.Dict.get(provider.cache, key) {
  | Some(cached) => Some(cached)
  | None =>
    // Try to get from environment
    let envKey = prefKeyToEnvKey(provider, key)
    try {
      switch getEnv(envKey) {
      | Some(strValue) => {
          let value = if provider.config.parseValues {
            parseValue(strValue)
          } else {
            String(strValue)
          }
          let metadata = {
            key,
            value,
            priority: provider.config.priority,
            source: provider.name,
            timestamp: Js.Date.make(),
            encrypted: None,
            validated: None,
            ttl: None,
          }
          Js.Dict.set(provider.cache, key, metadata)
          Some(metadata)
        }
      | None => None
      }
    } catch {
    | _ => None
    }
  }
}

/** Get all preferences */
let getAll = async (provider: t): promise<Js.Dict.t<preferenceMetadata>> => {
  provider.cache
}

/** Set is not supported for environment provider (read-only) */
let set = async (_provider: t, _key: string, _value: preferenceValue, _options: option<setOptions>): promise<
  unit,
> => {
  Js.Console.warn("EnvProvider is read-only, cannot set preferences")
}

/** Check if a preference exists */
let has = async (provider: t, key: string): promise<bool> => {
  let result = await get(provider, key)
  Option.isSome(result)
}

/** Delete is not supported for environment provider (read-only) */
let delete = async (_provider: t, _key: string): promise<bool> => {
  Js.Console.warn("EnvProvider is read-only, cannot delete preferences")
  false
}

/** Clear the cache (not the actual environment) */
let clear = async (provider: t): promise<unit> => {
  provider.cache = Js.Dict.empty()
}
