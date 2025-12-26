// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Hyperpolymath

/**
 * Core type definitions for the preference injection system
 */

/** Preference value types that can be stored and injected */
@genType
type rec preferenceValue =
  | String(string)
  | Number(float)
  | Bool(bool)
  | Null
  | Object(Js.Dict.t<preferenceValue>)
  | Array(array<preferenceValue>)

/** Priority levels for preference resolution */
@genType
type preferencePriority =
  | Lowest
  | Low
  | Normal
  | High
  | Highest

let priorityToInt = (p: preferencePriority): int => {
  switch p {
  | Lowest => 0
  | Low => 25
  | Normal => 50
  | High => 75
  | Highest => 100
  }
}

let intToPriority = (n: int): preferencePriority => {
  if n <= 0 {
    Lowest
  } else if n <= 25 {
    Low
  } else if n <= 50 {
    Normal
  } else if n <= 75 {
    High
  } else {
    Highest
  }
}

/** Conflict resolution strategies */
@genType
type conflictResolution =
  | HighestPriority
  | LowestPriority
  | Merge
  | Override
  | Error

/** Preference metadata */
@genType
type preferenceMetadata = {
  key: string,
  value: preferenceValue,
  priority: preferencePriority,
  source: string,
  timestamp: Js.Date.t,
  encrypted: option<bool>,
  validated: option<bool>,
  ttl: option<int>,
}

/** Options for setting preferences */
@genType
type setOptions = {
  priority: option<preferencePriority>,
  ttl: option<int>,
  encrypt: option<bool>,
  validate: option<bool>,
}

/** Options for getting preferences */
@genType
type getOptions = {
  defaultValue: option<preferenceValue>,
  decrypt: option<bool>,
  useCache: option<bool>,
}

/** Validation error */
@genType
type validationError = {
  rule: string,
  message: string,
  value: preferenceValue,
}

/** Validation result */
@genType
type validationResult = {
  valid: bool,
  errors: array<validationError>,
}

/** Audit actions */
@genType
type auditAction =
  | Get
  | Set
  | Delete
  | Clear
  | Validate
  | Encrypt
  | Decrypt

let auditActionToString = (action: auditAction): string => {
  switch action {
  | Get => "get"
  | Set => "set"
  | Delete => "delete"
  | Clear => "clear"
  | Validate => "validate"
  | Encrypt => "encrypt"
  | Decrypt => "decrypt"
  }
}

/** Audit log entry */
@genType
type auditLogEntry = {
  timestamp: Js.Date.t,
  action: auditAction,
  key: string,
  value: option<preferenceValue>,
  oldValue: option<preferenceValue>,
  provider: string,
  userId: option<string>,
}

/** Audit filter */
@genType
type auditFilter = {
  action: option<auditAction>,
  key: option<string>,
  provider: option<string>,
  startDate: option<Js.Date.t>,
  endDate: option<Js.Date.t>,
  userId: option<string>,
}

/** Event types for preference changes */
@genType
type preferenceEvent =
  | Changed
  | Added
  | Removed
  | Cleared

/** Preference change event */
@genType
type preferenceChangeEvent = {
  eventType: preferenceEvent,
  key: string,
  newValue: option<preferenceValue>,
  oldValue: option<preferenceValue>,
  provider: string,
  timestamp: Js.Date.t,
}

/** Provider configuration for file-based provider */
@genType
type fileProviderConfig = {
  filePath: string,
  priority: option<preferencePriority>,
  watchForChanges: option<bool>,
  format: option<string>,
}

/** Provider configuration for API-based provider */
@genType
type apiProviderConfig = {
  baseUrl: string,
  apiKey: option<string>,
  headers: option<Js.Dict.t<string>>,
  priority: option<preferencePriority>,
  timeout: option<int>,
  retries: option<int>,
}

/** Provider configuration for environment variable provider */
@genType
type envProviderConfig = {
  prefix: option<string>,
  priority: option<preferencePriority>,
  parseValues: option<bool>,
}

/** Schema field types */
@genType
type schemaFieldType =
  | StringType
  | NumberType
  | BooleanType
  | ObjectType
  | ArrayType

/** Schema field definition */
@genType
type schemaField = {
  fieldType: schemaFieldType,
  required: option<bool>,
  defaultValue: option<preferenceValue>,
  description: option<string>,
  encrypted: option<bool>,
}

/** Schema definition for preferences */
@genType
type preferenceSchema = Js.Dict.t<schemaField>

/** Injector configuration */
@genType
type injectorConfig = {
  conflictResolution: option<conflictResolution>,
  enableCache: option<bool>,
  cacheTTL: option<int>,
  enableValidation: option<bool>,
  enableEncryption: option<bool>,
  enableAudit: option<bool>,
  encryptionKey: option<string>,
}
