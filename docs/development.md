# Developing dynlib

## Prerequisites

Install a current MoonBit toolchain. Native loader tests require a native
compiler and the platform's system loader. The package is expected to compile
for `native`, `wasm`, `wasm-gc`, and `js`.

## Local validation

Run these commands from the repository root before opening a pull request:

```powershell
moon fmt --check
moon check --target native --deny-warn --warn-list +73
moon test --target native --deny-warn --warn-list +73
moon check --target wasm --deny-warn --warn-list +73
moon test --target wasm --deny-warn --warn-list +73
moon check --target wasm-gc --deny-warn --warn-list +73
moon test --target wasm-gc --deny-warn --warn-list +73
moon check --target js --deny-warn --warn-list +73
moon test --target js --deny-warn --warn-list +73
moon info
git diff --exit-code
```

`moon info` regenerates `src/pkg.generated.mbti`, which is tracked and must be
included when a public API changes.

## Implementation boundaries

Keep the public API limited to loading a library, resolving a symbol, reading
its address, and closing the library. `Library` and `Symbol` must remain
opaque, and closing a library must remain idempotent. Do not add arbitrary
symbol invocation: callers must provide the exact native ABI through their own
FFI declarations.

The native implementation uses C-managed opaque pointers. `Bytes` parameters
are borrowed for the duration of each call and are copied before calling the
operating-system loader; C never stores a MoonBit object. Native failures are
reported through a thread-local status code and mapped to `DynlibError` without
exposing operating-system messages or local paths.

The `js`, `wasm`, and `wasm-gc` implementations are deliberate compile-time
stubs. They reject dynamic-library operations with `UnsupportedTarget` rather
than returning a fake open handle.

Platform code belongs in `src/dynlib.c`:

- Windows uses `LoadLibraryW`, `GetProcAddress`, and `FreeLibrary`.
- Linux and macOS use `dlopen`, `dlsym`, and `dlclose` with `RTLD_NOW |
  RTLD_LOCAL`.

`src/ffi.mbt` is selected for `native` and `llvm`; `src/ffi_stub.mbt` is
selected for `js`, `wasm`, and `wasm-gc`. Keep the target mapping in
`src/moon.pkg` synchronized with those files.

The LLVM backend is experimental in the current MoonBit toolchain and is not
part of the CI gate. When the local toolchain provides its LLVM core bundle, it
uses the same native FFI file.

For a local LLVM installation, put its `bin` directory on `PATH`, build the
MoonBit core bundle once, then validate this package with:

```powershell
$env:PATH = "<llvm-install>\\bin;$env:PATH"
moon -C "$HOME/.moon/lib/core" bundle --target llvm --release --all
moon check --target llvm --deny-warn --warn-list +73
moon build --target llvm --release --deny-warn --warn-list +73
```

MoonBit 0.10.9 can still report `LLVM backend is disabled` when `moon test`
tries to link an LLVM test executable. Treat that as a toolchain limitation;
the package's LLVM check/build path remains valid.

Do not return platform diagnostics or requested library paths through the public
error type. Preserve the explicit error classes for invalid input, target
support, allocation/conversion failures, and loader operations.

The handle lifecycle is not synchronized. A resolved address is only valid
while the source library remains open, so concurrent `resolve`, `address`, and
`close` calls are unsupported. A future thread-safe API would need a lease or
callback boundary that keeps the address alive through actual use; adding a
lock around only `resolve` would not be sufficient.

## Tests and CI

`src/library_test.mbt` uses an operating-system library and stable symbol on
each native platform. The smoke test verifies load, resolve, address access,
idempotent close, and the closed-handle behavior without invoking the resolved
symbol. `src/library_cross_target_test.mbt` verifies explicit unsupported-target
and input-validation behavior on `js`, `wasm`, and `wasm-gc`.

`.github/workflows/validation.yml` runs native validation on
`windows-latest`, `ubuntu-latest`, and `macos-latest`, plus check/test jobs for
`wasm`, `wasm-gc`, and `js` on Ubuntu. Keep the native matrix green when
changing loader code and keep all cross-target jobs green when changing the
public API or target stubs.
