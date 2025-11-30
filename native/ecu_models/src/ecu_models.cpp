#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <cstdlib>
#include <cstring>
#include <cstdio>
#include <string>
#include <iostream>

#include "ecu_models.h"

#include "ttctk.h"

#ifdef _WIN32
#include <windows.h>
#include <PCANBasic.h>
#endif

ECU_EXPORT char *get_ttctk_version()
{
    TkStatusType res = TK_STATUS_OK;
    char *version = "Unknown";

    /* check the TTC Toolkit version */
    res = TK_GetVersionString(&version);
    if (res == TK_STATUS_OK)
    {
        std::cout << "-- TTC Toolkit version " << version << '\n';
    }
    else
    {
        std::cout << "-- Failed to get the TTC Toolkit version, error code = " << res << '\n';
    }

    return version;
}

// Returns a malloc'd C string containing JSON array of mocked ECUs with extended metadata.
// Caller must call free_cstring() to release the memory.
ECU_EXPORT const char *get_mock_ecus()
{
    static const std::string json = R"JSON([
        {"name":"Engine Control Module","txId":2016,"rxId":2024,"bootloaderVersion":"1.2.0","serialNumber":"ECU-ENG-0001","appVersion":"2.5.3","appBuildDate":"2025-11-01","hardwareType":"ENG-V1","productionCode":"P-ENG-2025"},
        {"name":"Transmission Control","txId":2017,"rxId":2025,"bootloaderVersion":"3.0.1","serialNumber":"ECU-TRN-0042","appVersion":"1.8.0","appBuildDate":"2025-10-20","hardwareType":"TRN-X","productionCode":"P-TRN-2024"},
        {"name":"Random Module","txId":2018,"rxId":2026,"bootloaderVersion":"0.9.7","serialNumber":"ECU-ABS-0020","appVersion":"4.0.1","appBuildDate":"2025-09-15","hardwareType":"ABS-PRO","productionCode":"P-ABS-2023"}
    ])JSON";

    // Use C allocation so free_cstring can call free()
    size_t len = json.size() + 1;
    char *buf = static_cast<char *>(std::malloc(len));
    if (!buf)
        return nullptr;
    std::memcpy(buf, json.c_str(), len);
    return buf;
}

ECU_EXPORT void free_cstring(const char *p)
{
    if (p)
        std::free(const_cast<char *>(p));
}
