// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Hyperpolymath

/**
 * Preference Injector
 * A powerful, type-safe preference injection system for dynamic configuration management
 *
 * This is the main entry point for the library.
 */

// Re-export all types
module Types = Types

// Re-export errors
module Errors = Errors

// Re-export core injector
module Injector = Injector

// Re-export providers
module MemoryProvider = MemoryProvider
module EnvProvider = EnvProvider
module FileProvider = FileProvider
module ApiProvider = ApiProvider

// Re-export utilities
module Cache = Cache
module Validator = Validator
module Audit = Audit
module ConflictResolver = ConflictResolver
module Encryption = Encryption
module Schema = Schema
module Migration = Migration

// Re-export CRDT modules
module CRDTTypes = Types
module GCounter = GCounter
module PNCounter = PNCounter
module LWWRegister = LWWRegister
module LWWMap = LWWMap
module ORSet = ORSet
module Merge = Merge

// Re-export crypto modules
module CryptoConstants = Constants
module Hashing = Hashing
module KDF = KDF
module Signatures = Signatures
module KeyExchange = KeyExchange
