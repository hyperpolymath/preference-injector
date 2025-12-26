// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Hyperpolymath

/**
 * File-based preference provider using Deno file system APIs
 */

open Types

/** File format types */
type fileFormat =
  | JSON
  | Env

/** File provider configuration */
type config = {
  filePath: string,
  priority: preferencePriority,
  format: fileFormat,
  watchForChanges: bool,
}

/** File provider state */
type t = {
  name: string,
  config: config,
  mutable preferences: Js.Dict.t<preferenceMetadata>,
  mutable initialized: bool,
}

/** Deno file system bindings */
@val @scope("Deno") external readTextFile: string => promise<string> = "readTextFile"
@val @scope("Deno") external writeTextFile: (string, string) => promise<unit> = "writeTextFile"
@val @scope("Deno") external stat: string => promise<{..}> = "stat"

/** Check if file exists */
let fileExists = async (path: string): promise<bool> => {
  try {
    let _ = await stat(path)
    true
  } catch {
  | _ => false
  }
}

/** Create a new file provider */
let make = (~config: config): t => {
  name: "file",
  config,
  preferences: Js.Dict.empty(),
  initialized: false,
}

/** Parse a preference value from JSON */
let rec jsonToPreferenceValue = (json: Js.Json.t): preferenceValue => {
  switch Js.Json.classify(json) {
  | Js.Json.JSONString(s) => String(s)
  | Js.Json.JSONNumber(n) => Number(n)
  | Js.Json.JSONTrue => Bool(true)
  | Js.Json.JSONFalse => Bool(false)
  | Js.Json.JSONNull => Null
  | Js.Json.JSONArray(arr) => Array(arr->Array.map(jsonToPreferenceValue))
  | Js.Json.JSONObject(obj) => {
      let dict = Js.Dict.empty()
      Js.Dict.keys(obj)->Array.forEach(key => {
        switch Js.Dict.get(obj, key) {
        | Some(v) => Js.Dict.set(dict, key, jsonToPreferenceValue(v))
        | None => ()
        }
      })
      Object(dict)
    }
  }
}

/** Convert preference value to JSON */
let rec preferenceValueToJson = (value: preferenceValue): Js.Json.t => {
  switch value {
  | String(s) => Js.Json.string(s)
  | Number(n) => Js.Json.number(n)
  | Bool(b) => Js.Json.boolean(b)
  | Null => Js.Json.null
  | Array(arr) => Js.Json.array(arr->Array.map(preferenceValueToJson))
  | Object(dict) => {
      let obj = Js.Dict.empty()
      Js.Dict.keys(dict)->Array.forEach(key => {
        switch Js.Dict.get(dict, key) {
        | Some(v) => Js.Dict.set(obj, key, preferenceValueToJson(v))
        | None => ()
        }
      })
      Js.Json.object_(obj)
    }
  }
}

/** Parse .env file content */
let parseEnvFile = (content: string): Js.Dict.t<string> => {
  let result = Js.Dict.empty()
  let lines = String.split(content, ~sep="\n")
  lines->Array.forEach(line => {
    let trimmed = String.trim(line)
    if !String.startsWith(trimmed, ~search="#") && String.includes(trimmed, ~search="=") {
      let eqIndex = String.indexOf(trimmed, ~search="=")
      if eqIndex > 0 {
        let key = String.trim(String.slice(trimmed, ~start=0, ~end=eqIndex))
        let value = String.trim(String.sliceToEnd(trimmed, ~start=eqIndex + 1))
        // Remove quotes if present
        let cleanValue = if (
          (String.startsWith(value, ~search="\"") && String.endsWith(value, ~search="\"")) ||
            (String.startsWith(value, ~search="'") && String.endsWith(value, ~search="'"))
        ) {
          String.slice(value, ~start=1, ~end=String.length(value) - 1)
        } else {
          value
        }
        Js.Dict.set(result, key, cleanValue)
      }
    }
  })
  result
}

/** Serialize to .env format */
let serializeToEnv = (preferences: Js.Dict.t<preferenceMetadata>): string => {
  Js.Dict.keys(preferences)
  ->Array.map(key => {
    switch Js.Dict.get(preferences, key) {
    | Some(metadata) =>
      let valueStr = switch metadata.value {
      | String(s) =>
        if String.includes(s, ~search=" ") {
          `"${s}"`
        } else {
          s
        }
      | Number(n) => Float.toString(n)
      | Bool(b) =>
        if b {
          "true"
        } else {
          "false"
        }
      | Null => "null"
      | _ => Js.Json.stringify(preferenceValueToJson(metadata.value))
      }
      `${String.toUpperCase(key)}=${valueStr}`
    | None => ""
    }
  })
  ->Array.filter(s => s != "")
  ->Array.join("\n")
}

/** Load preferences from file */
let loadFromFile = async (provider: t): promise<unit> => {
  try {
    let exists = await fileExists(provider.config.filePath)
    if exists {
      let content = await readTextFile(provider.config.filePath)
      switch provider.config.format {
      | JSON => {
          let json = Js.Json.parseExn(content)
          switch Js.Json.classify(json) {
          | Js.Json.JSONObject(obj) =>
            Js.Dict.keys(obj)->Array.forEach(key => {
              switch Js.Dict.get(obj, key) {
              | Some(v) =>
                Js.Dict.set(
                  provider.preferences,
                  key,
                  {
                    key,
                    value: jsonToPreferenceValue(v),
                    priority: provider.config.priority,
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
          | _ => ()
          }
        }
      | Env => {
          let envDict = parseEnvFile(content)
          Js.Dict.keys(envDict)->Array.forEach(key => {
            switch Js.Dict.get(envDict, key) {
            | Some(value) =>
              Js.Dict.set(
                provider.preferences,
                String.toLowerCase(key),
                {
                  key: String.toLowerCase(key),
                  value: String(value),
                  priority: provider.config.priority,
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
        }
      }
    }
  } catch {
  | _ => Js.Console.error(`Failed to load preferences from ${provider.config.filePath}`)
  }
}

/** Save preferences to file */
let saveToFile = async (provider: t): promise<unit> => {
  try {
    let content = switch provider.config.format {
    | JSON => {
        let obj = Js.Dict.empty()
        Js.Dict.keys(provider.preferences)->Array.forEach(key => {
          switch Js.Dict.get(provider.preferences, key) {
          | Some(metadata) => Js.Dict.set(obj, key, preferenceValueToJson(metadata.value))
          | None => ()
          }
        })
        Js.Json.stringifyWithSpace(Js.Json.object_(obj), 2)
      }
    | Env => serializeToEnv(provider.preferences)
    }
    await writeTextFile(provider.config.filePath, content)
  } catch {
  | _ => Js.Console.error(`Failed to save preferences to ${provider.config.filePath}`)
  }
}

/** Initialize the provider */
let initialize = async (provider: t): promise<unit> => {
  if !provider.initialized {
    await loadFromFile(provider)
    provider.initialized = true
  }
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
      | None => provider.config.priority
      }
    | None => provider.config.priority
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
  await saveToFile(provider)
}

/** Check if a preference exists */
let has = async (provider: t, key: string): promise<bool> => {
  Js.Dict.get(provider.preferences, key)->Option.isSome
}

/** Delete a preference */
let delete = async (provider: t, key: string): promise<bool> => {
  let existed = Js.Dict.get(provider.preferences, key)->Option.isSome
  if existed {
    %raw(`delete provider.preferences[key]`)
    await saveToFile(provider)
  }
  existed
}

/** Clear all preferences */
let clear = async (provider: t): promise<unit> => {
  provider.preferences = Js.Dict.empty()
  await saveToFile(provider)
}
