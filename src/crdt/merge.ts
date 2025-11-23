/**
 * CRDT Merge Utilities
 *
 * Helper functions for merging and synchronizing CRDTs
 *
 * @module crdt/merge
 */

import type { SyncMessage, VectorClock } from './types.ts'
import { GCounter } from './gcounter.ts'
import { PNCounter } from './pncounter.ts'
import { LWWRegister } from './lww-register.ts'
import { ORSet } from './or-set.ts'
import { LWWMap } from './lww-map.ts'

/**
 * Merge two vector clocks
 * @param clock1 - First vector clock
 * @param clock2 - Second vector clock
 * @returns Merged vector clock (maximum of each replica)
 */
export function mergeVectorClocks(
  clock1: VectorClock,
  clock2: VectorClock,
): VectorClock {
  const merged = new Map(clock1)

  for (const [replicaId, clock] of clock2) {
    const currentClock = merged.get(replicaId) ?? 0
    merged.set(replicaId, Math.max(currentClock, clock))
  }

  return merged
}

/**
 * Compare two vector clocks
 * @param clock1 - First vector clock
 * @param clock2 - Second vector clock
 * @returns -1 if clock1 < clock2, 0 if concurrent, 1 if clock1 > clock2
 */
export function compareVectorClocks(
  clock1: VectorClock,
  clock2: VectorClock,
): -1 | 0 | 1 {
  let less = false
  let greater = false

  // Check all replicas in clock1
  for (const [replicaId, clock] of clock1) {
    const otherClock = clock2.get(replicaId) ?? 0

    if (clock < otherClock) {
      less = true
    } else if (clock > otherClock) {
      greater = true
    }
  }

  // Check replicas only in clock2
  for (const [replicaId, clock] of clock2) {
    if (!clock1.has(replicaId)) {
      if (clock > 0) {
        less = true
      }
    }
  }

  if (less && greater) {
    return 0 // Concurrent
  } else if (less) {
    return -1 // clock1 < clock2
  } else if (greater) {
    return 1 // clock1 > clock2
  }

  return 0 // Equal
}

/**
 * Check if one vector clock happened before another
 * @param clock1 - First vector clock
 * @param clock2 - Second vector clock
 * @returns true if clock1 <= clock2 for all replicas
 */
export function happenedBefore(
  clock1: VectorClock,
  clock2: VectorClock,
): boolean {
  for (const [replicaId, clock] of clock1) {
    const otherClock = clock2.get(replicaId) ?? 0
    if (clock > otherClock) {
      return false
    }
  }
  return true
}

/**
 * Check if two vector clocks are concurrent
 * @param clock1 - First vector clock
 * @param clock2 - Second vector clock
 * @returns true if neither happened before the other
 */
export function isConcurrent(
  clock1: VectorClock,
  clock2: VectorClock,
): boolean {
  return !happenedBefore(clock1, clock2) &&
    !happenedBefore(clock2, clock1)
}

/**
 * Create a sync message for a CRDT
 * @param crdt - CRDT instance
 * @param to - Optional target replica ID
 * @returns Sync message
 */
export function createSyncMessage<T>(
  crdt: any,
  to?: string,
): SyncMessage<T> {
  const state = crdt.getState()

  return {
    from: crdt.getReplicaId(),
    to,
    type: determineCRDTType(crdt),
    state,
    vectorClock: state.vectorClock ?? new Map(),
    timestamp: Date.now(),
  }
}

/**
 * Determine CRDT type from instance
 */
function determineCRDTType(
  crdt: any,
): 'g-counter' | 'pn-counter' | 'lww-register' | 'or-set' | 'lww-map' {
  if (crdt instanceof GCounter) return 'g-counter'
  if (crdt instanceof PNCounter) return 'pn-counter'
  if (crdt instanceof LWWRegister) return 'lww-register'
  if (crdt instanceof ORSet) return 'or-set'
  if (crdt instanceof LWWMap) return 'lww-map'

  throw new Error('Unknown CRDT type')
}

/**
 * Serialize CRDT for transmission
 * @param crdt - CRDT instance
 * @returns JSON string
 */
export function serializeCRDT(crdt: any): string {
  return JSON.stringify(crdt.toJSON())
}

/**
 * Deserialize CRDT from JSON
 * @param json - JSON string
 * @param type - CRDT type
 * @returns CRDT instance
 */
export function deserializeCRDT(json: string, type: string): any {
  const data = JSON.parse(json)

  switch (type) {
    case 'g-counter':
      return GCounter.fromJSON(data)
    case 'pn-counter':
      return PNCounter.fromJSON(data)
    case 'lww-register':
      return LWWRegister.fromJSON(data)
    case 'or-set':
      return ORSet.fromJSON(data)
    case 'lww-map':
      return LWWMap.fromJSON(data)
    default:
      throw new Error(`Unknown CRDT type: ${type}`)
  }
}

/**
 * Batch merge multiple CRDT states
 * @param crdts - Array of CRDTs to merge
 * @returns Merged CRDT
 */
export function batchMerge<T>(crdts: T[]): T {
  if (crdts.length === 0) {
    throw new Error('Cannot merge empty array')
  }

  const [first, ...rest] = crdts
  const result = first

  for (const crdt of rest) {
    ;(result as any).merge((crdt as any).getState())
  }

  return result
}

/**
 * Calculate delta between two CRDT states
 * Only works for state-based CRDTs
 * @param state1 - Earlier state
 * @param state2 - Later state
 * @returns Delta state
 */
export function calculateDelta(state1: any, state2: any): any {
  // Placeholder: in production, implement delta-state CRDT
  // For now, return full state2
  return state2
}

/**
 * Apply delta to CRDT state
 * @param state - Current state
 * @param delta - Delta to apply
 * @returns New state
 */
export function applyDelta(state: any, delta: any): any {
  // Placeholder: in production, implement delta application
  // For now, merge full states
  state.merge(delta)
  return state
}
