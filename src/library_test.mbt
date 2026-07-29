///|
extern "C" fn native_platform() -> Int = "dynlib_platform"

///|
fn platform_library_for_test() -> String {
  match native_platform() {
    1 => "kernel32.dll"
    2 => "libc.so.6"
    3 => "/usr/lib/libSystem.B.dylib"
    _ => ""
  }
}

///|
fn platform_symbol_for_test() -> String {
  match native_platform() {
    1 => "GetTickCount64"
    2 | 3 => "printf"
    _ => ""
  }
}

///|
test "load and resolve a platform library" {
  let library_name = platform_library_for_test()
  let symbol_name = platform_symbol_for_test()
  let library = match load(library_name) {
    Ok(value) => value
    Err(_) => abort("could not load test library")
  }
  let symbol = match library.resolve(symbol_name) {
    Ok(value) => value
    Err(_) => abort("could not resolve test symbol")
  }
  let address = match symbol.address() {
    Ok(value) => value
    Err(_) => abort("could not read test symbol")
  }
  assert_true(address != 0UL)
  assert_true(library.is_open())
  assert_eq(library.close(), Ok(()))
  assert_eq(library.close(), Ok(()))
  assert_false(library.is_open())
  assert_eq(symbol.address(), Err(Closed))
}

///|
test "reject invalid names before native calls" {
  match load("") {
    Err(InvalidLibraryPath) => ()
    _ => abort("empty path should be rejected")
  }
  match load("bad\u{0000}name") {
    Err(InvalidLibraryPath) => ()
    _ => abort("NUL path should be rejected")
  }
  let library = match load(platform_library_for_test()) {
    Ok(value) => value
    Err(_) => abort("could not load test library")
  }
  match library.resolve("") {
    Err(InvalidSymbolName) => ()
    _ => abort("empty symbol should be rejected")
  }
  match library.resolve("bad\u{0000}symbol") {
    Err(InvalidSymbolName) => ()
    _ => abort("NUL symbol should be rejected")
  }
  assert_eq(library.close(), Ok(()))
}

///|
test "report loader and resolver failures" {
  match load("dynlib-definitely-missing-library") {
    Err(LoadFailed) => ()
    _ => abort("expected load failure")
  }
  let library = match load(platform_library_for_test()) {
    Ok(value) => value
    Err(_) => abort("could not load test library")
  }
  match library.resolve("dynlib_definitely_missing_symbol") {
    Err(SymbolNotFound(_)) => ()
    _ => abort("expected symbol failure")
  }
  assert_eq(library.close(), Ok(()))
}
