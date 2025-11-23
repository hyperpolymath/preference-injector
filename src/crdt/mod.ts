/**
 * CRDT (Conflict-free Replicated Data Types) Module
 *
 * Implements CRDTs for distributed state management without conflicts.
 * Enables offline-first synchronization with automatic conflict resolution.
 *
 * Supported CRDTs:
 * - G-Counter: Grow-only counter
 * - PN-Counter: Positive-negative counter
 * - LWW-Register: Last-write-wins register
 * - OR-Set: Observed-remove set
 * - LWW-Map: Last-write-wins map
 *
 * @module crdt
 */

export * from './types.ts'
export * from './gcounter.ts'
export * from './pncounter.ts'
export * from './lww-register.ts'
export * from './or-set.ts'
export * from './lww-map.ts'
export * from './merge.ts'
