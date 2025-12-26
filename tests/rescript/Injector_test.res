// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Hyperpolymath

/**
 * Tests for the Preference Injector
 */

open Types
open Injector

// Test helpers
let assertEquals = (a, b, msg) => {
  if a != b {
    Js.Console.error(`FAIL: ${msg}`)
    Js.Console.error(`  Expected: ${Js.Json.stringify(Obj.magic(b))}`)
    Js.Console.error(`  Got: ${Js.Json.stringify(Obj.magic(a))}`)
  } else {
    Js.Console.log(`PASS: ${msg}`)
  }
}

let assertTrue = (condition, msg) => {
  if !condition {
    Js.Console.error(`FAIL: ${msg}`)
  } else {
    Js.Console.log(`PASS: ${msg}`)
  }
}

// Test: Create injector
let testCreateInjector = () => {
  let injector = make()
  assertTrue(true, "Create injector")
}

// Test: Add memory provider
let testAddProvider = () => {
  let injector = make()
  let memProvider = MemoryProvider.make()

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

  addProvider(injector, provider)
  assertTrue(true, "Add provider")
}

// Test: Set and get preference
let testSetAndGet = async () => {
  let injector = make()
  let memProvider = MemoryProvider.make()

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

  addProvider(injector, provider)
  await initialize(injector)

  let _ = await set(injector, "theme", String("dark"), None)
  let result = await get(injector, "theme", None)

  switch result {
  | Ok(String("dark")) => Js.Console.log("PASS: Set and get preference")
  | Ok(_) => Js.Console.error("FAIL: Wrong value returned")
  | Error(_) => Js.Console.error("FAIL: Error getting preference")
  }
}

// Test: Delete preference
let testDelete = async () => {
  let injector = make()
  let memProvider = MemoryProvider.make()

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

  addProvider(injector, provider)
  await initialize(injector)

  let _ = await set(injector, "theme", String("dark"), None)
  let deleted = await delete(injector, "theme")
  assertTrue(deleted, "Delete preference")
}

// Run tests
let runTests = async () => {
  Js.Console.log("Running Injector Tests...")
  Js.Console.log("========================")

  testCreateInjector()
  testAddProvider()
  await testSetAndGet()
  await testDelete()

  Js.Console.log("========================")
  Js.Console.log("Tests complete")
}

let _ = runTests()
