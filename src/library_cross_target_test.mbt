///|
test "unsupported targets fail explicitly" {
  match load("dynlib-test-library") {
    Err(UnsupportedTarget) => ()
    _ => abort("non-native target should report UnsupportedTarget")
  }
}

///|
test "input validation happens before target dispatch" {
  match load("") {
    Err(InvalidLibraryPath) => ()
    _ => abort("empty path should be rejected")
  }
  match load("bad\u{0000}path") {
    Err(InvalidLibraryPath) => ()
    _ => abort("NUL path should be rejected")
  }
}
