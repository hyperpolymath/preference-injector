/**
 * CRDT Type Definitions
 * @module crdt/types
 */

/**
 * Replica identifier (unique per client/node)
 */
export type ReplicaId = string

/**
 * Logical timestamp for causality tracking
 */
export type Timestamp = number

/**
 * Vector clock for causal ordering
 */
export type VectorClock = Map<ReplicaId, Timestamp>

/**
 * Base CRDT interface
 */
export interface CRDT<T> {
  /**
   * Merge this CRDT with another replica's state
   * @param other - Other CRDT state to merge
   */
  merge(other: T): void

  /**
   * Get current value
   */
  value(): unknown

  /**
   * Serialize to JSON
   */
  toJSON(): unknown

  /**
   * Get replica ID
   */
  getReplicaId(): ReplicaId
}

/**
 * G-Counter state (Grow-only counter)
 */
export interface GCounterState {
  replicaId: ReplicaId
  counts: Map<ReplicaId, number>
}

/**
 * PN-Counter state (Positive-Negative counter)
 */
export interface PNCounterState {
  replicaId: ReplicaId
  increments: Map<ReplicaId, number>
  decrements: Map<ReplicaId, number>
}

/**
 * LWW-Register state (Last-Write-Wins register)
 */
export interface LWWRegisterState<T> {
  replicaId: ReplicaId
  value: T
  timestamp: Timestamp
  vectorClock: VectorClock
}

/**
 * OR-Set state (Observed-Remove set)
 */
export interface ORSetState<T> {
  replicaId: ReplicaId
  elements: Map<string, { value: T; timestamp: Timestamp; tag: string }>
  tombstones: Set<string>
}

/**
 * LWW-Map state (Last-Write-Wins map)
 */
export interface LWWMapState<K extends string, V> {
  replicaId: ReplicaId
  entries: Map<K, { value: V; timestamp: Timestamp; deleted: boolean }>
}

/**
 * Merge result
 */
export interface MergeResult {
  /** Whether merge caused state change */
  changed: boolean

  /** Number of conflicts resolved */
  conflicts: number
}

/**
 * Sync message for CRDT replication
 */
export interface SyncMessage<T> {
  /** Source replica ID */
  from: ReplicaId

  /** Target replica ID (optional, for unicast) */
  to?: ReplicaId

  /** CRDT type */
  type: 'g-counter' | 'pn-counter' | 'lww-register' | 'or-set' | 'lww-map'

  /** CRDT state */
  state: T

  /** Vector clock for causality */
  vectorClock: VectorClock

  /** Timestamp */
  timestamp: Timestamp
}
