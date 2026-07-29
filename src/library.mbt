///|
/// A failure produced while loading, resolving, or closing a native library.
pub(all) enum DynlibError {
  InvalidLibraryPath
  InvalidSymbolName
  LoadFailed
  SymbolNotFound(String)
  CloseFailed
  Closed
} derive(Eq, Debug)

///|
/// An explicitly owned native dynamic-library handle.
///
/// Call close when the library is no longer needed. Closing is idempotent.
pub struct Library {
  priv mut handle : UInt64
}

///|
/// A resolved symbol tied to the library that produced it.
///
/// The address cannot be obtained after the source library is closed.
pub struct Symbol {
  priv library : Library
  priv address : UInt64
}

///|
fn has_nul(value : String) -> Bool {
  value.contains_code_unit(0)
}

///|
fn encode_utf8(value : String) -> Bytes {
  @utf8.encode(value)
}

///|
/// Loads a dynamic library by absolute path or platform loader name.
///
/// Paths are encoded as UTF-8. On Windows they are converted to UTF-16 before
/// calling the operating system loader.
pub fn load(path : String) -> Result[Library, DynlibError] {
  if path.is_empty() || has_nul(path) {
    return Err(InvalidLibraryPath)
  }
  let handle = native_load(encode_utf8(path))
  if handle == 0UL {
    Err(LoadFailed)
  } else {
    Ok({ handle, })
  }
}

///|
/// Returns whether this library remains open.
pub fn Library::is_open(self : Library) -> Bool {
  self.handle != 0UL
}

///|
/// Resolves a native symbol without invoking it.
///
/// Dynamic function calls are deliberately outside this package's API because
/// calling conventions and signatures must be modeled by the consuming FFI.
pub fn Library::resolve(
  self : Library,
  name : String,
) -> Result[Symbol, DynlibError] {
  if !self.is_open() {
    return Err(Closed)
  }
  if name.is_empty() || has_nul(name) {
    return Err(InvalidSymbolName)
  }
  let address = native_resolve(self.handle, encode_utf8(name))
  if address == 0UL {
    Err(SymbolNotFound(name))
  } else {
    Ok({ library: self, address })
  }
}

///|
/// Returns a raw symbol address while its source library remains open.
///
/// The caller must not retain or invoke the address after Library::close.
pub fn Symbol::address(self : Symbol) -> Result[UInt64, DynlibError] {
  if self.library.is_open() {
    Ok(self.address)
  } else {
    Err(Closed)
  }
}

///|
/// Unloads the library. Calling close again returns success without touching
/// the operating system handle.
pub fn Library::close(self : Library) -> Result[Unit, DynlibError] {
  if !self.is_open() {
    return Ok(())
  }
  if native_close(self.handle) {
    self.handle = 0UL
    Ok(())
  } else {
    Err(CloseFailed)
  }
}
