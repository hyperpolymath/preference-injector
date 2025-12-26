// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Hyperpolymath

/**
 * Encryption utilities for sensitive preference values
 * Uses Web Crypto API for secure encryption
 */

/** Encryption prefix to identify encrypted values */
let encryptionPrefix = "enc:v1:"

/** Module type for encryption service */
module type EncryptionService = {
  type t
  let make: string => t
  let encrypt: (t, string) => promise<string>
  let decrypt: (t, string) => promise<string>
  let isEncrypted: (t, string) => bool
}

/** AES-256-GCM encryption service using Web Crypto API */
module AESEncryption: EncryptionService = {
  type t = {key: string}

  let make = (key: string): t => {key: key}

  /** Derive a crypto key from password using PBKDF2 */
  let deriveKey = async (password: string, salt: Js.TypedArray2.Uint8Array.t): promise<
    Webapi.Crypto.CryptoKey.t,
  > => {
    // This would use Web Crypto API - simplified implementation
    // In production, use proper PBKDF2 key derivation
    ignore(password)
    ignore(salt)
    %raw(`
      (async () => {
        const enc = new TextEncoder();
        const keyMaterial = await crypto.subtle.importKey(
          "raw",
          enc.encode(password),
          "PBKDF2",
          false,
          ["deriveBits", "deriveKey"]
        );
        return await crypto.subtle.deriveKey(
          {
            name: "PBKDF2",
            salt: salt,
            iterations: 100000,
            hash: "SHA-256"
          },
          keyMaterial,
          { name: "AES-GCM", length: 256 },
          true,
          ["encrypt", "decrypt"]
        );
      })()
    `)
  }

  let encrypt = async (service: t, plaintext: string): promise<string> => {
    ignore(service)
    ignore(plaintext)
    // Simplified - in production use proper Web Crypto API
    %raw(`
      (async () => {
        const enc = new TextEncoder();
        const salt = crypto.getRandomValues(new Uint8Array(16));
        const iv = crypto.getRandomValues(new Uint8Array(12));

        const keyMaterial = await crypto.subtle.importKey(
          "raw",
          enc.encode(service.key),
          "PBKDF2",
          false,
          ["deriveBits", "deriveKey"]
        );

        const key = await crypto.subtle.deriveKey(
          {
            name: "PBKDF2",
            salt: salt,
            iterations: 100000,
            hash: "SHA-256"
          },
          keyMaterial,
          { name: "AES-GCM", length: 256 },
          true,
          ["encrypt"]
        );

        const encrypted = await crypto.subtle.encrypt(
          { name: "AES-GCM", iv: iv },
          key,
          enc.encode(plaintext)
        );

        const combined = new Uint8Array(salt.length + iv.length + encrypted.byteLength);
        combined.set(salt, 0);
        combined.set(iv, salt.length);
        combined.set(new Uint8Array(encrypted), salt.length + iv.length);

        return "enc:v1:" + btoa(String.fromCharCode(...combined));
      })()
    `)
  }

  let decrypt = async (service: t, ciphertext: string): promise<string> => {
    ignore(service)
    ignore(ciphertext)
    %raw(`
      (async () => {
        if (!ciphertext.startsWith("enc:v1:")) {
          throw new Error("Invalid encrypted value");
        }

        const data = Uint8Array.from(atob(ciphertext.slice(7)), c => c.charCodeAt(0));
        const salt = data.slice(0, 16);
        const iv = data.slice(16, 28);
        const encrypted = data.slice(28);

        const enc = new TextEncoder();
        const keyMaterial = await crypto.subtle.importKey(
          "raw",
          enc.encode(service.key),
          "PBKDF2",
          false,
          ["deriveBits", "deriveKey"]
        );

        const key = await crypto.subtle.deriveKey(
          {
            name: "PBKDF2",
            salt: salt,
            iterations: 100000,
            hash: "SHA-256"
          },
          keyMaterial,
          { name: "AES-GCM", length: 256 },
          true,
          ["decrypt"]
        );

        const decrypted = await crypto.subtle.decrypt(
          { name: "AES-GCM", iv: iv },
          key,
          encrypted
        );

        return new TextDecoder().decode(decrypted);
      })()
    `)
  }

  let isEncrypted = (_service: t, value: string): bool => {
    String.startsWith(value, ~search=encryptionPrefix)
  }
}

/** No-op encryption service for testing */
module NoOpEncryption: EncryptionService = {
  type t = unit

  let make = (_key: string): t => ()

  let encrypt = async (_service: t, plaintext: string): promise<string> => {
    plaintext
  }

  let decrypt = async (_service: t, ciphertext: string): promise<string> => {
    ciphertext
  }

  let isEncrypted = (_service: t, _value: string): bool => false
}
