/**
 * LWW-Register (Last-Write-Wins Register) CRDT
 *
 * A register that resolves conflicts using timestamps.
 * The value with the latest timestamp wins.
 *
 * @module crdt/lww-register
 */

import type { CRDT, LWWRegisterState, ReplicaId, VectorClock } from './types.ts'

/**
 * LWW-Register implementation
 *
 * @example
 * ```ts
 * const reg1 = new LWWRegister('replica-1', 'initial')
 * const reg2 = new LWWRegister('replica-2', 'initial')
 *
 * reg1.set('value-1')
 * reg2.set('value-2')
 *
 * // Later write wins
 * reg1.merge(reg2.getState())
 * console.log(reg1.value()) // 'value-2' (if reg2's timestamp is later)
 * ```
 */
export class LWWRegister<T> implements CRDT<LWWRegisterState<T>> {
  private replicaId: ReplicaId
  private _value: T
  private timestamp: number
  private vectorClock: VectorClock

  constructor(replicaId: ReplicaId, initialValue: T, initialState?: LWWRegisterState<T>) {
    this.replicaId = replicaId

    if (initialState) {
      this._value = initialState.value
      this.timestamp = initialState.timestamp
      this.vectorClock = new Map(initialState.vectorClock)
    } else {
      this._value = initialValue
      this.timestamp = Date.now()
      this.vectorClock = new Map()
      this.vectorClock.set(replicaId, 0)
    }
  }

  /**
   * Set new value
   * @param value - New value
   */
  set(value: T): void {
    this._value = value
    this.timestamp = Date.now()

    // Increment vector clock
    const currentClock = this.vectorClock.get(this.replicaId) ?? 0
    this.vectorClock.set(this.replicaId, currentClock + 1)
  }

  /**
   * Get current value
   */
  value(): T {
    return this._value
  }

  /**
   * Merge with another LWW-Register state
   * @param other - Other register state
   */
  merge(other: LWWRegisterState<T>): void {
    // Compare timestamps
    if (other.timestamp > this.timestamp) {
      // Other is newer, adopt its value
      this._value = other.value
      this.timestamp = other.timestamp
      this.vectorClock = new Map(other.vectorClock)
    } else if (other.timestamp === this.timestamp) {
      // Tie-break using replica ID (deterministic)
      if (other.replicaId > this.replicaId) {
        this._value = other.value
        this.vectorClock = new Map(other.vectorClock)
      }
    }

    // Merge vector clocks (take maximum for each replica)
    for (const [replicaId, clock] of other.vectorClock) {
      const currentClock = this.vectorClock.get(replicaId) ?? 0
      this.vectorClock.set(replicaId, Math.max(currentClock, clock))
    }
  }

  /**
   * Get current state
   */
  getState(): LWWRegisterState<T> {
    return {
      replicaId: this.replicaId,
      value: this._value,
      timestamp: this.timestamp,
      vectorClock: new Map(this.vectorClock),
    }
  }

  /**
   * Get replica ID
   */
  getReplicaId(): ReplicaId {
    return this.replicaId
  }

  /**
   * Get timestamp of current value
   */
  getTimestamp(): number {
    return this.timestamp
  }

  /**
   * Get vector clock
   */
  getVectorClock(): VectorClock {
    return new Map(this.vectorClock)
  }

  /**
   * Check if this register happened before another
   * @param other - Other register state
   * @returns true if this happened before other
   */
  happenedBefore(other: LWWRegisterState<T>): boolean {
    for (const [replicaId, clock] of this.vectorClock) {
      const otherClock = other.vectorClock.get(replicaId) ?? 0
      if (clock > otherClock) {
        return false
      }
    }
    return true
  }

  /**
   * Check if this register is concurrent with another
   * @param other - Other register state
   * @returns true if concurrent
   */
  isConcurrent(other: LWWRegisterState<T>): boolean {
    return !this.happenedBefore(other) &&
      !this.otherHappenedBefore(other)
  }

  private otherHappenedBefore(other: LWWRegisterState<T>): boolean {
    for (const [replicaId, clock] of other.vectorClock) {
      const thisClock = this.vectorClock.get(replicaId) ?? 0
      if (clock > thisClock) {
        return false
      }
    }
    return true
  }

  /**
   * Serialize to JSON
   */
  toJSON(): unknown {
    return {
      type: 'lww-register',
      replicaId: this.replicaId,
      value: this._value,
      timestamp: this.timestamp,
      vectorClock: Array.from(this.vectorClock.entries()),
    }
  }

  /**
   * Deserialize from JSON
   */
  static fromJSON<T>(json: any): LWWRegister<T> {
    return new LWWRegister<T>(json.replicaId, json.value, {
      replicaId: json.replicaId,
      value: json.value,
      timestamp: json.timestamp,
      vectorClock: new Map(json.vectorClock),
    })
  }
}
