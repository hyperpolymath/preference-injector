/**
 * G-Counter (Grow-only Counter) CRDT
 *
 * A counter that can only increment. Supports concurrent increments
 * from multiple replicas without conflicts.
 *
 * @module crdt/gcounter
 */

import type { CRDT, GCounterState, ReplicaId } from './types.ts'

/**
 * G-Counter implementation
 *
 * @example
 * ```ts
 * const counter = new GCounter('replica-1')
 * counter.increment(5)
 * console.log(counter.value()) // 5
 *
 * // On another replica
 * const counter2 = new GCounter('replica-2')
 * counter2.increment(3)
 *
 * // Merge states
 * counter.merge(counter2.getState())
 * console.log(counter.value()) // 8
 * ```
 */
export class GCounter implements CRDT<GCounterState> {
  private replicaId: ReplicaId
  private counts: Map<ReplicaId, number>

  constructor(replicaId: ReplicaId, initialState?: GCounterState) {
    this.replicaId = replicaId
    this.counts = initialState?.counts
      ? new Map(initialState.counts)
      : new Map()

    // Initialize own counter
    if (!this.counts.has(replicaId)) {
      this.counts.set(replicaId, 0)
    }
  }

  /**
   * Increment counter by delta
   * @param delta - Amount to increment (default: 1)
   */
  increment(delta: number = 1): void {
    if (delta < 0) {
      throw new Error('G-Counter can only increment (use PN-Counter for decrements)')
    }

    const current = this.counts.get(this.replicaId) ?? 0
    this.counts.set(this.replicaId, current + delta)
  }

  /**
   * Get current counter value
   * @returns Sum of all replica counts
   */
  value(): number {
    let sum = 0
    for (const count of this.counts.values()) {
      sum += count
    }
    return sum
  }

  /**
   * Merge with another G-Counter state
   * @param other - Other G-Counter state
   */
  merge(other: GCounterState): void {
    // Take maximum count for each replica
    for (const [replicaId, count] of other.counts) {
      const currentCount = this.counts.get(replicaId) ?? 0
      this.counts.set(replicaId, Math.max(currentCount, count))
    }
  }

  /**
   * Get current state
   * @returns G-Counter state
   */
  getState(): GCounterState {
    return {
      replicaId: this.replicaId,
      counts: new Map(this.counts),
    }
  }

  /**
   * Get replica ID
   */
  getReplicaId(): ReplicaId {
    return this.replicaId
  }

  /**
   * Serialize to JSON
   */
  toJSON(): unknown {
    return {
      type: 'g-counter',
      replicaId: this.replicaId,
      counts: Array.from(this.counts.entries()),
      value: this.value(),
    }
  }

  /**
   * Deserialize from JSON
   * @param json - JSON representation
   * @returns G-Counter instance
   */
  static fromJSON(json: any): GCounter {
    const counts = new Map(json.counts)
    return new GCounter(json.replicaId, {
      replicaId: json.replicaId,
      counts,
    })
  }
}
