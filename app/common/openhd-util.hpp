#ifndef OPENHD_UTIL_H
#define OPENHD_UTIL_H

#include <array>
#include <iostream>
#include <optional>
#include <string>
#include <vector>
#include <sstream>
#include <memory>

#if defined(__linux__) || defined(__macos__)
#include <arpa/inet.h>
#include <netinet/in.h>
#endif // __linux__ || __macos__


namespace OHDUtil {

/**
 * Utility to execute a command on the command line.
 * Blocks until the command has been executed, and returns its result.
 * @param command the command to run
 * @param args the args for the command to run
 * @param print_debug print debug to std::cout, really usefully for debugging. true by default.
 * @return the command result
 * NOTE: Used to use boost, there were issues with that, I changed it to use c standard library.
 */
static bool run_command(const std::string &command, const std::vector<std::string> &args,bool print_debug=true) {
#if defined(__linux__) || defined(__macos__)
  std::stringstream ss;
  ss << command;
  for (const auto &arg: args) {
	ss << " " << arg;
  }
  if(print_debug){
	std::stringstream log;
	log<< "run command begin [" << ss.str() << "]\n";
    std::cout<<log.str();
  }
  // Some weird locale issue ?!
  // https://man7.org/linux/man-pages/man3/system.3.html
  auto ret = system(ss.str().c_str());
  // With boost, there is this locale issue ??!!
  /*boost::process::child c(boost::process::search_path(command), args);
  c.wait();
  std::cout<<"Run command end\n";
  return c.exit_code() == 0;*/
  if(print_debug){
	std::cout << "Run command end\n";
  }
  return ret;
#else
    std::cerr<<"run_command only supported on linux and macos\n";
    return false;
#endif
}

/**
 * from https://stackoverflow.com/questions/646241/c-run-a-system-command-and-get-output
 * also see https://linux.die.net/man/3/popen
 * Not sure how to describe this - it runs a command and returns its shell output.
 * NOTE: This just returns the shell output, it does not check if the executed command is actually available on
 * the system. If the command is not available on the system, it most likely returns "command not found" as a string.
 * @param command the command and its args to run
 * @return the shell output, or std::nullopt if something went wrong.
 */

static std::optional<std::string> run_command_out(const char* command){
#if defined(__linux__) || defined(__macos__)
  std::string raw_value;
  std::array<char, 512> buffer{};
  std::unique_ptr<FILE, decltype(&pclose)> pipe(popen(command, "r"), pclose);
  if (!pipe) {
	// if the pipe opening fails, this doesn't mean the command failed (see above)
	// But rather we need to find a different way to implement this functionality on this platform.
	std::stringstream ss;
	ss<<"run_command_out with "<<command<<" cannot open pipe";
	return std::nullopt;
  }
  while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr) {
	raw_value += buffer.data();
  }
  return raw_value;
#else
    std::cerr<<"run_command only supported on linux and macos\n";
    return std::nullopt;
#endif
}

static std::string yes_or_no(bool yes){
  return (yes ? "Y" : "N");
}

static bool is_valid_ip(const std::string& ip) {
#if defined(__linux__) || defined(__macos__)
  unsigned char buf[sizeof(struct in6_addr)];
  auto result = inet_pton(AF_INET, ip.c_str(), buf);
  return result == 1;
#else
  // TODO find method
  return true;
#endif //#ifdef __linux__

}

}

#endif
