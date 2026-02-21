// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Hyperpolymath

/**
 * Preference Injector — High-Assurance Dynamic Configuration.
 *
 * This module acts as the central hub for the `preference-injector` library.
 * It provides a type-safe interface for managing user preferences and 
 * application configurations across distributed systems.
 *
 * CORE CAPABILITIES:
 * 1. MULTI-PROVIDER: Ingests data from ENV, Files, APIs, or Memory.
 * 2. CRDT-BASED SYNC: Uses Conflict-free Replicated Data Types to ensure 
 *    consistency across multiple nodes without a central authority.
 * 3. SECURITY: Built-in KDF and Encryption for sensitive preference fields.
 * 4. VALIDATION: Schema-driven verification of preference values.
 */

// EXPORT MAP: Exposes the primary building blocks of the injector system.
module Types = Types
module Errors = Errors
module Injector = Injector

// DATA PROVIDERS: Specialized modules for data retrieval.
module MemoryProvider = MemoryProvider
module EnvProvider = EnvProvider
module FileProvider = FileProvider
module ApiProvider = ApiProvider

// CONFLICT RESOLUTION: Implementation of various CRDT strategies.
module CRDTTypes = Types
module GCounter = GCounter
module LWWRegister = LWWRegister
module LWWMap = LWWMap
module ORSet = ORSet

// CRYPTOGRAPHIC KERNEL: Primitives for securing configuration state.
module CryptoConstants = Constants
module Hashing = Hashing
module KDF = KDF
module Signatures = Signatures
