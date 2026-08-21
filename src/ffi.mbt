///|
#external
priv type NativeHandle

///|
#external
priv type NativeAddress

///|
#borrow(path)
extern "C" fn native_load(path : Bytes) -> NativeHandle = "dynlib_load"

///|
#borrow(value)
extern "C" fn native_is_null(value : NativeHandle) -> Bool = "dynlib_is_null"

///|
#borrow(handle, name)
extern "C" fn native_resolve(
  handle : NativeHandle,
  name : Bytes,
) -> NativeAddress = "dynlib_resolve"

///|
#borrow(value)
extern "C" fn native_address_is_null(value : NativeAddress) -> Bool = "dynlib_is_null"

///|
#borrow(value)
extern "C" fn native_address_value(value : NativeAddress) -> UInt64 = "dynlib_address_value"

///|
#borrow(handle)
extern "C" fn native_close(handle : NativeHandle) -> Int = "dynlib_close"

///|
extern "C" fn native_last_error() -> Int = "dynlib_last_error"
