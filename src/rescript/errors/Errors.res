// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Hyperpolymath

/**
 * Custom error types for the preference injection system
 */

/** Error codes for preference errors */
type errorCode =
  | PreferenceNotFound
  | ValidationFailed
  | ConflictDetected
  | EncryptionFailed
  | ProviderInitFailed
  | ProviderOperationFailed
  | SchemaValidationFailed
  | MigrationFailed
  | ConfigurationInvalid
  | TypeMismatch

let errorCodeToString = (code: errorCode): string => {
  switch code {
  | PreferenceNotFound => "PREFERENCE_NOT_FOUND"
  | ValidationFailed => "VALIDATION_ERROR"
  | ConflictDetected => "CONFLICT_ERROR"
  | EncryptionFailed => "ENCRYPTION_ERROR"
  | ProviderInitFailed => "PROVIDER_INIT_ERROR"
  | ProviderOperationFailed => "PROVIDER_ERROR"
  | SchemaValidationFailed => "SCHEMA_VALIDATION_ERROR"
  | MigrationFailed => "MIGRATION_ERROR"
  | ConfigurationInvalid => "CONFIGURATION_ERROR"
  | TypeMismatch => "TYPE_MISMATCH_ERROR"
  }
}

/** Base preference error type */
type preferenceError = {
  message: string,
  code: errorCode,
  key: option<string>,
  provider: option<string>,
  details: option<string>,
}

/** Create a preference not found error */
let makeNotFoundError = (~key: string, ~provider: option<string>=?): preferenceError => {
  let providerMsg = switch provider {
  | Some(p) => ` in provider ${p}`
  | None => ""
  }
  {
    message: `Preference not found: ${key}${providerMsg}`,
    code: PreferenceNotFound,
    key: Some(key),
    provider,
    details: None,
  }
}

/** Create a validation error */
let makeValidationError = (
  ~key: string,
  ~errors: array<{.."rule": string, "message": string}>,
): preferenceError => {
  let errorMsgs = errors->Array.map(e => `${e["rule"]}: ${e["message"]}`)->Array.join(", ")
  {
    message: `Validation failed for ${key}: ${errorMsgs}`,
    code: ValidationFailed,
    key: Some(key),
    provider: None,
    details: Some(errorMsgs),
  }
}

/** Create a conflict error */
let makeConflictError = (~key: string, ~providers: array<string>): preferenceError => {
  let providerList = providers->Array.join(", ")
  {
    message: `Conflict detected for preference ${key} from providers: ${providerList}`,
    code: ConflictDetected,
    key: Some(key),
    provider: None,
    details: Some(providerList),
  }
}

/** Create an encryption error */
let makeEncryptionError = (~message: string): preferenceError => {
  {
    message: `Encryption error: ${message}`,
    code: EncryptionFailed,
    key: None,
    provider: None,
    details: Some(message),
  }
}

/** Create a provider initialization error */
let makeProviderInitError = (~provider: string, ~reason: option<string>=?): preferenceError => {
  let reasonMsg = switch reason {
  | Some(r) => r
  | None => "Unknown error"
  }
  {
    message: `Failed to initialize provider ${provider}: ${reasonMsg}`,
    code: ProviderInitFailed,
    key: None,
    provider: Some(provider),
    details: reason,
  }
}

/** Create a provider operation error */
let makeProviderError = (
  ~provider: string,
  ~operation: string,
  ~reason: option<string>=?,
): preferenceError => {
  let reasonMsg = switch reason {
  | Some(r) => r
  | None => "Unknown error"
  }
  {
    message: `Provider ${provider} failed during ${operation}: ${reasonMsg}`,
    code: ProviderOperationFailed,
    key: None,
    provider: Some(provider),
    details: reason,
  }
}

/** Create a schema validation error */
let makeSchemaValidationError = (
  ~key: string,
  ~expected: string,
  ~received: string,
): preferenceError => {
  {
    message: `Schema validation failed for ${key}: expected ${expected}, received ${received}`,
    code: SchemaValidationFailed,
    key: Some(key),
    provider: None,
    details: Some(`expected ${expected}, received ${received}`),
  }
}

/** Create a migration error */
let makeMigrationError = (~version: int, ~direction: string, ~reason: option<string>=?): preferenceError => {
  let reasonMsg = switch reason {
  | Some(r) => r
  | None => "Unknown error"
  }
  {
    message: `Migration ${direction} to version ${Int.toString(version)} failed: ${reasonMsg}`,
    code: MigrationFailed,
    key: None,
    provider: None,
    details: reason,
  }
}

/** Create a configuration error */
let makeConfigurationError = (~message: string): preferenceError => {
  {
    message: `Configuration error: ${message}`,
    code: ConfigurationInvalid,
    key: None,
    provider: None,
    details: Some(message),
  }
}

/** Create a type mismatch error */
let makeTypeMismatchError = (~key: string, ~expected: string, ~received: string): preferenceError => {
  {
    message: `Type mismatch for ${key}: expected ${expected}, received ${received}`,
    code: TypeMismatch,
    key: Some(key),
    provider: None,
    details: Some(`expected ${expected}, received ${received}`),
  }
}

/** Result type for operations that can fail */
type result<'a> = Result.t<'a, preferenceError>
