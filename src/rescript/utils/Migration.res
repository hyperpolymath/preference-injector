// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Hyperpolymath

/**
 * Migration utilities for preference schema versioning
 */

open Types

/** Migration definition */
type migration = {
  version: int,
  name: string,
  up: Js.Dict.t<preferenceMetadata> => promise<Js.Dict.t<preferenceMetadata>>,
  down: Js.Dict.t<preferenceMetadata> => promise<Js.Dict.t<preferenceMetadata>>,
}

/** Create a migration */
let createMigration = (
  ~version: int,
  ~name: string,
  ~up: Js.Dict.t<preferenceMetadata> => promise<Js.Dict.t<preferenceMetadata>>,
  ~down: Js.Dict.t<preferenceMetadata> => promise<Js.Dict.t<preferenceMetadata>>,
): migration => {
  version,
  name,
  up,
  down,
}

/** Migration manager */
type migrationManager = {mutable migrations: array<migration>}

/** Create a new migration manager */
let make = (): migrationManager => {
  migrations: [],
}

/** Register a migration */
let register = (manager: migrationManager, migration: migration): unit => {
  manager.migrations = Array.concat(manager.migrations, [migration])
  // Sort by version
  manager.migrations =
    manager.migrations->Array.toSorted((a, b) => Float.fromInt(a.version - b.version))
}

/** Get all registered migrations */
let getMigrations = (manager: migrationManager): array<migration> => {
  manager.migrations
}

/** Get migration by version */
let getMigration = (manager: migrationManager, version: int): option<migration> => {
  manager.migrations->Array.find(m => m.version == version)
}

/** Get latest version */
let getLatestVersion = (manager: migrationManager): int => {
  switch manager.migrations[Array.length(manager.migrations) - 1] {
  | Some(m) => m.version
  | None => 0
  }
}

/** Migrate up to a specific version */
let rec migrateUp = async (
  manager: migrationManager,
  preferences: Js.Dict.t<preferenceMetadata>,
  fromVersion: int,
  toVersion: int,
): promise<result<Js.Dict.t<preferenceMetadata>, Errors.preferenceError>> => {
  if fromVersion >= toVersion {
    Ok(preferences)
  } else {
    let nextVersion = fromVersion + 1
    switch getMigration(manager, nextVersion) {
    | None =>
      Error(Errors.makeMigrationError(~version=nextVersion, ~direction="up", ~reason=Some("Migration not found")))
    | Some(migration) =>
      try {
        let migrated = await migration.up(preferences)
        await migrateUp(manager, migrated, nextVersion, toVersion)
      } catch {
      | Exn.Error(e) =>
        Error(
          Errors.makeMigrationError(
            ~version=nextVersion,
            ~direction="up",
            ~reason=Exn.message(e),
          ),
        )
      }
    }
  }
}

/** Migrate down to a specific version */
let rec migrateDown = async (
  manager: migrationManager,
  preferences: Js.Dict.t<preferenceMetadata>,
  fromVersion: int,
  toVersion: int,
): promise<result<Js.Dict.t<preferenceMetadata>, Errors.preferenceError>> => {
  if fromVersion <= toVersion {
    Ok(preferences)
  } else {
    switch getMigration(manager, fromVersion) {
    | None =>
      Error(Errors.makeMigrationError(~version=fromVersion, ~direction="down", ~reason=Some("Migration not found")))
    | Some(migration) =>
      try {
        let migrated = await migration.down(preferences)
        await migrateDown(manager, migrated, fromVersion - 1, toVersion)
      } catch {
      | Exn.Error(e) =>
        Error(
          Errors.makeMigrationError(
            ~version=fromVersion,
            ~direction="down",
            ~reason=Exn.message(e),
          ),
        )
      }
    }
  }
}

/** Migrate to a specific version (up or down) */
let migrateTo = async (
  manager: migrationManager,
  preferences: Js.Dict.t<preferenceMetadata>,
  fromVersion: int,
  toVersion: int,
): promise<result<Js.Dict.t<preferenceMetadata>, Errors.preferenceError>> => {
  if fromVersion < toVersion {
    await migrateUp(manager, preferences, fromVersion, toVersion)
  } else if fromVersion > toVersion {
    await migrateDown(manager, preferences, fromVersion, toVersion)
  } else {
    Ok(preferences)
  }
}

/** Migrate to the latest version */
let migrateToLatest = async (
  manager: migrationManager,
  preferences: Js.Dict.t<preferenceMetadata>,
  fromVersion: int,
): promise<result<Js.Dict.t<preferenceMetadata>, Errors.preferenceError>> => {
  let latestVersion = getLatestVersion(manager)
  await migrateUp(manager, preferences, fromVersion, latestVersion)
}

/** Migration helpers */
module Helpers = {
  /** Rename a preference key */
  let renameKey = (
    preferences: Js.Dict.t<preferenceMetadata>,
    ~from: string,
    ~to_: string,
  ): Js.Dict.t<preferenceMetadata> => {
    switch Js.Dict.get(preferences, from) {
    | Some(metadata) => {
        let newPrefs = Js.Dict.empty()
        Js.Dict.keys(preferences)->Array.forEach(key => {
          switch Js.Dict.get(preferences, key) {
          | Some(v) if key == from => Js.Dict.set(newPrefs, to_, {...v, key: to_})
          | Some(v) => Js.Dict.set(newPrefs, key, v)
          | None => ()
          }
        })
        newPrefs
      }
    | None => preferences
    }
  }

  /** Remove a preference key */
  let removeKey = (preferences: Js.Dict.t<preferenceMetadata>, key: string): Js.Dict.t<
    preferenceMetadata,
  > => {
    let newPrefs = Js.Dict.empty()
    Js.Dict.keys(preferences)->Array.forEach(k => {
      if k != key {
        switch Js.Dict.get(preferences, k) {
        | Some(v) => Js.Dict.set(newPrefs, k, v)
        | None => ()
        }
      }
    })
    newPrefs
  }

  /** Transform a preference value */
  let transformValue = (
    preferences: Js.Dict.t<preferenceMetadata>,
    key: string,
    transformer: preferenceValue => preferenceValue,
  ): Js.Dict.t<preferenceMetadata> => {
    switch Js.Dict.get(preferences, key) {
    | Some(metadata) => {
        let newValue = transformer(metadata.value)
        let newPrefs = Js.Dict.empty()
        Js.Dict.keys(preferences)->Array.forEach(k => {
          switch Js.Dict.get(preferences, k) {
          | Some(v) if k == key => Js.Dict.set(newPrefs, k, {...v, value: newValue})
          | Some(v) => Js.Dict.set(newPrefs, k, v)
          | None => ()
          }
        })
        newPrefs
      }
    | None => preferences
    }
  }

  /** Add a new preference with default value */
  let addDefault = (
    preferences: Js.Dict.t<preferenceMetadata>,
    ~key: string,
    ~value: preferenceValue,
    ~priority: preferencePriority,
    ~source: string,
  ): Js.Dict.t<preferenceMetadata> => {
    switch Js.Dict.get(preferences, key) {
    | Some(_) => preferences // Key already exists
    | None => {
        let newPrefs = Js.Dict.empty()
        Js.Dict.keys(preferences)->Array.forEach(k => {
          switch Js.Dict.get(preferences, k) {
          | Some(v) => Js.Dict.set(newPrefs, k, v)
          | None => ()
          }
        })
        Js.Dict.set(
          newPrefs,
          key,
          {
            key,
            value,
            priority,
            source,
            timestamp: Js.Date.make(),
            encrypted: None,
            validated: None,
            ttl: None,
          },
        )
        newPrefs
      }
    }
  }
}
