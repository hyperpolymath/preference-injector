// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Hyperpolymath

/**
 * Cryptographic hashing utilities
 * Uses Web Crypto API and BLAKE3 for modern, secure hashing
 */

/** Hash algorithm type */
type hashAlgorithm =
  | SHA256
  | SHA384
  | SHA512
  | BLAKE3

/** Convert to Web Crypto algorithm name */
let algorithmToString = (algo: hashAlgorithm): string => {
  switch algo {
  | SHA256 => "SHA-256"
  | SHA384 => "SHA-384"
  | SHA512 => "SHA-512"
  | BLAKE3 => "BLAKE3"
  }
}

/** Hash result */
type hashResult = {
  hex: string,
  bytes: Js.TypedArray2.Uint8Array.t,
}

/** Convert Uint8Array to hex string */
let bytesToHex = (bytes: Js.TypedArray2.Uint8Array.t): string => {
  %raw(`
    Array.from(bytes)
      .map(b => b.toString(16).padStart(2, '0'))
      .join('')
  `)
}

/** Convert hex string to Uint8Array */
let hexToBytes = (hex: string): Js.TypedArray2.Uint8Array.t => {
  %raw(`
    new Uint8Array(
      hex.match(/.{1,2}/g)?.map(byte => parseInt(byte, 16)) || []
    )
  `)
}

/** Hash data using Web Crypto API */
let hash = async (data: string, algorithm: hashAlgorithm): promise<hashResult> => {
  %raw(`
    (async () => {
      const encoder = new TextEncoder();
      const dataBytes = encoder.encode(data);

      if (algorithm === "BLAKE3") {
        // Use BLAKE3 library if available
        if (typeof blake3 !== 'undefined') {
          const hash = blake3.hash(dataBytes);
          return {
            hex: Array.from(hash).map(b => b.toString(16).padStart(2, '0')).join(''),
            bytes: hash
          };
        }
        // Fallback to SHA-256 if BLAKE3 not available
        algorithm = "SHA-256";
      }

      const hashBuffer = await crypto.subtle.digest(algorithm, dataBytes);
      const hashBytes = new Uint8Array(hashBuffer);
      const hex = Array.from(hashBytes)
        .map(b => b.toString(16).padStart(2, '0'))
        .join('');

      return { hex, bytes: hashBytes };
    })()
  `)
}

/** Hash data with SHA-256 (convenience function) */
let sha256 = async (data: string): promise<string> => {
  let result = await hash(data, SHA256)
  result.hex
}

/** Hash data with SHA-512 (convenience function) */
let sha512 = async (data: string): promise<string> => {
  let result = await hash(data, SHA512)
  result.hex
}

/** Hash data with BLAKE3 (convenience function) */
let blake3Hash = async (data: string): promise<string> => {
  let result = await hash(data, BLAKE3)
  result.hex
}

/** Verify a hash */
let verify = async (data: string, expectedHex: string, algorithm: hashAlgorithm): promise<bool> => {
  let result = await hash(data, algorithm)
  result.hex == expectedHex
}

/** Hash with salt */
let hashWithSalt = async (data: string, salt: string, algorithm: hashAlgorithm): promise<
  hashResult,
> => {
  await hash(salt ++ data, algorithm)
}

/** Generate a random salt */
let generateSalt = (~length: int=16): Js.TypedArray2.Uint8Array.t => {
  %raw(`crypto.getRandomValues(new Uint8Array(length))`)
}
