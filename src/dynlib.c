#include <moonbit.h>

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#else
#include <dlfcn.h>
#endif

static char *dynlib_copy_utf8(moonbit_bytes_t value) {
  if (value == NULL) return NULL;
  int32_t length = Moonbit_array_length(value);
  if (length < 0) return NULL;
  char *copy = (char *)malloc((size_t)length + 1);
  if (copy == NULL) return NULL;
  if (length > 0) memcpy(copy, value, (size_t)length);
  copy[length] = '\0';
  return copy;
}

#ifdef _WIN32
static wchar_t *dynlib_utf8_to_wide(moonbit_bytes_t value) {
  if (value == NULL) return NULL;
  int32_t length = Moonbit_array_length(value);
  if (length < 0) return NULL;
  int wide_length = MultiByteToWideChar(
      CP_UTF8, MB_ERR_INVALID_CHARS, (const char *)value, length, NULL, 0);
  if (wide_length <= 0) return NULL;
  wchar_t *wide = (wchar_t *)malloc(((size_t)wide_length + 1) * sizeof(wchar_t));
  if (wide == NULL) return NULL;
  int written = MultiByteToWideChar(
      CP_UTF8, MB_ERR_INVALID_CHARS, (const char *)value, length, wide, wide_length);
  if (written != wide_length) {
    free(wide);
    return NULL;
  }
  wide[wide_length] = L'\0';
  return wide;
}
#endif

MOONBIT_FFI_EXPORT uint64_t dynlib_load(moonbit_bytes_t path) {
#ifdef _WIN32
  wchar_t *wide_path = dynlib_utf8_to_wide(path);
  if (wide_path == NULL) return 0;
  HMODULE library = LoadLibraryW(wide_path);
  free(wide_path);
  return (uint64_t)(uintptr_t)library;
#else
  char *utf8_path = dynlib_copy_utf8(path);
  if (utf8_path == NULL) return 0;
  void *library = dlopen(utf8_path, RTLD_NOW | RTLD_LOCAL);
  free(utf8_path);
  return (uint64_t)(uintptr_t)library;
#endif
}

MOONBIT_FFI_EXPORT uint64_t dynlib_resolve(uint64_t handle, moonbit_bytes_t name) {
  if (handle == 0) return 0;
  char *utf8_name = dynlib_copy_utf8(name);
  if (utf8_name == NULL) return 0;
#ifdef _WIN32
  FARPROC symbol = GetProcAddress((HMODULE)(uintptr_t)handle, utf8_name);
  free(utf8_name);
  return (uint64_t)(uintptr_t)symbol;
#else
  dlerror();
  void *symbol = dlsym((void *)(uintptr_t)handle, utf8_name);
  free(utf8_name);
  return (uint64_t)(uintptr_t)symbol;
#endif
}

MOONBIT_FFI_EXPORT int32_t dynlib_close(uint64_t handle) {
  if (handle == 0) return 1;
#ifdef _WIN32
  return FreeLibrary((HMODULE)(uintptr_t)handle) != 0;
#else
  return dlclose((void *)(uintptr_t)handle) == 0;
#endif
}

MOONBIT_FFI_EXPORT int32_t dynlib_platform(void) {
#ifdef _WIN32
  return 1;
#elif defined(__APPLE__)
  return 3;
#elif defined(__linux__)
  return 2;
#else
  return 0;
#endif
}
