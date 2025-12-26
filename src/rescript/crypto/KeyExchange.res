// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Hyperpolymath

/**
 * Key exchange utilities using Web Crypto API
 * Supports ECDH for key agreement
 */

/** Key exchange algorithm */
type keyExchangeAlgorithm =
  | ECDH_P256
  | ECDH_P384

/** Key pair for key exchange */
type exchangeKeyPair = {
  publicKey: Webapi.Crypto.CryptoKey.t,
  privateKey: Webapi.Crypto.CryptoKey.t,
}

/** Generate a new key exchange key pair */
let generateKeyPair = async (algorithm: keyExchangeAlgorithm): promise<exchangeKeyPair> => {
  let namedCurve = switch algorithm {
  | ECDH_P256 => "P-256"
  | ECDH_P384 => "P-384"
  }
  %raw(`
    (async () => {
      const keyPair = await crypto.subtle.generateKey(
        {
          name: "ECDH",
          namedCurve: namedCurve
        },
        true,
        ["deriveBits", "deriveKey"]
      );
      return {
        publicKey: keyPair.publicKey,
        privateKey: keyPair.privateKey
      };
    })()
  `)
}

/** Derive shared secret from key pair */
let deriveSharedSecret = async (
  privateKey: Webapi.Crypto.CryptoKey.t,
  publicKey: Webapi.Crypto.CryptoKey.t,
  ~bitLength: int=256,
): promise<Js.TypedArray2.Uint8Array.t> => {
  %raw(`
    (async () => {
      const sharedBits = await crypto.subtle.deriveBits(
        {
          name: "ECDH",
          public: publicKey
        },
        privateKey,
        bitLength
      );
      return new Uint8Array(sharedBits);
    })()
  `)
}

/** Derive an AES key from shared secret */
let deriveAESKey = async (
  privateKey: Webapi.Crypto.CryptoKey.t,
  publicKey: Webapi.Crypto.CryptoKey.t,
): promise<Webapi.Crypto.CryptoKey.t> => {
  %raw(`
    (async () => {
      return await crypto.subtle.deriveKey(
        {
          name: "ECDH",
          public: publicKey
        },
        privateKey,
        { name: "AES-GCM", length: 256 },
        false,
        ["encrypt", "decrypt"]
      );
    })()
  `)
}

/** Export public key to raw format */
let exportPublicKey = async (key: Webapi.Crypto.CryptoKey.t): promise<Js.TypedArray2.Uint8Array.t> => {
  %raw(`
    (async () => {
      const exported = await crypto.subtle.exportKey("raw", key);
      return new Uint8Array(exported);
    })()
  `)
}

/** Export public key to JWK format */
let exportPublicKeyJWK = async (key: Webapi.Crypto.CryptoKey.t): promise<Js.Json.t> => {
  %raw(`
    (async () => {
      return await crypto.subtle.exportKey("jwk", key);
    })()
  `)
}

/** Import public key from raw format */
let importPublicKey = async (
  keyBytes: Js.TypedArray2.Uint8Array.t,
  algorithm: keyExchangeAlgorithm,
): promise<Webapi.Crypto.CryptoKey.t> => {
  let namedCurve = switch algorithm {
  | ECDH_P256 => "P-256"
  | ECDH_P384 => "P-384"
  }
  %raw(`
    (async () => {
      return await crypto.subtle.importKey(
        "raw",
        keyBytes,
        {
          name: "ECDH",
          namedCurve: namedCurve
        },
        true,
        []
      );
    })()
  `)
}

/** Import public key from JWK format */
let importPublicKeyJWK = async (jwk: Js.Json.t, algorithm: keyExchangeAlgorithm): promise<
  Webapi.Crypto.CryptoKey.t,
> => {
  let namedCurve = switch algorithm {
  | ECDH_P256 => "P-256"
  | ECDH_P384 => "P-384"
  }
  %raw(`
    (async () => {
      return await crypto.subtle.importKey(
        "jwk",
        jwk,
        {
          name: "ECDH",
          namedCurve: namedCurve
        },
        true,
        []
      );
    })()
  `)
}
