#include <iostream>
#include "ecu_models.h"

int main(int argc, char **argv)
{

  const char *version = get_ttctk_version();

  if (!version)
  {
    std::cerr << "get_ttctk_version returned null\n";
  }
  else
  {
    std::cout << "TTC Toolkit Version: " << version << "\n";
  }

  const char *json = get_mock_ecus();
  if (!json)
  {
    std::cerr << "get_mock_ecus returned null\n";
  }
  else
  {
    std::cout << "Mock ECUs JSON:\n"
              << json << "\n";
    free_cstring(json);
  }

  return 0;
}