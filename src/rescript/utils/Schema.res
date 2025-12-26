// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Hyperpolymath

/**
 * Schema validation utilities for preference structures
 */

open Types

/** Schema builder for fluent API */
type schemaBuilder = {mutable fields: Js.Dict.t<schemaField>}

/** Create a new schema builder */
let make = (): schemaBuilder => {
  fields: Js.Dict.empty(),
}

/** Add a string field */
let string = (
  builder: schemaBuilder,
  ~name: string,
  ~required: option<bool>=?,
  ~defaultValue: option<string>=?,
  ~description: option<string>=?,
): schemaBuilder => {
  Js.Dict.set(
    builder.fields,
    name,
    {
      fieldType: StringType,
      required,
      defaultValue: switch defaultValue {
      | Some(s) => Some(String(s))
      | None => None
      },
      description,
      encrypted: None,
    },
  )
  builder
}

/** Add a number field */
let number = (
  builder: schemaBuilder,
  ~name: string,
  ~required: option<bool>=?,
  ~defaultValue: option<float>=?,
  ~description: option<string>=?,
): schemaBuilder => {
  Js.Dict.set(
    builder.fields,
    name,
    {
      fieldType: NumberType,
      required,
      defaultValue: switch defaultValue {
      | Some(n) => Some(Number(n))
      | None => None
      },
      description,
      encrypted: None,
    },
  )
  builder
}

/** Add a boolean field */
let boolean = (
  builder: schemaBuilder,
  ~name: string,
  ~required: option<bool>=?,
  ~defaultValue: option<bool>=?,
  ~description: option<string>=?,
): schemaBuilder => {
  Js.Dict.set(
    builder.fields,
    name,
    {
      fieldType: BooleanType,
      required,
      defaultValue: switch defaultValue {
      | Some(b) => Some(Bool(b))
      | None => None
      },
      description,
      encrypted: None,
    },
  )
  builder
}

/** Add an object field */
let object = (
  builder: schemaBuilder,
  ~name: string,
  ~required: option<bool>=?,
  ~description: option<string>=?,
): schemaBuilder => {
  Js.Dict.set(
    builder.fields,
    name,
    {
      fieldType: ObjectType,
      required,
      defaultValue: None,
      description,
      encrypted: None,
    },
  )
  builder
}

/** Add an array field */
let array = (
  builder: schemaBuilder,
  ~name: string,
  ~required: option<bool>=?,
  ~description: option<string>=?,
): schemaBuilder => {
  Js.Dict.set(
    builder.fields,
    name,
    {
      fieldType: ArrayType,
      required,
      defaultValue: None,
      description,
      encrypted: None,
    },
  )
  builder
}

/** Add an encrypted string field */
let encrypted = (
  builder: schemaBuilder,
  ~name: string,
  ~required: option<bool>=?,
  ~description: option<string>=?,
): schemaBuilder => {
  Js.Dict.set(
    builder.fields,
    name,
    {
      fieldType: StringType,
      required,
      defaultValue: None,
      description,
      encrypted: Some(true),
    },
  )
  builder
}

/** Build the schema */
let build = (builder: schemaBuilder): preferenceSchema => {
  builder.fields
}

/** Get the type of a preference value */
let getValueType = (value: preferenceValue): schemaFieldType => {
  switch value {
  | String(_) => StringType
  | Number(_) => NumberType
  | Bool(_) => BooleanType
  | Null => StringType // Treat null as string for validation
  | Object(_) => ObjectType
  | Array(_) => ArrayType
  }
}

/** Schema validator */
type schemaValidator = {schema: preferenceSchema}

let makeValidator = (schema: preferenceSchema): schemaValidator => {
  schema: schema,
}

/** Validate a single field */
let validateField = (
  validator: schemaValidator,
  key: string,
  value: preferenceValue,
): validationResult => {
  switch Js.Dict.get(validator.schema, key) {
  | None => {valid: true, errors: []} // Unknown fields are valid
  | Some(field) => {
      let errors = []

      // Check required
      switch (field.required, value) {
      | (Some(true), Null) =>
        Array.concat(errors, [{rule: "required", message: `${key} is required`, value}])
      | _ => errors
      }

      // Check type
      let valueType = getValueType(value)
      if valueType != field.fieldType && value != Null {
        let expectedStr = switch field.fieldType {
        | StringType => "string"
        | NumberType => "number"
        | BooleanType => "boolean"
        | ObjectType => "object"
        | ArrayType => "array"
        }
        let receivedStr = switch valueType {
        | StringType => "string"
        | NumberType => "number"
        | BooleanType => "boolean"
        | ObjectType => "object"
        | ArrayType => "array"
        }
        Array.concat(
          errors,
          [{rule: "type", message: `Expected ${expectedStr}, got ${receivedStr}`, value}],
        )
      } else {
        errors
      }
    }->((errs): validationResult => {valid: Array.length(errs) == 0, errors: errs})
  }
}

/** Validate all fields in a preference map */
let validateAll = (
  validator: schemaValidator,
  preferences: Js.Dict.t<preferenceValue>,
): validationResult => {
  let allErrors = []

  // Check all schema fields
  Js.Dict.keys(validator.schema)->Array.forEach(key => {
    let value = switch Js.Dict.get(preferences, key) {
    | Some(v) => v
    | None => Null
    }
    let result = validateField(validator, key, value)
    if !result.valid {
      ignore(Array.concat(allErrors, result.errors))
    }
  })

  // Check provided values against schema
  Js.Dict.keys(preferences)->Array.forEach(key => {
    switch Js.Dict.get(preferences, key) {
    | Some(value) => {
        let result = validateField(validator, key, value)
        if !result.valid {
          ignore(Array.concat(allErrors, result.errors))
        }
      }
    | None => ()
    }
  })

  {valid: Array.length(allErrors) == 0, errors: allErrors}
}

/** Get default values from schema */
let getDefaults = (schema: preferenceSchema): Js.Dict.t<preferenceValue> => {
  let defaults = Js.Dict.empty()
  Js.Dict.keys(schema)->Array.forEach(key => {
    switch Js.Dict.get(schema, key) {
    | Some(field) =>
      switch field.defaultValue {
      | Some(v) => Js.Dict.set(defaults, key, v)
      | None => ()
      }
    | None => ()
    }
  })
  defaults
}
