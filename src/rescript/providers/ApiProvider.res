// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Hyperpolymath

/**
 * API-based preference provider for remote configuration services
 */

open Types

/** API provider configuration */
type config = {
  baseUrl: string,
  apiKey: option<string>,
  headers: Js.Dict.t<string>,
  priority: preferencePriority,
  timeout: int,
  retries: int,
}

/** API provider state */
type t = {
  name: string,
  config: config,
  mutable cache: Js.Dict.t<preferenceMetadata>,
  mutable initialized: bool,
}

/** Default configuration */
let defaultConfig = (~baseUrl: string): config => {
  baseUrl,
  apiKey: None,
  headers: Js.Dict.empty(),
  priority: Normal,
  timeout: 5000,
  retries: 3,
}

/** Create a new API provider */
let make = (~config: config): t => {
  name: "api",
  config,
  cache: Js.Dict.empty(),
  initialized: false,
}

/** Build headers for requests */
let buildHeaders = (provider: t): Js.Dict.t<string> => {
  let headers = Js.Dict.empty()
  Js.Dict.set(headers, "Content-Type", "application/json")

  // Add custom headers
  Js.Dict.keys(provider.config.headers)->Array.forEach(key => {
    switch Js.Dict.get(provider.config.headers, key) {
    | Some(value) => Js.Dict.set(headers, key, value)
    | None => ()
    }
  })

  // Add API key if present
  switch provider.config.apiKey {
  | Some(key) => Js.Dict.set(headers, "Authorization", `Bearer ${key}`)
  | None => ()
  }

  headers
}

/** Fetch with timeout and retries */
let fetchWithRetry = async (
  url: string,
  options: {..},
  retries: int,
  timeout: int,
): promise<Fetch.Response.t> => {
  ignore(timeout) // Would use AbortController in full implementation
  let rec attempt = async (remainingRetries: int): promise<Fetch.Response.t> => {
    try {
      await Fetch.fetch(url, options)
    } catch {
    | Exn.Error(_) as e =>
      if remainingRetries > 0 {
        await attempt(remainingRetries - 1)
      } else {
        raise(e)
      }
    }
  }
  await attempt(retries)
}

/** Convert JSON to preference value */
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

/** Initialize the provider by fetching all preferences */
let initialize = async (provider: t): promise<unit> => {
  if !provider.initialized {
    try {
      let headers = buildHeaders(provider)
      let response = await fetchWithRetry(
        `${provider.config.baseUrl}/preferences`,
        {"method": "GET", "headers": headers},
        provider.config.retries,
        provider.config.timeout,
      )

      if Fetch.Response.ok(response) {
        let json = await Fetch.Response.json(response)
        switch Js.Json.classify(json) {
        | Js.Json.JSONObject(obj) =>
          Js.Dict.keys(obj)->Array.forEach(key => {
            switch Js.Dict.get(obj, key) {
            | Some(v) =>
              Js.Dict.set(
                provider.cache,
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
      provider.initialized = true
    } catch {
    | _ => Js.Console.error(`Failed to initialize API provider from ${provider.config.baseUrl}`)
    }
  }
}

/** Get a preference */
let get = async (provider: t, key: string): promise<option<preferenceMetadata>> => {
  // Check cache first
  switch Js.Dict.get(provider.cache, key) {
  | Some(cached) => Some(cached)
  | None =>
    // Fetch from API
    try {
      let headers = buildHeaders(provider)
      let response = await fetchWithRetry(
        `${provider.config.baseUrl}/preferences/${key}`,
        {"method": "GET", "headers": headers},
        provider.config.retries,
        provider.config.timeout,
      )

      if Fetch.Response.ok(response) {
        let json = await Fetch.Response.json(response)
        let metadata = {
          key,
          value: jsonToPreferenceValue(json),
          priority: provider.config.priority,
          source: provider.name,
          timestamp: Js.Date.make(),
          encrypted: None,
          validated: None,
          ttl: None,
        }
        Js.Dict.set(provider.cache, key, metadata)
        Some(metadata)
      } else {
        None
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

/** Set a preference */
let set = async (
  provider: t,
  key: string,
  value: preferenceValue,
  options: option<setOptions>,
): promise<unit> => {
  try {
    let headers = buildHeaders(provider)
    let body = Js.Json.stringify(preferenceValueToJson(value))
    let response = await fetchWithRetry(
      `${provider.config.baseUrl}/preferences/${key}`,
      {"method": "PUT", "headers": headers, "body": body},
      provider.config.retries,
      provider.config.timeout,
    )

    if Fetch.Response.ok(response) {
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
      Js.Dict.set(provider.cache, key, metadata)
    }
  } catch {
  | _ => Js.Console.error(`Failed to set preference ${key} via API`)
  }
}

/** Check if a preference exists */
let has = async (provider: t, key: string): promise<bool> => {
  let result = await get(provider, key)
  Option.isSome(result)
}

/** Delete a preference */
let delete = async (provider: t, key: string): promise<bool> => {
  try {
    let headers = buildHeaders(provider)
    let response = await fetchWithRetry(
      `${provider.config.baseUrl}/preferences/${key}`,
      {"method": "DELETE", "headers": headers},
      provider.config.retries,
      provider.config.timeout,
    )

    if Fetch.Response.ok(response) {
      %raw(`delete provider.cache[key]`)
      true
    } else {
      false
    }
  } catch {
  | _ => false
  }
}

/** Clear all preferences */
let clear = async (provider: t): promise<unit> => {
  try {
    let headers = buildHeaders(provider)
    let _ = await fetchWithRetry(
      `${provider.config.baseUrl}/preferences`,
      {"method": "DELETE", "headers": headers},
      provider.config.retries,
      provider.config.timeout,
    )
    provider.cache = Js.Dict.empty()
  } catch {
  | _ => Js.Console.error("Failed to clear preferences via API")
  }
}
