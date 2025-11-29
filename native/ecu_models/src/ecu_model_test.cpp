#include <iostream>
#include "ecu_models.h"

int main(int argc, char** argv) {

  print_ttctk_version();
  
  const char* json = get_mock_ecus();
  if (!json) {
    std::cerr << "get_mock_ecus returned null\n";
  } else {
    std::cout << "Mock ECUs JSON:\n" << json << "\n";
    free_cstring(json);
  }
  return 0;
}