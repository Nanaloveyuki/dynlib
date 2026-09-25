///|
priv struct NativeHandle {
  raw : UInt64
}

///|
priv struct NativeAddress {
  raw : UInt64
}

///|
fn native_load(path : Bytes) -> NativeHandle {
  ignore(path)
  { raw: 0UL, }
}

///|
fn native_is_null(value : NativeHandle) -> Bool {
  value.raw == 0UL
}

///|
fn native_resolve(handle : NativeHandle, name : Bytes) -> NativeAddress {
  ignore(handle)
  ignore(name)
  { raw: 0UL, }
}

///|
fn native_address_is_null(value : NativeAddress) -> Bool {
  value.raw == 0UL
}

///|
fn native_address_value(value : NativeAddress) -> UInt64 {
  value.raw
}

///|
fn native_close(handle : NativeHandle) -> Int {
  ignore(handle)
  ffi_error_unsupported_target
}

///|
fn native_last_error() -> Int {
  ffi_error_unsupported_target
}
