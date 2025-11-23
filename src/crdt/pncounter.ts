/**
 * PN-Counter (Positive-Negative Counter) CRDT
 *
 * A counter that supports both increments and decrements.
 * Composed of two G-Counters (positive and negative).
 *
 * @module crdt/pncounter
 */

import type { CRDT, PNCounterState, ReplicaId } from './types.ts'

/**
 * PN-Counter implementation
 *
 * @example
 * ```ts
 * const counter = new PNCounter('replica-1')
 * counter.increment(10)
 * counter.decrement(3)
 * console.log(counter.value()) // 7
 * ```
 */
export class PNCounter implements CRDT<PNCounterState> {
  private replicaId: ReplicaId
  private increments: Map<ReplicaId, number>
  private decrements: Map<ReplicaId, number>

  constructor(replicaId: ReplicaId, initialState?: PNCounterState) {
    this.replicaId = replicaId
    this.increments = initialState?.increments
      ? new Map(initialState.increments)
      : new Map()
    this.decrements = initialState?.decrements
      ? new Map(initialState.decrements)
      : new Map()

    // Initialize own counters
    if (!this.increments.has(replicaId)) {
      this.increments.set(replicaId, 0)
    }
    if (!this.decrements.has(replicaId)) {
      this.decrements.set(replicaId, 0)
    }
  }

  /**
   * Increment counter
   * @param delta - Amount to increment (default: 1)
   */
  increment(delta: number = 1): void {
    if (delta < 0) {
      throw new Error('Delta must be non-negative')
    }

    const current = this.increments.get(this.replicaId) ?? 0
    this.increments.set(this.replicaId, current + delta)
  }

  /**
   * Decrement counter
   * @param delta - Amount to decrement (default: 1)
   */
  decrement(delta: number = 1): void {
    if (delta < 0) {
      throw new Error('Delta must be non-negative')
    }

    const current = this.decrements.get(this.replicaId) ?? 0
    this.decrements.set(this.replicaId, current + delta)
  }

  /**
   * Get current counter value
   * @returns Difference between increments and decrements
   */
  value(): number {
    let positiveSum = 0
    for (const count of this.increments.values()) {
      positiveSum += count
    }

    let negativeSum = 0
    for (const count of this.decrements.values()) {
      negativeSum += count
    }

    return positiveSum - negativeSum
  }

  /**
   * Merge with another PN-Counter state
   * @param other - Other PN-Counter state
   */
  merge(other: PNCounterState): void {
    // Merge increments (take maximum)
    for (const [replicaId, count] of other.increments) {
      const currentCount = this.increments.get(replicaId) ?? 0
      this.increments.set(replicaId, Math.max(currentCount, count))
    }

    // Merge decrements (take maximum)
    for (const [replicaId, count] of other.decrements) {
      const currentCount = this.decrements.get(replicaId) ?? 0
      this.decrements.set(replicaId, Math.max(currentCount, count))
    }
  }

  /**
   * Get current state
   */
  getState(): PNCounterState {
    return {
      replicaId: this.replicaId,
      increments: new Map(this.increments),
      decrements: new Map(this.decrements),
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
      type: 'pn-counter',
      replicaId: this.replicaId,
      increments: Array.from(this.increments.entries()),
      decrements: Array.from(this.decrements.entries()),
      value: this.value(),
    }
  }

  /**
   * Deserialize from JSON
   */
  static fromJSON(json: any): PNCounter {
    return new PNCounter(json.replicaId, {
      replicaId: json.replicaId,
      increments: new Map(json.increments),
      decrements: new Map(json.decrements),
    })
  }
}
