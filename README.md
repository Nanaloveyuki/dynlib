# dynlib

`Nanaloveyuki/dynlib` is a native-only MoonBit package for loading dynamic
libraries on Windows, Linux, and macOS.

## Install

Add the package to your `moon.mod`:

```moonbit
import {
  "Nanaloveyuki/dynlib@0.1.0",
}
```

Build the consuming package for the native target.

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

## Close

Close each loaded library at a deterministic shutdown point:

```moonbit
ignore(library.close())
```

`Library::close` is idempotent. After it succeeds, `Library::resolve` and
`Symbol::address` return `Closed`; do not retain or use a previously returned
address.
