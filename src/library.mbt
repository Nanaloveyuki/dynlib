///|
/// A failure produced while loading, resolving, or closing a dynamic library.
pub(all) enum DynlibError {
  UnsupportedTarget
  InvalidLibraryPath
  InvalidSymbolName
  InvalidUtf8
  OutOfMemory
  LoadFailed
  ResolveFailed
  SymbolNotFound(String)
  InvalidHandle
  CloseFailed
  Closed
} derive(Eq, Debug)

///|
pub extend DynlibError with Eq::{equal}

///|
#deprecated("Use `!=` instead", skip_current_package=true)
#doc(hidden)
pub extend DynlibError with Eq::{not_equal}

///|
#deprecated("Use `Debug::to_repr` instead", skip_current_package=true)
#doc(hidden)
pub extend DynlibError with @debug.Debug::{to_repr}

///|
/// An explicitly owned native dynamic-library handle.
///
/// Call close when the library is no longer needed. Closing is idempotent.
pub struct Library {
  priv handle : NativeHandle
  priv mut closed : Bool
}

///|
/// A resolved symbol tied to the library that produced it.
///
/// The address cannot be obtained after the source library is closed.
pub struct Symbol {
  priv library : Library
  priv address : NativeAddress
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
fn load_error(code : Int) -> DynlibError {
  if code == ffi_error_unsupported_target {
    UnsupportedTarget
  } else if code == ffi_error_invalid_argument {
    InvalidLibraryPath
  } else if code == ffi_error_invalid_utf8 {
    InvalidUtf8
  } else if code == ffi_error_out_of_memory {
    OutOfMemory
  } else if code == ffi_error_load_failed {
    LoadFailed
  } else {
    LoadFailed
  }
}

///|
fn resolve_error(code : Int, name : String) -> DynlibError {
  if code == ffi_error_unsupported_target {
    UnsupportedTarget
  } else if code == ffi_error_invalid_argument {
    InvalidSymbolName
  } else if code == ffi_error_invalid_utf8 {
    InvalidUtf8
  } else if code == ffi_error_out_of_memory {
    OutOfMemory
  } else if code == ffi_error_invalid_handle {
    InvalidHandle
  } else if code == ffi_error_symbol_not_found {
    SymbolNotFound(name)
  } else {
    ResolveFailed
  }
}

///|
fn close_error(code : Int) -> DynlibError {
  if code == ffi_error_unsupported_target {
    UnsupportedTarget
  } else if code == ffi_error_invalid_handle {
    InvalidHandle
  } else if code == ffi_error_close_failed {
    CloseFailed
  } else {
    CloseFailed
  }
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
  if native_is_null(handle) {
    Err(load_error(native_last_error()))
  } else {
    Ok({ handle, closed: false, })
  }
}

///|
/// Returns whether this library remains open.
pub fn Library::is_open(self : Library) -> Bool {
  !self.closed
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
  if native_address_is_null(address) {
    Err(resolve_error(native_last_error(), name))
  } else {
    Ok({ library: self, address, })
  }
}

///|
/// Returns a raw symbol address while its source library remains open.
///
/// The caller must not retain or invoke the address after Library::close.
pub fn Symbol::address(self : Symbol) -> Result[UInt64, DynlibError] {
  if self.library.is_open() {
    Ok(native_address_value(self.address))
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
  let status = native_close(self.handle)
  if status == ffi_error_ok {
    self.closed = true
    Ok(())
  } else {
    Err(close_error(status))
  }
}
