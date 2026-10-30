"""Exercise the production reset branches with in-memory RPC/storage/reboot fakes.

No settings file is touched and no power command is executed.
"""
from pathlib import Path
import os
import subprocess

ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT.parent / 'OpenHD'
SYS = ROOT.parent / 'OpenHD-SysUtils'


def block(text, marker):
    start = text.index(marker)
    opening = text.index('{', start)
    depth, end = 1, opening + 1
    while depth:
        depth += (text[end] == '{') - (text[end] == '}')
        end += 1
    return text[start:end]


core = block((CORE / 'ohd_telemetry/src/internal/OHDMainComponent.cpp').read_text(),
             'if (command.command == MAV_CMD_PREFLIGHT_STORAGE)')
sys = block((SYS / 'src/sysutil_settings.cpp').read_text(),
            'if (extract_bool_field(line, "reset_defaults").value_or(false))')
source = r'''
#include <cassert>
#include <chrono>
#include <iostream>
#include <optional>
#include <vector>
#include <nlohmann/json.hpp>
#include "sysutil_config.h"
using nlohmann::json;
enum { MAV_CMD_PREFLIGHT_STORAGE=245, MAV_RESULT_ACCEPTED=0, MAV_RESULT_DENIED=2,
       MAV_RESULT_UNSUPPORTED=3, MAV_RESULT_FAILED=4 };
struct Command { int command=245; float param1=2,param2=0,param3=0,param4=0,param5=0,param6=0,param7=0; };
namespace sysutil {
SysutilConfig saved;
bool writable=true;
int writes=0;
bool write_sysutil_config(const SysutilConfig& config) { ++writes; if(!writable)return false; saved=config; return true; }
std::optional<bool> extract_bool_field(const std::string& line,const char* key) {
 auto j=json::parse(line);if(!j.contains(key))return {};return j.at(key).get<bool>();
}
std::optional<std::string> extract_string_field(const std::string& line,const char* key) {
 auto j=json::parse(line);if(!j.contains(key))return {};return j.at(key).get<std::string>();
}
std::string update(const std::string& line,SysutilConfig config) {
@SYS@
 return "{}";
}
}
namespace openhd {
struct ArmingStateHelper {
 bool armed=false;
 static ArmingStateHelper& instance(){static ArmingStateHelper value;return value;}
 bool is_currently_armed(){return armed;}
};
std::optional<json> response=json{{"ok",true},{"reset_defaults_applied",true}};
json request;
int requests=0;
std::optional<json> request_sysutil_json(json value,std::chrono::milliseconds) { ++requests;request=value;return response; }
namespace reboot {int calls=0;void handle_power_command_async(std::chrono::seconds,bool shutdown){assert(!shutdown);++calls;}}
}
struct Handler {
 bool RUNS_ON_AIR=true,m_settings_reset_scheduled=false,m_storage_format_running=false;
 int ack_command_result(int,int,int,int result){return result;}
 int run(Command command={}) {
  int source_sys_id=255,source_comp_id=190;std::vector<int> message_buffer;
@CORE@
  return message_buffer.at(0);
 }
};
int main() {
 Handler h;Command invalid;invalid.param1=1;
 assert(h.run(invalid)==MAV_RESULT_DENIED && openhd::requests==0);
 openhd::ArmingStateHelper::instance().armed=true;
 assert(h.run()==MAV_RESULT_DENIED && openhd::requests==0);
 openhd::ArmingStateHelper::instance().armed=false;
 h.m_storage_format_running=true;assert(h.run()==MAV_RESULT_DENIED);h.m_storage_format_running=false;
 openhd::response=json{{"ok",true}};assert(h.run()==MAV_RESULT_UNSUPPORTED && !h.m_settings_reset_scheduled);
 openhd::response.reset();assert(h.run()==MAV_RESULT_FAILED && !h.m_settings_reset_scheduled);
 openhd::response=json{{"ok",false},{"reset_defaults_applied",false}};assert(h.run()==MAV_RESULT_FAILED);
 openhd::response=json{{"ok",true},{"reset_defaults_applied",true}};
 assert(h.run()==MAV_RESULT_ACCEPTED && openhd::reboot::calls==1);
 assert(openhd::request.at("run_mode")=="air");
 auto requests=openhd::requests;
 assert(h.run()==MAV_RESULT_ACCEPTED && openhd::requests==requests && openhd::reboot::calls==1);
 Handler ground;ground.RUNS_ON_AIR=false;assert(ground.run()==MAV_RESULT_ACCEPTED);
 assert(openhd::request.at("run_mode")=="ground");
 sysutil::SysutilConfig config;config.platform_type=20;config.platform_name="ROCK 5A";
 config.run_mode="air";config.camera_type=64;config.camera2_type=3;config.wifi_local_network_password="private";
 config.display_force_mode=true;config.disable_ethernet_link=true;config.debug_enabled=true;
 auto result=json::parse(sysutil::update(R"({"reset_defaults":true,"run_mode":"air"})",config));
 assert(result.at("ok")==true && result.at("reset_defaults_applied")==true);
 assert(sysutil::saved.platform_type==20 && sysutil::saved.platform_name=="ROCK 5A" && sysutil::saved.run_mode=="air");
 assert(!sysutil::saved.camera_type && !sysutil::saved.camera2_type && !sysutil::saved.wifi_local_network_password);
 assert(!sysutil::saved.display_force_mode && !sysutil::saved.disable_ethernet_link && !sysutil::saved.debug_enabled);
 assert(sysutil::saved.reset_requested==true && sysutil::saved.firstboot==false);
 sysutil::writable=false;
 result=json::parse(sysutil::update(R"({"reset_defaults":true,"run_mode":"ground"})",config));
 assert(result.at("ok")==false && result.at("reset_defaults_applied")==false);
 std::cout<<"PASS: targeted reset, arming/storage guards, unsupported and failed RPC, retry deduplication, reboot scheduling, hardware/role preservation and defaults\n";
}
'''.replace('@SYS@', sys).replace('@CORE@', core)
folder = ROOT / 'build/device-settings-reset-test'
folder.mkdir(parents=True, exist_ok=True)
(folder / 'test.cpp').write_text(source)
compiler = Path('C:/Qt/Tools/mingw810_64/bin/g++.exe')
env = dict(os.environ, PATH=str(compiler.parent) + os.pathsep + os.environ.get('PATH', ''))
exe = folder / 'test.exe'
subprocess.run([str(compiler), '-std=c++17', '-O0', '-I'+str(SYS/'inc'),
                '-I'+str(CORE/'ohd_common/lib/json/single_include'),
                str(folder/'test.cpp'), '-o', str(exe)], check=True, env=env)
subprocess.run([str(exe)], check=True, env=env)
