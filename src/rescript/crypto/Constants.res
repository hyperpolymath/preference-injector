// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Hyperpolymath

/**
 * Cryptographic constants - RSR Framework compliant
 * Note: SHA1/MD5 are BANNED for security purposes (use SHA256+)
 */

/** Recommended hash algorithms (SHA256+) */
module HashAlgorithm = {
  let sha256 = "SHA-256"
  let sha384 = "SHA-384"
  let sha512 = "SHA-512"
  let blake3 = "BLAKE3" // Preferred for performance
}

/** Key derivation parameters */
module KDF = {
  let pbkdf2Iterations = 100000
  let argon2MemoryCost = 65536
  let argon2TimeCost = 3
  let argon2Parallelism = 1
  let saltLength = 16
}

/** Encryption parameters */
module Encryption = {
  let aesKeyLength = 256
  let aesIvLength = 12
  let aesTagLength = 128
  let algorithm = "AES-GCM"
}

/** Signature algorithms */
module Signature = {
  let ed25519 = "Ed25519"
  let ecdsa = "ECDSA"
  let dilithium = "Dilithium" // Post-quantum
}

/** Key exchange algorithms */
module KeyExchange = {
  let x25519 = "X25519"
  let ecdh = "ECDH"
  let kyber = "Kyber" // Post-quantum
}

/** Post-quantum cryptography support */
module PQC = {
  let kyberKeySize = 1568
  let dilithiumSignatureSize = 2420
}
