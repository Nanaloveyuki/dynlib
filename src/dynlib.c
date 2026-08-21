#include <moonbit.h>

#include <limits.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#else
#include <dlfcn.h>
#endif

enum {
  DYNLIB_OK = 0,
  DYNLIB_INVALID_ARGUMENT = 1,
  DYNLIB_OUT_OF_MEMORY = 2,
  DYNLIB_INVALID_UTF8 = 3,
  DYNLIB_LOAD_FAILED = 4,
  DYNLIB_INVALID_HANDLE = 5,
  DYNLIB_SYMBOL_NOT_FOUND = 6,
  DYNLIB_CLOSE_FAILED = 7,
};

#if defined(_WIN32) && defined(_MSC_VER)
#define DYNLIB_THREAD_LOCAL __declspec(thread)
#else
#define DYNLIB_THREAD_LOCAL _Thread_local
#endif

static DYNLIB_THREAD_LOCAL int32_t dynlib_error = DYNLIB_OK;

static void dynlib_set_error(int32_t error) {
  dynlib_error = error;
}

static char *dynlib_copy_utf8(moonbit_bytes_t value, int32_t *error) {
  if (value == NULL) {
    *error = DYNLIB_INVALID_ARGUMENT;
    return NULL;
  }

  int32_t length = Moonbit_array_length(value);
  if (length < 0 || (size_t)length > SIZE_MAX - 1) {
    *error = DYNLIB_INVALID_ARGUMENT;
    return NULL;
  }

  char *copy = (char *)malloc((size_t)length + 1);
  if (copy == NULL) {
    *error = DYNLIB_OUT_OF_MEMORY;
    return NULL;
  }

  if (length > 0) memcpy(copy, value, (size_t)length);
  copy[length] = '\0';
  *error = DYNLIB_OK;
  return copy;
}

#ifdef _WIN32
static wchar_t *dynlib_utf8_to_wide(moonbit_bytes_t value, int32_t *error) {
  int32_t copy_error = DYNLIB_OK;
  char *utf8 = dynlib_copy_utf8(value, &copy_error);
  if (utf8 == NULL) {
    *error = copy_error;
    return NULL;
  }

  int32_t byte_length = Moonbit_array_length(value);
  if (byte_length < 0 || byte_length > INT_MAX) {
    free(utf8);
    *error = DYNLIB_INVALID_ARGUMENT;
    return NULL;
  }

  int wide_length = MultiByteToWideChar(
      CP_UTF8, MB_ERR_INVALID_CHARS, utf8, byte_length, NULL, 0);
  if (wide_length <= 0) {
    free(utf8);
    *error = DYNLIB_INVALID_UTF8;
    return NULL;
  }

  if ((size_t)wide_length > SIZE_MAX / sizeof(wchar_t) - 1) {
    free(utf8);
    *error = DYNLIB_INVALID_ARGUMENT;
    return NULL;
  }

  wchar_t *wide = (wchar_t *)malloc(((size_t)wide_length + 1) * sizeof(wchar_t));
  if (wide == NULL) {
    free(utf8);
    *error = DYNLIB_OUT_OF_MEMORY;
    return NULL;
  }

  int written = MultiByteToWideChar(
      CP_UTF8, MB_ERR_INVALID_CHARS, utf8, byte_length, wide, wide_length);
  free(utf8);
  if (written != wide_length) {
    free(wide);
    *error = DYNLIB_INVALID_UTF8;
    return NULL;
  }

  wide[wide_length] = L'\0';
  *error = DYNLIB_OK;
  return wide;
}
#endif

MOONBIT_FFI_EXPORT void *dynlib_load(moonbit_bytes_t path) {
  int32_t error = DYNLIB_OK;
#ifdef _WIN32
  wchar_t *wide_path = dynlib_utf8_to_wide(path, &error);
  if (wide_path == NULL) {
    dynlib_set_error(error);
    return NULL;
  }

  HMODULE library = LoadLibraryW(wide_path);
  free(wide_path);
  if (library == NULL) {
    dynlib_set_error(DYNLIB_LOAD_FAILED);
    return NULL;
  }

  dynlib_set_error(DYNLIB_OK);
  return (void *)library;
#else
  char *utf8_path = dynlib_copy_utf8(path, &error);
  if (utf8_path == NULL) {
    dynlib_set_error(error);
    return NULL;
  }

  void *library = dlopen(utf8_path, RTLD_NOW | RTLD_LOCAL);
  free(utf8_path);
  if (library == NULL) {
    dynlib_set_error(DYNLIB_LOAD_FAILED);
    return NULL;
  }

  dynlib_set_error(DYNLIB_OK);
  return library;
#endif
}

MOONBIT_FFI_EXPORT int32_t dynlib_is_null(void *value) {
  return value == NULL;
}

MOONBIT_FFI_EXPORT void *dynlib_resolve(void *handle, moonbit_bytes_t name) {
  if (handle == NULL) {
    dynlib_set_error(DYNLIB_INVALID_HANDLE);
    return NULL;
  }

  int32_t error = DYNLIB_OK;
  char *utf8_name = dynlib_copy_utf8(name, &error);
  if (utf8_name == NULL) {
    dynlib_set_error(error);
    return NULL;
  }

#ifdef _WIN32
  FARPROC symbol = GetProcAddress((HMODULE)handle, utf8_name);
  free(utf8_name);
  if (symbol == NULL) {
    dynlib_set_error(DYNLIB_SYMBOL_NOT_FOUND);
    return NULL;
  }

  dynlib_set_error(DYNLIB_OK);
  return (void *)(uintptr_t)symbol;
#else
  dlerror();
  void *symbol = dlsym(handle, utf8_name);
  const char *lookup_error = dlerror();
  free(utf8_name);
  if (lookup_error != NULL || symbol == NULL) {
    dynlib_set_error(DYNLIB_SYMBOL_NOT_FOUND);
    return NULL;
  }

  dynlib_set_error(DYNLIB_OK);
  return symbol;
#endif
}

MOONBIT_FFI_EXPORT uint64_t dynlib_address_value(void *value) {
  if (value == NULL) {
    dynlib_set_error(DYNLIB_INVALID_HANDLE);
    return 0;
  }

  dynlib_set_error(DYNLIB_OK);
  return (uint64_t)(uintptr_t)value;
}

MOONBIT_FFI_EXPORT int32_t dynlib_close(void *handle) {
  if (handle == NULL) {
    dynlib_set_error(DYNLIB_INVALID_HANDLE);
    return DYNLIB_INVALID_HANDLE;
  }

#ifdef _WIN32
  if (FreeLibrary((HMODULE)handle) == 0) {
    dynlib_set_error(DYNLIB_CLOSE_FAILED);
    return DYNLIB_CLOSE_FAILED;
  }
#else
  if (dlclose(handle) != 0) {
    dynlib_set_error(DYNLIB_CLOSE_FAILED);
    return DYNLIB_CLOSE_FAILED;
  }
#endif

  dynlib_set_error(DYNLIB_OK);
  return DYNLIB_OK;
}

MOONBIT_FFI_EXPORT int32_t dynlib_last_error(void) {
  return dynlib_error;
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
