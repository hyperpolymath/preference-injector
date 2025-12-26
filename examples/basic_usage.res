// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Hyperpolymath

/**
 * Basic usage example for Preference Injector
 */

open Types
open Injector

// Create an injector with a memory provider
let example = async () => {
  Js.Console.log("Preference Injector - Basic Usage Example")
  Js.Console.log("=========================================")

  // Create injector with configuration
  let injector = make(
    ~config=Some({
      conflictResolution: Some(HighestPriority),
      enableCache: Some(true),
      cacheTTL: Some(3600000),
      enableValidation: Some(true),
      enableEncryption: None,
      enableAudit: Some(true),
      encryptionKey: None,
    }),
  )

  // Create a memory provider
  let memProvider = MemoryProvider.make(~priority=Normal)

  // Wrap it as a provider interface
  let provider: provider = {
    name: memProvider.name,
    priority: memProvider.priority,
    initialize: () => MemoryProvider.initialize(memProvider),
    get: key => MemoryProvider.get(memProvider, key),
    getAll: () => MemoryProvider.getAll(memProvider),
    set: (key, value, opts) => MemoryProvider.set(memProvider, key, value, opts),
    has: key => MemoryProvider.has(memProvider, key),
    delete: key => MemoryProvider.delete(memProvider, key),
    clear: () => MemoryProvider.clear(memProvider),
  }

  // Add provider and initialize
  addProvider(injector, provider)
  await initialize(injector)

  Js.Console.log("✓ Injector initialized with memory provider")

  // Add validation rules
  addValidationRule(injector, "theme", Validator.CommonRules.oneOf([String("light"), String("dark")]))
  addValidationRule(injector, "fontSize", Validator.CommonRules.numberRange(~min=8.0, ~max=72.0))

  Js.Console.log("✓ Validation rules added")

  // Set preferences
  switch await set(injector, "theme", String("dark"), None) {
  | Ok() => Js.Console.log("✓ Set theme = dark")
  | Error(e) => Js.Console.error(`✗ Failed to set theme: ${e.message}`)
  }

  switch await set(injector, "fontSize", Number(14.0), None) {
  | Ok() => Js.Console.log("✓ Set fontSize = 14")
  | Error(e) => Js.Console.error(`✗ Failed to set fontSize: ${e.message}`)
  }

  switch await set(injector, "notifications", Bool(true), None) {
  | Ok() => Js.Console.log("✓ Set notifications = true")
  | Error(e) => Js.Console.error(`✗ Failed to set notifications: ${e.message}`)
  }

  // Get preferences
  switch await get(injector, "theme", None) {
  | Ok(String(value)) => Js.Console.log(`✓ Got theme = ${value}`)
  | Ok(_) => Js.Console.error("✗ Unexpected theme type")
  | Error(e) => Js.Console.error(`✗ Failed to get theme: ${e.message}`)
  }

  switch await get(injector, "fontSize", None) {
  | Ok(Number(value)) => Js.Console.log(`✓ Got fontSize = ${Float.toString(value)}`)
  | Ok(_) => Js.Console.error("✗ Unexpected fontSize type")
  | Error(e) => Js.Console.error(`✗ Failed to get fontSize: ${e.message}`)
  }

  // Get with default value
  switch await get(
    injector,
    "language",
    Some({defaultValue: Some(String("en")), decrypt: None, useCache: None}),
  ) {
  | Ok(String(value)) => Js.Console.log(`✓ Got language (default) = ${value}`)
  | Ok(_) => Js.Console.error("✗ Unexpected language type")
  | Error(e) => Js.Console.error(`✗ Failed to get language: ${e.message}`)
  }

  // Check existence
  let exists = await has(injector, "theme")
  Js.Console.log(`✓ Theme exists = ${exists ? "true" : "false"}`)

  // Get all preferences
  let all = await getAll(injector)
  Js.Console.log(`✓ Total preferences: ${Int.toString(Js.Dict.keys(all)->Array.length)}`)

  // Delete preference
  let deleted = await delete(injector, "notifications")
  Js.Console.log(`✓ Deleted notifications = ${deleted ? "true" : "false"}`)

  Js.Console.log("=========================================")
  Js.Console.log("Example complete!")
}

let _ = example()
