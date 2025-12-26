// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Hyperpolymath

/**
 * Tests for the Validator module
 */

open Types
open Validator

// Test: Create validator
let testCreateValidator = () => {
  let validator = make()
  Js.Console.log("PASS: Create validator")
  ignore(validator)
}

// Test: Add and validate rule
let testValidateRequired = () => {
  let validator = make()
  addRule(validator, "name", CommonRules.required())

  let result1 = validate(validator, "name", String("John"))
  let result2 = validate(validator, "name", Null)

  if result1.valid && !result2.valid {
    Js.Console.log("PASS: Required validation")
  } else {
    Js.Console.error("FAIL: Required validation")
  }
}

// Test: Email validation
let testValidateEmail = () => {
  let validator = make()
  addRule(validator, "email", CommonRules.email())

  let result1 = validate(validator, "email", String("test@example.com"))
  let result2 = validate(validator, "email", String("invalid-email"))

  if result1.valid && !result2.valid {
    Js.Console.log("PASS: Email validation")
  } else {
    Js.Console.error("FAIL: Email validation")
  }
}

// Test: Number range validation
let testValidateNumberRange = () => {
  let validator = make()
  addRule(validator, "age", CommonRules.numberRange(~min=0.0, ~max=150.0))

  let result1 = validate(validator, "age", Number(25.0))
  let result2 = validate(validator, "age", Number(-5.0))
  let result3 = validate(validator, "age", Number(200.0))

  if result1.valid && !result2.valid && !result3.valid {
    Js.Console.log("PASS: Number range validation")
  } else {
    Js.Console.error("FAIL: Number range validation")
  }
}

// Test: String length validation
let testValidateStringLength = () => {
  let validator = make()
  addRule(validator, "username", CommonRules.stringLength(~min=3, ~max=20))

  let result1 = validate(validator, "username", String("john"))
  let result2 = validate(validator, "username", String("ab"))
  let result3 = validate(validator, "username", String("thisisaverylongusernamethatexceedsthelimit"))

  if result1.valid && !result2.valid && !result3.valid {
    Js.Console.log("PASS: String length validation")
  } else {
    Js.Console.error("FAIL: String length validation")
  }
}

// Run tests
let runTests = () => {
  Js.Console.log("Running Validator Tests...")
  Js.Console.log("=========================")

  testCreateValidator()
  testValidateRequired()
  testValidateEmail()
  testValidateNumberRange()
  testValidateStringLength()

  Js.Console.log("=========================")
  Js.Console.log("Tests complete")
}

let _ = runTests()
