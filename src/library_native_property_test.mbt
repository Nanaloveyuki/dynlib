///|
fn lifecycle_sequence_holds(actions : Array[Int]) -> Bool {
  let library = match @dynlib.load(platform_library_for_test()) {
    Ok(value) => value
    Err(_) => return false
  }
  let symbol = match library.resolve(platform_symbol_for_test()) {
    Ok(value) => value
    Err(_) => {
      ignore(library.close())
      return false
    }
  }
  let mut closed = false
  let mut valid = true
  for action in actions {
    if valid {
      match action & 3 {
        0 =>
          match library.resolve(platform_symbol_for_test()) {
            Ok(candidate) =>
              valid = match candidate.address() {
                Ok(address) => !closed && address != 0UL
                Err(_) => false
              }
            Err(Closed) => valid = closed
            Err(_) => valid = false
          }
        1 =>
          valid = match symbol.address() {
            Ok(address) => !closed && address != 0UL
            Err(Closed) => closed
            Err(_) => false
          }
        2 => {
          let result = library.close()
          if result == Ok(()) {
            closed = true
          } else {
            valid = false
          }
        }
        _ => valid = library.is_open() == !closed
      }
    }
  }
  let final_close = library.close()
  valid &&
  final_close == Ok(()) &&
  !library.is_open() &&
  symbol.address() == Err(Closed)
}

///|
test "generated lifecycle sequences preserve handle state" {
  @quickcheck.check(
    (actions : Array[Int]) => lifecycle_sequence_holds(actions),
    count=128,
    max_size=96,
    max_shrinks=192,
    seed=2026082503UL,
  )
}

///|
test "generated NUL symbols are rejected without closing the library" {
  @quickcheck.check(
    (input : (String, String, Bool)) => {
      let (prefix, suffix, at_start) = input
      let library = match @dynlib.load(platform_library_for_test()) {
        Ok(value) => value
        Err(_) => return false
      }
      let name = property_name_with_nul(prefix, suffix, at_start)
      let rejected = match library.resolve(name) {
        Err(InvalidSymbolName) => true
        _ => false
      }
      let remains_open = library.is_open()
      let closed = library.close() == Ok(())
      rejected && remains_open && closed
    },
    count=128,
    max_size=64,
    max_shrinks=128,
    seed=2026082504UL,
  )
}

///|
test "generated missing symbols preserve the requested name" {
  @quickcheck.check(
    (suffix : String) => {
      let library = match @dynlib.load(platform_library_for_test()) {
        Ok(value) => value
        Err(_) => return false
      }
      let name = "dynlib_property_missing_symbol_" + suffix
      let preserved = match library.resolve(name) {
        Err(SymbolNotFound(found)) => found == name
        _ => false
      }
      let closed = library.close() == Ok(())
      preserved && closed
    },
    filter=suffix => !suffix.contains_code_unit(0),
    count=128,
    max_size=64,
    max_shrinks=128,
    seed=2026082505UL,
  )
}
