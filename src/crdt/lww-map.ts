/**
 * LWW-Map (Last-Write-Wins Map) CRDT
 *
 * A map/dictionary where last write wins for each key.
 * Perfect for preference storage with automatic conflict resolution.
 *
 * @module crdt/lww-map
 */

import type { CRDT, LWWMapState, ReplicaId } from './types.ts'

/**
 * LWW-Map implementation
 *
 * @example
 * ```ts
 * const map = new LWWMap('replica-1')
 * map.set('theme', 'dark')
 * map.set('language', 'en')
 *
 * console.log(map.get('theme')) // 'dark'
 * console.log(map.value()) // Map { 'theme' => 'dark', 'language' => 'en' }
 * ```
 */
export class LWWMap<K extends string, V> implements CRDT<LWWMapState<K, V>> {
  private replicaId: ReplicaId
  private entries: Map<K, { value: V; timestamp: number; deleted: boolean }>

  constructor(replicaId: ReplicaId, initialState?: LWWMapState<K, V>) {
    this.replicaId = replicaId

    if (initialState) {
      this.entries = new Map(initialState.entries)
    } else {
      this.entries = new Map()
    }
  }

  /**
   * Set key-value pair
   * @param key - Key
   * @param value - Value
   */
  set(key: K, value: V): void {
    this.entries.set(key, {
      value,
      timestamp: Date.now(),
      deleted: false,
    })
  }

  /**
   * Get value for key
   * @param key - Key
   * @returns Value or undefined
   */
  get(key: K): V | undefined {
    const entry = this.entries.get(key)
    if (entry && !entry.deleted) {
      return entry.value
    }
    return undefined
  }

  /**
   * Check if key exists
   * @param key - Key
   * @returns true if key exists and not deleted
   */
  has(key: K): boolean {
    const entry = this.entries.get(key)
    return entry !== undefined && !entry.deleted
  }

  /**
   * Delete key
   * @param key - Key to delete
   */
  delete(key: K): void {
    const existing = this.entries.get(key)

    if (existing) {
      this.entries.set(key, {
        ...existing,
        timestamp: Date.now(),
        deleted: true,
      })
    } else {
      // Create tombstone for key that doesn't exist locally
      // but might exist on other replicas
      this.entries.set(key, {
        value: undefined as any,
        timestamp: Date.now(),
        deleted: true,
      })
    }
  }

  /**
   * Get current map value (excluding deleted entries)
   * @returns Map of non-deleted entries
   */
  value(): Map<K, V> {
    const result = new Map<K, V>()

    for (const [key, entry] of this.entries) {
      if (!entry.deleted) {
        result.set(key, entry.value)
      }
    }

    return result
  }

  /**
   * Get all keys (excluding deleted)
   */
  keys(): K[] {
    const result: K[] = []

    for (const [key, entry] of this.entries) {
      if (!entry.deleted) {
        result.push(key)
      }
    }

    return result
  }

  /**
   * Get all values (excluding deleted)
   */
  values(): V[] {
    const result: V[] = []

    for (const entry of this.entries.values()) {
      if (!entry.deleted) {
        result.push(entry.value)
      }
    }

    return result
  }

  /**
   * Get number of non-deleted entries
   */
  size(): number {
    let count = 0

    for (const entry of this.entries.values()) {
      if (!entry.deleted) {
        count++
      }
    }

    return count
  }

  /**
   * Merge with another LWW-Map state
   * @param other - Other map state
   */
  merge(other: LWWMapState<K, V>): void {
    for (const [key, otherEntry] of other.entries) {
      const thisEntry = this.entries.get(key)

      if (!thisEntry) {
        // Key doesn't exist locally, adopt remote entry
        this.entries.set(key, { ...otherEntry })
      } else {
        // Key exists, compare timestamps
        if (otherEntry.timestamp > thisEntry.timestamp) {
          // Remote is newer, adopt it
          this.entries.set(key, { ...otherEntry })
        } else if (otherEntry.timestamp === thisEntry.timestamp) {
          // Tie-break: deleted wins over non-deleted
          // If both deleted or both not deleted, keep local
          if (otherEntry.deleted && !thisEntry.deleted) {
            this.entries.set(key, { ...otherEntry })
          }
        }
      }
    }
  }

  /**
   * Clear all entries (mark as deleted)
   */
  clear(): void {
    const now = Date.now()

    for (const [key, entry] of this.entries) {
      this.entries.set(key, {
        ...entry,
        timestamp: now,
        deleted: true,
      })
    }
  }

  /**
   * Iterate over non-deleted entries
   */
  forEach(callback: (value: V, key: K) => void): void {
    for (const [key, entry] of this.entries) {
      if (!entry.deleted) {
        callback(entry.value, key)
      }
    }
  }

  /**
   * Get current state
   */
  getState(): LWWMapState<K, V> {
    return {
      replicaId: this.replicaId,
      entries: new Map(this.entries),
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
    const valueMap: Record<string, V> = {}

    for (const [key, entry] of this.entries) {
      if (!entry.deleted) {
        valueMap[key] = entry.value
      }
    }

    return {
      type: 'lww-map',
      replicaId: this.replicaId,
      entries: Array.from(this.entries.entries()),
      value: valueMap,
    }
  }

  /**
   * Deserialize from JSON
   */
  static fromJSON<K extends string, V>(json: any): LWWMap<K, V> {
    return new LWWMap<K, V>(json.replicaId, {
      replicaId: json.replicaId,
      entries: new Map(json.entries),
    })
  }

  /**
   * Convert to plain object
   */
  toObject(): Record<K, V> {
    const result = {} as Record<K, V>

    for (const [key, entry] of this.entries) {
      if (!entry.deleted) {
        result[key] = entry.value
      }
    }

    return result
  }

  /**
   * Create from plain object
   */
  static fromObject<K extends string, V>(
    replicaId: ReplicaId,
    obj: Record<K, V>,
  ): LWWMap<K, V> {
    const map = new LWWMap<K, V>(replicaId)

    for (const [key, value] of Object.entries(obj) as Array<[K, V]>) {
      map.set(key, value)
    }

    return map
  }
}
