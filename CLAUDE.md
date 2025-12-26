# Preference Injector

## Project Overview

This project implements a preference injection system that allows dynamic modification of user preferences or settings in applications. The system is designed to inject, override, or manage user preferences at runtime.

Built with **ReScript** and **Deno** following the Hyperpolymath Language Standard.

## Language Policy (CRITICAL)

### ALLOWED Languages & Tools

| Language/Tool | Use Case |
|---------------|----------|
| **ReScript** | Primary application code |
| **Deno** | Runtime & package management |
| **Rust** | Performance-critical extensions |
| **Bash/POSIX Shell** | Scripts, automation |
| **Nickel** | Configuration language |
| **JavaScript** | Only compiled output from ReScript |

### BANNED - Do Not Use

| Banned | Replacement |
|--------|-------------|
| TypeScript | ReScript |
| Node.js | Deno |
| npm/yarn/pnpm | Deno imports |
| Bun | Deno |
| Go | Rust |
| Makefile | justfile |

## Project Structure

```
preference-injector/
├── src/rescript/           # ReScript source code
│   ├── core/               # Core injection logic
│   ├── providers/          # Preference providers
│   ├── utils/              # Utility functions
│   ├── types/              # Type definitions
│   ├── errors/             # Error handling
│   ├── crdt/               # CRDT implementations
│   └── crypto/             # Cryptographic utilities
├── tests/rescript/         # ReScript tests
├── examples/               # Usage examples
├── docs/                   # Documentation
├── deno.json               # Deno configuration
├── bsconfig.json           # ReScript configuration
├── justfile                # Task runner (NOT Makefile)
├── Mustfile.epx            # Deployment state contract
└── config.ncl              # Nickel configuration
```

## Development Setup

### Prerequisites
- Deno >= 1.40.0
- ReScript >= 11.0.0
- Just (task runner)

### Installation
```bash
# No npm install - Deno handles dependencies
just install  # Verifies ReScript is installed
```

### Build
```bash
just build  # Build ReScript code
```

### Testing
```bash
just test  # Run all tests
```

### Development Mode
```bash
just dev  # Watch mode with auto-rebuild
```

## Architecture

### Core Components

1. **Injector**: Main module responsible for injecting preferences into target applications
2. **Providers**: Sources of preference data (file-based, API-based, environment variables)
3. **ConflictResolver**: Logic for resolving preference conflicts and priorities
4. **Validator**: Ensure preference values are valid and safe
5. **CRDT**: Distributed synchronization with conflict-free data types
6. **Crypto**: Secure encryption and hashing (no MD5/SHA1)

### Key Concepts

- **Preference Sources**: Where preferences originate (config files, databases, APIs)
- **Injection Points**: Where preferences are applied in the application
- **Priority Levels**: Mechanism for handling conflicting preferences
- **Validation Rules**: Constraints and validation for preference values

## Coding Conventions

### ReScript
- Use pattern matching over if/else chains
- Leverage the type system - avoid `Obj.magic`
- Use labeled arguments for clarity
- Prefer pipe operators (`->`) for data transformation
- Use Result types for error handling

### Naming Conventions
- Files: `PascalCase.res` (ReScript convention)
- Modules: `PascalCase`
- Functions/Values: `camelCase`
- Constants: `camelCase` or `UPPER_SNAKE_CASE`
- Types: `camelCase` (ReScript convention)

### Code Style
- Use 2 spaces for indentation
- Add SPDX license headers to all files
- Use async/await for async operations
- Prefer immutable data structures

### Error Handling
- Use Result types (`Ok`/`Error`) for recoverable errors
- Use custom error records with `errorCode` and `message`
- Log errors appropriately

## Testing Strategy

- Unit tests: Test individual modules in isolation
- Integration tests: Test module interactions
- All tests written in ReScript and run via Deno
- Coverage target: >80%

### Test File Naming
- Tests: `*_test.res`

## Security Considerations

1. **Input Validation**: Always validate preference values before injection
2. **Sanitization**: Sanitize user-provided preferences
3. **Encryption**: AES-256-GCM for sensitive preferences
4. **Hashing**: SHA-256+ only (NO MD5/SHA1)
5. **Audit Logging**: Track all preference changes

## Performance Guidelines

- Cache frequently accessed preferences
- Use lazy loading for large preference sets
- Use LWW-Map for distributed state
- Avoid synchronous blocking operations
- Batch preference updates when possible

## Common Tasks

### Adding a New Preference Provider
1. Create new provider module in `src/rescript/providers/`
2. Follow the existing provider pattern
3. Add validation logic
4. Write tests in `tests/rescript/`
5. Update documentation

### Adding Validation Rules
1. Add rule to `Validator.CommonRules` module
2. Add test cases
3. Update documentation

## Dependencies

Dependencies are managed via `deno.json` imports:
- No `package.json` or `node_modules`
- All npm packages accessed via `npm:` specifier

## Troubleshooting

### Common Issues

**Preference not being injected**
- Check provider configuration
- Verify injection point is registered
- Check priority settings
- Review validation rules

**Build failures**
- Run `rescript clean` then `rescript build`
- Check for syntax errors in .res files
- Verify bsconfig.json is correct

**Type errors**
- ReScript provides excellent error messages
- Check pattern matching exhaustiveness
- Verify function signatures

## API Reference

Detailed API documentation is available in `docs/API.md`.

## Contributing

When adding new features:
1. Create feature branch from main
2. Write tests first (TDD approach preferred)
3. Implement feature in ReScript
4. Ensure all tests pass (`just test`)
5. Run `just ci` for full pipeline
6. Update documentation
7. Create pull request

**IMPORTANT**: TypeScript, Node.js, npm, and Makefile contributions will be rejected.

## Environment Variables

```bash
PREF_SOURCE=file|api|env
PREF_CACHE_TTL=3600
PREF_VALIDATION_STRICT=true
LOG_LEVEL=info|debug|error
```

## Git Workflow

- Main branch: `main` (protected)
- Feature branches: `feature/<description>`
- Bug fixes: `fix/<description>`
- Claude AI branches: `claude/*`

## Task Runner

Use `just` for all development tasks:

```bash
just              # List all commands
just build        # Build ReScript
just test         # Run tests
just ci           # Full CI pipeline
just rsr-verify   # RSR compliance check
```

**Do NOT use make/Makefile** - use justfile instead.

## Additional Notes

- All source code is ReScript (compiles to JavaScript)
- Runtime is Deno (not Node.js)
- Configuration uses Nickel for type safety
- Deployment managed via Mustfile.epx
- Document all breaking changes in CHANGELOG.md
