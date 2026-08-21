# dynlib

`Nanaloveyuki/dynlib` is a MoonBit package for loading dynamic libraries on
native targets. The package also compiles for `js`, `wasm`, and `wasm-gc`; those
targets return `UnsupportedTarget` because their runtime does not provide the
native dynamic-library loader used by this API.

## Install

Add the package to your `moon.mod`:

```moonbit
import {
  "Nanaloveyuki/dynlib@0.2.0",
}
```

Build the consuming package for a native target to load libraries. Cross-target
builds remain available when the package is part of a shared library.

## Load, Resolve, and Read an Address

Load a platform library name or an absolute library path, resolve a symbol,
then obtain its address:

```moonbit
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

// Use address only with an explicit, ABI-correct native binding.
ignore(address)
```

`dynlib` does not invoke resolved symbols. The consuming package owns the FFI
signature and calling convention.

`DynlibError` does not include operating-system diagnostic strings or requested
paths. Handle `InvalidLibraryPath`, `InvalidSymbolName`, `LoadFailed`,
`ResolveFailed`, `SymbolNotFound`, `OutOfMemory`, `InvalidUtf8`, and
`UnsupportedTarget` explicitly when the distinction matters.

## Close

Close each loaded library at a deterministic shutdown point:

```moonbit
ignore(library.close())
```

`Library::close` is idempotent. After it succeeds, `Library::resolve` and
`Symbol::address` return `Closed`; do not retain or use a previously returned
address. Do not call `resolve`, `address`, or `close` concurrently for the same
library; the package does not provide a synchronization or symbol lease API.
