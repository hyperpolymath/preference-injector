/**
 * OR-Set (Observed-Remove Set) CRDT
 *
 * A set that supports add and remove operations.
 * Elements can be added and removed multiple times.
 * Add wins over remove for concurrent operations.
 *
 * @module crdt/or-set
 */

import type { CRDT, ORSetState, ReplicaId } from './types.ts'

/**
 * OR-Set implementation
 *
 * @example
 * ```ts
 * const set1 = new ORSet('replica-1')
 * const set2 = new ORSet('replica-2')
 *
 * set1.add('apple')
 * set2.add('banana')
 * set1.remove('apple')
 *
 * set1.merge(set2.getState())
 * console.log(set1.value()) // Set(['banana'])
 * ```
 */
export class ORSet<T> implements CRDT<ORSetState<T>> {
  private replicaId: ReplicaId
  private elements: Map<string, { value: T; timestamp: number; tag: string }>
  private tombstones: Set<string>
  private tagCounter: number = 0

  constructor(replicaId: ReplicaId, initialState?: ORSetState<T>) {
    this.replicaId = replicaId

    if (initialState) {
      this.elements = new Map(initialState.elements)
      this.tombstones = new Set(initialState.tombstones)
    } else {
      this.elements = new Map()
      this.tombstones = new Set()
    }
  }

  /**
   * Add element to set
   * @param value - Element to add
   */
  add(value: T): void {
    const key = this.hash(value)
    const tag = `${this.replicaId}-${Date.now()}-${this.tagCounter++}`

    this.elements.set(key, {
      value,
      timestamp: Date.now(),
      tag,
    })

    // Remove from tombstones if present
    this.tombstones.delete(key)
  }

  /**
   * Remove element from set
   * @param value - Element to remove
   */
  remove(value: T): void {
    const key = this.hash(value)

    if (this.elements.has(key)) {
      const element = this.elements.get(key)!
      this.tombstones.add(element.tag)
      this.elements.delete(key)
    }
  }

  /**
   * Check if element is in set
   * @param value - Element to check
   * @returns true if element is in set
   */
  has(value: T): boolean {
    const key = this.hash(value)
    return this.elements.has(key)
  }

  /**
   * Get current set value
   * @returns Set of all elements
   */
  value(): Set<T> {
    const result = new Set<T>()
    for (const { value } of this.elements.values()) {
      result.add(value)
    }
    return result
  }

  /**
   * Get set size
   */
  size(): number {
    return this.elements.size
  }

  /**
   * Merge with another OR-Set state
   * @param other - Other OR-Set state
   */
  merge(other: ORSetState<T>): void {
    // Merge elements (union)
    for (const [key, element] of other.elements) {
      const existing = this.elements.get(key)

      // Add if not present
      if (!existing) {
        this.elements.set(key, element)
      } else {
        // Keep most recent
        if (element.timestamp > existing.timestamp) {
          this.elements.set(key, element)
        }
      }
    }

    // Merge tombstones (union)
    for (const tombstone of other.tombstones) {
      this.tombstones.add(tombstone)
    }

    // Remove tombstoned elements
    for (const [key, element] of this.elements) {
      if (this.tombstones.has(element.tag)) {
        this.elements.delete(key)
      }
    }
  }

  /**
   * Get current state
   */
  getState(): ORSetState<T> {
    return {
      replicaId: this.replicaId,
      elements: new Map(this.elements),
      tombstones: new Set(this.tombstones),
    }
  }

  /**
   * Get replica ID
   */
  getReplicaId(): ReplicaId {
    return this.replicaId
  }

  /**
   * Convert to array
   */
  toArray(): T[] {
    return Array.from(this.value())
  }

  /**
   * Iterate over elements
   */
  forEach(callback: (value: T) => void): void {
    for (const { value } of this.elements.values()) {
      callback(value)
    }
  }

  /**
   * Clear all elements
   */
  clear(): void {
    // Move all elements to tombstones
    for (const element of this.elements.values()) {
      this.tombstones.add(element.tag)
    }
    this.elements.clear()
  }

  /**
   * Hash value to key
   */
  private hash(value: T): string {
    return JSON.stringify(value)
  }

  /**
   * Serialize to JSON
   */
  toJSON(): unknown {
    return {
      type: 'or-set',
      replicaId: this.replicaId,
      elements: Array.from(this.elements.entries()),
      tombstones: Array.from(this.tombstones),
      value: this.toArray(),
    }
  }

  /**
   * Deserialize from JSON
   */
  static fromJSON<T>(json: any): ORSet<T> {
    return new ORSet<T>(json.replicaId, {
      replicaId: json.replicaId,
      elements: new Map(json.elements),
      tombstones: new Set(json.tombstones),
    })
  }
}
