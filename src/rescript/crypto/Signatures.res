// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Hyperpolymath

/**
 * Digital signature utilities
 * Uses Web Crypto API for ECDSA signatures
 */

/** Signature algorithm */
type signatureAlgorithm =
  | ECDSA_P256
  | ECDSA_P384

/** Key pair */
type keyPair = {
  publicKey: Webapi.Crypto.CryptoKey.t,
  privateKey: Webapi.Crypto.CryptoKey.t,
}

/** Generate a new signing key pair */
let generateKeyPair = async (algorithm: signatureAlgorithm): promise<keyPair> => {
  let namedCurve = switch algorithm {
  | ECDSA_P256 => "P-256"
  | ECDSA_P384 => "P-384"
  }
  %raw(`
    (async () => {
      const keyPair = await crypto.subtle.generateKey(
        {
          name: "ECDSA",
          namedCurve: namedCurve
        },
        true,
        ["sign", "verify"]
      );
      return {
        publicKey: keyPair.publicKey,
        privateKey: keyPair.privateKey
      };
    })()
  `)
}

/** Sign data */
let sign = async (
  data: string,
  privateKey: Webapi.Crypto.CryptoKey.t,
  algorithm: signatureAlgorithm,
): promise<Js.TypedArray2.Uint8Array.t> => {
  let hashName = switch algorithm {
  | ECDSA_P256 => "SHA-256"
  | ECDSA_P384 => "SHA-384"
  }
  %raw(`
    (async () => {
      const encoder = new TextEncoder();
      const dataBytes = encoder.encode(data);

      const signature = await crypto.subtle.sign(
        {
          name: "ECDSA",
          hash: hashName
        },
        privateKey,
        dataBytes
      );

      return new Uint8Array(signature);
    })()
  `)
}

/** Verify a signature */
let verify = async (
  data: string,
  signature: Js.TypedArray2.Uint8Array.t,
  publicKey: Webapi.Crypto.CryptoKey.t,
  algorithm: signatureAlgorithm,
): promise<bool> => {
  let hashName = switch algorithm {
  | ECDSA_P256 => "SHA-256"
  | ECDSA_P384 => "SHA-384"
  }
  %raw(`
    (async () => {
      const encoder = new TextEncoder();
      const dataBytes = encoder.encode(data);

      return await crypto.subtle.verify(
        {
          name: "ECDSA",
          hash: hashName
        },
        publicKey,
        signature,
        dataBytes
      );
    })()
  `)
}

/** Export public key to JWK format */
let exportPublicKey = async (key: Webapi.Crypto.CryptoKey.t): promise<Js.Json.t> => {
  %raw(`
    (async () => {
      return await crypto.subtle.exportKey("jwk", key);
    })()
  `)
}

/** Import public key from JWK format */
let importPublicKey = async (jwk: Js.Json.t, algorithm: signatureAlgorithm): promise<
  Webapi.Crypto.CryptoKey.t,
> => {
  let namedCurve = switch algorithm {
  | ECDSA_P256 => "P-256"
  | ECDSA_P384 => "P-384"
  }
  %raw(`
    (async () => {
      return await crypto.subtle.importKey(
        "jwk",
        jwk,
        {
          name: "ECDSA",
          namedCurve: namedCurve
        },
        true,
        ["verify"]
      );
    })()
  `)
}
