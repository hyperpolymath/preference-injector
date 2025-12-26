# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2024 Hyperpolymath
#
# Nickel configuration for preference-injector
# Type-safe configuration language for the hyperpolymath standard

{
  # Project metadata
  project = {
    name = "preference-injector",
    version = "2.0.0",
    description = "Type-safe preference injection system for dynamic configuration management",
    license = "MIT",
    repository = "https://github.com/hyperpolymath/preference-injector",
  },

  # Language policy (Hyperpolymath Standard)
  language_policy = {
    allowed = [
      "rescript",
      "javascript",  # Only compiled output
      "bash",
      "nickel",
    ],
    banned = [
      "typescript",
      "nodejs",
      "npm",
      "bun",
      "go",
      "python",  # Except SaltStack
      "java",
      "kotlin",
      "swift",
    ],
    primary_runtime = "deno",
    primary_language = "rescript",
  },

  # Build configuration
  build = {
    rescript = {
      module_format = "es6",
      suffix = ".bs.js",
      namespace = true,
      sources = [
        { dir = "src/rescript", subdirs = true },
        { dir = "tests/rescript", subdirs = true, type = "dev" },
        { dir = "examples", subdirs = true, type = "dev" },
      ],
    },
    deno = {
      permissions = ["allow-all"],
      unstable = true,
      check_js = false,
    },
  },

  # Security requirements
  security = {
    # Banned hash algorithms (RSR compliance)
    banned_hashes = ["md5", "sha1"],

    # Minimum hash algorithm for security
    minimum_hash = "sha256",

    # Encryption requirements
    encryption = {
      algorithm = "AES-256-GCM",
      key_derivation = "PBKDF2",
      iterations = 100000,
    },

    # Network requirements
    network = {
      require_https = true,
      no_http_urls = true,
    },

    # Secret management
    secrets = {
      no_hardcoded = true,
      env_prefix = "PREF_",
    },
  },

  # Testing configuration
  testing = {
    coverage_target = 80,
    test_pattern = "**/*.test.res",
    frameworks = ["deno-test"],
  },

  # Documentation requirements
  documentation = {
    required_files = [
      "README.adoc",
      "SECURITY.md",
      "LICENSE.txt",
      "CONTRIBUTING.md",
      "MAINTAINERS.md",
      "CODE_OF_CONDUCT.md",
      "CHANGELOG.md",
    ],
    api_docs = true,
  },

  # CI/CD configuration
  ci = {
    pre_commit = [
      "rescript format",
      "deno fmt --check",
      "deno lint",
    ],
    pre_push = [
      "rescript build",
      "deno test --allow-all",
    ],
    main_branch = "main",
    protected_branches = ["main", "develop"],
  },
}
