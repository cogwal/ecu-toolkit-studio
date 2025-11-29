#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "ecu_models.h"

#include "ttctk_can.h"
#include "ttctk_common.h"
#include "ttctk_program.h"
#include "ttctk_data.h"

#ifdef _WIN32
#include <windows.h>
#include <PCANBasic.h>
#endif

// Begin C API
// ----------

// TODO figure out if I should just switch to c++ if it's easier to generate json objects

// Implementations use C linkage to match the header declarations.

ECU_EXPORT void print_ttctk_version()
{
    TkStatusType res = TK_STATUS_OK;
    uint16_t major;
    uint16_t minor;
    uint16_t patch;

        /* check the TTC Toolkit version */
    res = TK_GetVersion(&major, &minor, &patch);
    if (res == TK_STATUS_OK)
    {
        printf("-- APP: TTC Toolkit version %u.%u.%u\n", major, minor, patch);
    }
    else
    {
        printf("-- APP: Failed to get the TTC Toolkit version, error code = %u\n", res);
    }
}

// Returns a malloc'd C string containing JSON array of mocked ECUs with extended metadata.
// Caller must call free_cstring() to release the memory.
ECU_EXPORT const char* get_mock_ecus() {
    const char* json = "["
        "{\"name\":\"Engine Control Module\",\"txId\":2016,\"rxId\":2024,\"bootloaderVersion\":\"1.2.0\",\"serialNumber\":\"ECU-ENG-0001\",\"appVersion\":\"2.5.3\",\"appBuildDate\":\"2025-11-01\",\"hardwareType\":\"ENG-V1\",\"productionCode\":\"P-ENG-2025\"},"
        "{\"name\":\"Transmission Control\",\"txId\":2017,\"rxId\":2025,\"bootloaderVersion\":\"3.0.1\",\"serialNumber\":\"ECU-TRN-0042\",\"appVersion\":\"1.8.0\",\"appBuildDate\":\"2025-10-20\",\"hardwareType\":\"TRN-X\",\"productionCode\":\"P-TRN-2024\"},"
        "{\"name\":\"Random Module\",\"txId\":2018,\"rxId\":2026,\"bootloaderVersion\":\"0.9.7\",\"serialNumber\":\"ECU-ABS-0020\",\"appVersion\":\"4.0.1\",\"appBuildDate\":\"2025-09-15\",\"hardwareType\":\"ABS-PRO\",\"productionCode\":\"P-ABS-2023\"}"
    "]";

    size_t len = strlen(json) + 1;
    char* buf = (char*)malloc(len);
    if (!buf) return NULL;
    memcpy(buf, json, len);
    return buf;
}

ECU_EXPORT void free_cstring(const char* p) {
    if (p) free((void*)p);
}

// ----------
