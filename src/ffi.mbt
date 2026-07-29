///|
#borrow(path)
extern "C" fn native_load(path : Bytes) -> UInt64 = "dynlib_load"

///|
#borrow(handle, name)
extern "C" fn native_resolve(handle : UInt64, name : Bytes) -> UInt64 = "dynlib_resolve"

///|
extern "C" fn native_close(handle : UInt64) -> Bool = "dynlib_close"
