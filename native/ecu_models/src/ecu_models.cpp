#include <cstdlib>
#include <cstring>

extern "C" {

// Returns a malloc'd C string containing JSON array of mocked ECUs with extended metadata.
// Caller must call free_cstring() to release the memory.
const char* get_mock_ecus() {
    const char* json = "["
        "{\"name\":\"Engine Control Module\",\"txId\":2016,\"rxId\":2024,\"bootloaderVersion\":\"1.2.0\",\"serialNumber\":\"ECU-ENG-0001\",\"appVersion\":\"2.5.3\",\"appBuildDate\":\"2025-11-01\",\"hardwareType\":\"ENG-V1\",\"productionCode\":\"P-ENG-2025\"},"
        "{\"name\":\"Transmission Control\",\"txId\":2017,\"rxId\":2025,\"bootloaderVersion\":\"3.0.1\",\"serialNumber\":\"ECU-TRN-0042\",\"appVersion\":\"1.8.0\",\"appBuildDate\":\"2025-10-20\",\"hardwareType\":\"TRN-X\",\"productionCode\":\"P-TRN-2024\"},"
        "{\"name\":\"Random Module\",\"txId\":2018,\"rxId\":2026,\"bootloaderVersion\":\"0.9.7\",\"serialNumber\":\"ECU-ABS-0020\",\"appVersion\":\"4.0.1\",\"appBuildDate\":\"2025-09-15\",\"hardwareType\":\"ABS-PRO\",\"productionCode\":\"P-ABS-2023\"}"
    "]";

    size_t len = std::strlen(json) + 1;
    char* buf = (char*)std::malloc(len);
    if (!buf) return nullptr;
    std::memcpy(buf, json, len);
    return buf;
}

void free_cstring(const char* p) {
    if (p) std::free((void*)p);
}

} // extern C
