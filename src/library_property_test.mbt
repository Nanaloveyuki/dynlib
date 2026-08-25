///|
fn property_name_with_nul(
  prefix : String,
  suffix : String,
  at_start : Bool,
) -> String {
  if at_start {
    "\u{0000}" + prefix + suffix
  } else {
    prefix + suffix + "\u{0000}"
  }
}

///|
test "generated NUL paths are rejected before target dispatch" {
  @quickcheck.check(
    (input : (String, String, Bool)) => {
      let (prefix, suffix, at_start) = input
      let path = property_name_with_nul(prefix, suffix, at_start)
      match load(path) {
        Err(InvalidLibraryPath) => true
        _ => false
      }
    },
    count=128,
    max_size=64,
    max_shrinks=128,
    seed=2026082501UL,
  )
}

///|
test "generated valid paths are not classified as malformed" {
  @quickcheck.check(
    (path : String) => {
      match load(path) {
        Err(InvalidLibraryPath) | Err(InvalidUtf8) => false
        Ok(library) => library.close() == Ok(())
        Err(_) => true
      }
    },
    filter=path => !path.is_empty() && !path.contains_code_unit(0),
    count=128,
    max_size=64,
    max_shrinks=128,
    seed=2026082502UL,
  )
}
