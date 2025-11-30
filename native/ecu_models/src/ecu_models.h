// Header for ecu_models.cpp
// Declares the public C API exported by the ecu_models shared library.

#ifndef ECU_MODELS_H
#define ECU_MODELS_H

#ifdef _WIN32
#  ifdef ECU_MODELS_DLL_EXPORTS
#    define ECU_EXPORT __declspec(dllexport)
#  else
#    define ECU_EXPORT __declspec(dllimport)
#  endif
#else
#  define ECU_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

ECU_EXPORT char *get_ttctk_version();

// Returns a malloc'd C string containing JSON array of mocked ECUs.
// Caller must call free_cstring() to release memory.
ECU_EXPORT const char* get_mock_ecus();

// Frees a C string previously returned from get_mock_ecus().
ECU_EXPORT void free_cstring(const char* p);

#ifdef __cplusplus
}
#endif

#endif // ECU_MODELS_H
