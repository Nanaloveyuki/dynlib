///|
test "unsupported targets fail explicitly" {
  match @dynlib.load("dynlib-test-library") {
    Err(UnsupportedTarget) => ()
    _ => abort("non-native target should report UnsupportedTarget")
  }
}

///|
test "input validation happens before target dispatch" {
  match @dynlib.load("") {
    Err(InvalidLibraryPath) => ()
    _ => abort("empty path should be rejected")
  }
  match @dynlib.load("bad\u{0000}path") {
    Err(InvalidLibraryPath) => ()
    _ => abort("NUL path should be rejected")
  }
}
