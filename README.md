# dynlib

Nanaloveyuki/dynlib is a native-only MoonBit library for checked dynamic
library loading on Windows, Linux, and macOS. It wraps the platform loader and
intentionally does not expose dynamic function calls: an FFI signature and its
calling convention must remain explicit in the consuming package.

## Install

    import {
      "Nanaloveyuki/dynlib@0.1.0",
    }

The package requires MoonBit's native target.

## API

    // Load either a platform loader name or an absolute library path.
    let library = match @dynlib.load("example-library") {
      Ok(value) => value
      Err(error) => abort("load failed: \{error}")
    }

    let symbol = match library.resolve("example_symbol") {
      Ok(value) => value
      Err(error) => abort("symbol missing: \{error}")
    }

    let address = match symbol.address() {
      Ok(value) => value
      Err(error) => abort("library was closed: \{error}")
    }

    // Pass address only to an explicit, ABI-correct native binding.
    ignore(address)
    ignore(library.close())

Library::close is idempotent. After it returns success, Library::resolve and
Symbol::address report Closed and no raw address may be used.

## Guarantees and limits

- Windows paths are UTF-8 at the MoonBit boundary and are converted to UTF-16
  before LoadLibraryW.
- Linux and macOS use dlopen with RTLD_NOW | RTLD_LOCAL; symbol resolution uses
  dlsym; closing uses dlclose.
- Symbol names and paths containing NUL are rejected before reaching C.
- DynlibError variants distinguish validation, loading, lookup, close, and
  already-closed failures. Loading errors carry neither platform diagnostic
  text nor the requested path, so local filesystem paths are not exposed.
- A Symbol remains valid only until its source Library closes. The library
  cannot verify a raw address once it leaves this API.
- Automatic unloading is deliberately omitted. Native code should choose a
  deterministic shutdown point and close every successfully loaded library.

## Validation

    moon fmt --check
    moon check --target native --deny-warn --warn-list +73
    moon test --target native --deny-warn --warn-list +73
    moon info

The tests load a standard operating-system library and resolve one stable
symbol on each CI target. They do not invoke a dynamically resolved function.
