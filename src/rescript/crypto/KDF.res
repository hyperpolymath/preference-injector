// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Hyperpolymath

/**
 * Key Derivation Functions using Web Crypto API
 */

/** KDF algorithm type */
type kdfAlgorithm =
  | PBKDF2
  | HKDF

/** PBKDF2 parameters */
type pbkdf2Params = {
  salt: Js.TypedArray2.Uint8Array.t,
  iterations: int,
  hashAlgorithm: string,
  keyLength: int,
}

/** HKDF parameters */
type hkdfParams = {
  salt: Js.TypedArray2.Uint8Array.t,
  info: Js.TypedArray2.Uint8Array.t,
  hashAlgorithm: string,
  keyLength: int,
}

/** Default PBKDF2 parameters (secure defaults) */
let defaultPBKDF2Params = (): pbkdf2Params => {
  salt: %raw(`crypto.getRandomValues(new Uint8Array(16))`),
  iterations: 100000,
  hashAlgorithm: "SHA-256",
  keyLength: 256,
}

/** Default HKDF parameters */
let defaultHKDFParams = (): hkdfParams => {
  salt: %raw(`crypto.getRandomValues(new Uint8Array(16))`),
  info: %raw(`new Uint8Array(0)`),
  hashAlgorithm: "SHA-256",
  keyLength: 256,
}

/** Derive key using PBKDF2 */
let derivePBKDF2 = async (password: string, params: pbkdf2Params): promise<
  Js.TypedArray2.Uint8Array.t,
> => {
  %raw(`
    (async () => {
      const encoder = new TextEncoder();
      const passwordKey = await crypto.subtle.importKey(
        "raw",
        encoder.encode(password),
        "PBKDF2",
        false,
        ["deriveBits"]
      );

      const derivedBits = await crypto.subtle.deriveBits(
        {
          name: "PBKDF2",
          salt: params.salt,
          iterations: params.iterations,
          hash: params.hashAlgorithm
        },
        passwordKey,
        params.keyLength
      );

      return new Uint8Array(derivedBits);
    })()
  `)
}

/** Derive key using HKDF */
let deriveHKDF = async (ikm: Js.TypedArray2.Uint8Array.t, params: hkdfParams): promise<
  Js.TypedArray2.Uint8Array.t,
> => {
  %raw(`
    (async () => {
      const ikmKey = await crypto.subtle.importKey(
        "raw",
        ikm,
        "HKDF",
        false,
        ["deriveBits"]
      );

      const derivedBits = await crypto.subtle.deriveBits(
        {
          name: "HKDF",
          salt: params.salt,
          info: params.info,
          hash: params.hashAlgorithm
        },
        ikmKey,
        params.keyLength
      );

      return new Uint8Array(derivedBits);
    })()
  `)
}

/** Derive an AES-GCM key from password */
let deriveAESKey = async (password: string, salt: Js.TypedArray2.Uint8Array.t): promise<
  Webapi.Crypto.CryptoKey.t,
> => {
  %raw(`
    (async () => {
      const encoder = new TextEncoder();
      const passwordKey = await crypto.subtle.importKey(
        "raw",
        encoder.encode(password),
        "PBKDF2",
        false,
        ["deriveKey"]
      );

      return await crypto.subtle.deriveKey(
        {
          name: "PBKDF2",
          salt: salt,
          iterations: 100000,
          hash: "SHA-256"
        },
        passwordKey,
        { name: "AES-GCM", length: 256 },
        false,
        ["encrypt", "decrypt"]
      );
    })()
  `)
}

/** Generate a secure random salt */
let generateSalt = (~length: int=16): Js.TypedArray2.Uint8Array.t => {
  %raw(`crypto.getRandomValues(new Uint8Array(length))`)
}
