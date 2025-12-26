// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Hyperpolymath

/**
 * Validation utilities for preference values
 */

open Types

/** Validation rule definition */
type validationRule = {
  name: string,
  validate: preferenceValue => bool,
  message: string,
}

/** Validator state */
type t = {mutable rules: Js.Dict.t<array<validationRule>>}

/** Create a new validator */
let make = (): t => {
  rules: Js.Dict.empty(),
}

/** Add a validation rule for a key */
let addRule = (validator: t, key: string, rule: validationRule): unit => {
  let existingRules = switch Js.Dict.get(validator.rules, key) {
  | Some(rules) => rules
  | None => []
  }
  Js.Dict.set(validator.rules, key, Array.concat(existingRules, [rule]))
}

/** Remove a validation rule */
let removeRule = (validator: t, key: string, ruleName: string): unit => {
  switch Js.Dict.get(validator.rules, key) {
  | Some(rules) => {
      let filtered = rules->Array.filter(r => r.name != ruleName)
      Js.Dict.set(validator.rules, key, filtered)
    }
  | None => ()
  }
}

/** Validate a value against all rules for a key */
let validate = (validator: t, key: string, value: preferenceValue): validationResult => {
  switch Js.Dict.get(validator.rules, key) {
  | None => {valid: true, errors: []}
  | Some(rules) => {
      let errors =
        rules
        ->Array.filter(rule => !rule.validate(value))
        ->Array.map(rule => {
          rule: rule.name,
          message: rule.message,
          value,
        })
      {
        valid: Array.length(errors) == 0,
        errors,
      }
    }
  }
}

/** Common validation rules */
module CommonRules = {
  /** Required - value must not be null */
  let required = (): validationRule => {
    name: "required",
    validate: value =>
      switch value {
      | Null => false
      | _ => true
      },
    message: "Value is required",
  }

  /** String value must match pattern */
  let pattern = (regex: Js.Re.t): validationRule => {
    name: "pattern",
    validate: value =>
      switch value {
      | String(s) => Js.Re.test_(regex, s)
      | _ => false
      },
    message: "Value does not match required pattern",
  }

  /** Email format validation */
  let email = (): validationRule => {
    let emailRegex = %re("/^[^\s@]+@[^\s@]+\.[^\s@]+$/")
    {
      name: "email",
      validate: value =>
        switch value {
        | String(s) => Js.Re.test_(emailRegex, s)
        | _ => false
        },
      message: "Value must be a valid email address",
    }
  }

  /** URL format validation */
  let url = (): validationRule => {
    let urlRegex = %re("/^https?:\/\/[^\s]+$/")
    {
      name: "url",
      validate: value =>
        switch value {
        | String(s) => Js.Re.test_(urlRegex, s)
        | _ => false
        },
      message: "Value must be a valid URL",
    }
  }

  /** Number must be in range */
  let numberRange = (~min: float, ~max: float): validationRule => {
    name: "numberRange",
    validate: value =>
      switch value {
      | Number(n) => n >= min && n <= max
      | _ => false
      },
    message: `Value must be between ${Float.toString(min)} and ${Float.toString(max)}`,
  }

  /** Number must be positive */
  let positive = (): validationRule => {
    name: "positive",
    validate: value =>
      switch value {
      | Number(n) => n > 0.0
      | _ => false
      },
    message: "Value must be positive",
  }

  /** Number must be non-negative */
  let nonNegative = (): validationRule => {
    name: "nonNegative",
    validate: value =>
      switch value {
      | Number(n) => n >= 0.0
      | _ => false
      },
    message: "Value must be non-negative",
  }

  /** String length must be in range */
  let stringLength = (~min: int, ~max: int): validationRule => {
    name: "stringLength",
    validate: value =>
      switch value {
      | String(s) => {
          let len = String.length(s)
          len >= min && len <= max
        }
      | _ => false
      },
    message: `String length must be between ${Int.toString(min)} and ${Int.toString(max)}`,
  }

  /** String must not be empty */
  let nonEmpty = (): validationRule => {
    name: "nonEmpty",
    validate: value =>
      switch value {
      | String(s) => String.length(s) > 0
      | _ => false
      },
    message: "String must not be empty",
  }

  /** Value must be one of allowed values */
  let oneOf = (allowed: array<preferenceValue>): validationRule => {
    name: "oneOf",
    validate: value => allowed->Array.some(v => v == value),
    message: "Value must be one of the allowed values",
  }

  /** Array must have length in range */
  let arrayLength = (~min: int, ~max: int): validationRule => {
    name: "arrayLength",
    validate: value =>
      switch value {
      | Array(arr) => {
          let len = Array.length(arr)
          len >= min && len <= max
        }
      | _ => false
      },
    message: `Array length must be between ${Int.toString(min)} and ${Int.toString(max)}`,
  }

  /** Value must be a boolean */
  let boolean = (): validationRule => {
    name: "boolean",
    validate: value =>
      switch value {
      | Bool(_) => true
      | _ => false
      },
    message: "Value must be a boolean",
  }

  /** Value must be a number */
  let number = (): validationRule => {
    name: "number",
    validate: value =>
      switch value {
      | Number(_) => true
      | _ => false
      },
    message: "Value must be a number",
  }

  /** Value must be a string */
  let string = (): validationRule => {
    name: "string",
    validate: value =>
      switch value {
      | String(_) => true
      | _ => false
      },
    message: "Value must be a string",
  }
}
