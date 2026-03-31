#ifndef PLATFORM_HPP
#define PLATFORM_HPP

#include <sstream>
#include <string>

// Some things conditionally depend on the platform we are running on

// When this one shows up a bit more work has to be done to run openhd on the
// platform (probably) ;)
static constexpr int X_PLATFORM_TYPE_UNKNOWN = 0;
// Generic X86
static constexpr int X_PLATFORM_TYPE_X86 = 1;
// Numbers 10..20 are reserved for rpi
static constexpr int X_PLATFORM_TYPE_RPI_OLD = 10;
static constexpr int X_PLATFORM_TYPE_RPI_4 = 11;
static constexpr int X_PLATFORM_TYPE_RPI_CM4 = 12;
static constexpr int X_PLATFORM_TYPE_RPI_5 = 12;

// Numbers 20..30 are reserved for rockchip
static constexpr int X_PLATFORM_TYPE_ROCKCHIP_RK3566_RADXA_ZERO3W = 20;
static constexpr int X_PLATFORM_TYPE_ROCKCHIP_RK3588_RADXA_ROCK5_A = 21;
static constexpr int X_PLATFORM_TYPE_ROCKCHIP_RK3588_RADXA_ROCK5_B = 22;
static constexpr int X_PLATFORM_TYPE_ROCKCHIP_RV1126 = 23;
static constexpr int X_PLATFORM_TYPE_ROCKCHIP_RK3566_RADXA_CM3 = 24;
static constexpr int X_PLATFORM_TYPE_LUCKFOX_RV110X = 25;
// 26 used to be RV1103, merged into RV110X
static constexpr int X_PLATFORM_TYPE_ROCKCHIP_RV1103 = 26;
static constexpr int X_PLATFORM_TYPE_LUCKFOX_LYRA = 27;

// Legacy aliases
static constexpr int X_PLATFORM_TYPE_ROCKCHIP_RV1106 =
    X_PLATFORM_TYPE_LUCKFOX_RV110X;

// Numbers 30..35 are reserved for allwinner
static constexpr int X_PLATFORM_TYPE_ALWINNER_X20 = 30;
static constexpr int X_PLATFORM_TYPE_ALWINNER_CUBIE_A7S = 31;
static constexpr int X_PLATFORM_TYPE_ALWINNER_CUBIE_A7Z = 32;

// 36..39 reserved for openipc / sigmastar
static constexpr int X_PLATFORM_TYPE_OPENIPC_SIGMASTAR_UNDEFINED = 36;

// Numbers 40..45 are reserved for NVIDIA
static constexpr int X_PLATFORM_TYPE_NVIDIA_XAVIER = 40;

// Numbers 46..50 are reserved for QUALCOMM
static constexpr int X_PLATFORM_TYPE_QUALCOMM_QRB5165 = 46;
static constexpr int X_PLATFORM_TYPE_QUALCOMM_QCS405 = 47;

// Numbers 51..60 are reserved for enterprise
static constexpr int X_PLATFORM_TYPE_ORQA = 51;
static constexpr int X_PLATFORM_TYPE_UVX_MOD = 52;
// Legacy alias
static constexpr int X_PLATFORM_TYPE_UXV_MOD = X_PLATFORM_TYPE_UVX_MOD;

// Numbers 61..65 are reserved for NXP
static constexpr int X_PLATFORM_TYPE_NXP_IMX8 = 61;

static std::string x_platform_type_to_string(int platform_type) {
  switch (platform_type) {
    case X_PLATFORM_TYPE_UNKNOWN:
      return "UNKNOWN";
    case X_PLATFORM_TYPE_X86:
      return "X86";
    case X_PLATFORM_TYPE_RPI_OLD:
      return "RPI<=3";
    case X_PLATFORM_TYPE_RPI_4:
      return "RPI 4";
    case X_PLATFORM_TYPE_RPI_5:
      return "RPI 5";
    case X_PLATFORM_TYPE_ROCKCHIP_RK3566_RADXA_ZERO3W:
      return "RADXA ZERO3W";
    case X_PLATFORM_TYPE_ROCKCHIP_RK3566_RADXA_CM3:
      return "RADXA CM3";
    case X_PLATFORM_TYPE_ROCKCHIP_RK3588_RADXA_ROCK5_A:
      return "RADXA RK3588S";
    case X_PLATFORM_TYPE_ROCKCHIP_RK3588_RADXA_ROCK5_B:
      return "RADXA RK3588";
    case X_PLATFORM_TYPE_ROCKCHIP_RV1126:
      return "RV1126";
    case X_PLATFORM_TYPE_LUCKFOX_RV110X:
    case X_PLATFORM_TYPE_ROCKCHIP_RV1103:
      return "RV110X";
    case X_PLATFORM_TYPE_LUCKFOX_LYRA:
      return "Luckfox Lyra";
    case X_PLATFORM_TYPE_ORQA:
      return "ORQA";
    case X_PLATFORM_TYPE_UVX_MOD:
      return "UVX_MOD";
    case X_PLATFORM_TYPE_ALWINNER_X20:
      return "X20";
    case X_PLATFORM_TYPE_ALWINNER_CUBIE_A7Z:
      return "A733";
    case X_PLATFORM_TYPE_OPENIPC_SIGMASTAR_UNDEFINED:
      return "OPENIPC SIGMASTAR";
    case X_PLATFORM_TYPE_NVIDIA_XAVIER:
      return "NVIDIA_XAVIER";
    case X_PLATFORM_TYPE_QUALCOMM_QCS405:
      return "QUALCOMM_QCS405";
    case X_PLATFORM_TYPE_QUALCOMM_QRB5165:
      return "QUALCOMM_QRB5165";
    case X_PLATFORM_TYPE_NXP_IMX8:
      return "NXP_IMX8";
    default:
      break;
  }
  std::stringstream ss;
  ss << "ERR-UNDEFINED{" << platform_type << "}";
  return ss.str();
}

#endif  // PLATFORM_HPP
