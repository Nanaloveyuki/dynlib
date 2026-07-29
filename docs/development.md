# Developing dynlib

## Prerequisites

Install a current MoonBit toolchain with native-target support. Development is
native-only; this package does not support MoonBit's Wasm or JavaScript
targets.

## Local validation

Run these commands from the repository root before opening a pull request:

```powershell
moon fmt --check
moon check --target native --deny-warn --warn-list +73
moon test --target native --deny-warn --warn-list +73
moon info
git diff --exit-code
```

`moon info` regenerates `src/pkg.generated.mbti`, which is tracked and must be
included when a public API changes.

## Implementation boundaries

Keep the public API native-only and limited to loading a library, resolving a
symbol, reading its address, and closing the library. `Library` and `Symbol`
must remain opaque, and closing a library must remain idempotent.

Platform code belongs in `src/dynlib.c`:

- Windows uses `LoadLibraryW`, `GetProcAddress`, and `FreeLibrary`.
- Linux and macOS use `dlopen`, `dlsym`, and `dlclose` with `RTLD_NOW |
  RTLD_LOCAL`.

Do not add a dynamic function-call API. Consumers must model each called
function with an explicit native FFI signature and ABI. Do not return platform
diagnostics or requested library paths through the public error type.

## Tests and CI

`src/library_test.mbt` uses an operating-system library and stable symbol on
each platform. The smoke test verifies load, resolve, address access,
idempotent close, and the closed-handle behavior without invoking the resolved
symbol.

`.github/workflows/validation.yml` runs the validation sequence on
`windows-latest`, `ubuntu-latest`, and `macos-latest`. Keep all three targets
green when changing native code or platform-specific test fixtures.
