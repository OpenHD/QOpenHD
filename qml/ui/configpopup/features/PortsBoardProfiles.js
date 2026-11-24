.pragma library

var zero = [
        "3.3 V", "5 V", "GPIO1_A0", "5 V", "GPIO1_A1", "GND", "GPIO3_C4", "GPIO0_D1",
        "GND", "GPIO0_D0", "GPIO3_A1", "GPIO3_A3", "GPIO3_A2", "GND", "GPIO3_B0", "GPIO3_B1",
        "3.3 V", "GPIO3_B2", "GPIO4_C3", "GND", "GPIO4_C5", "GPIO3_C1", "GPIO4_C2", "GPIO4_C6",
        "GND", "NC", "GPIO4_B2", "GPIO4_B3", "GPIO3_B3", "GND", "GPIO3_B4", "GPIO3_C2",
        "GPIO3_C3", "GND", "GPIO3_A4", "GPIO3_A7", "GPIO1_A4", "GPIO3_A6", "GND", "GPIO3_A5"
]

var pi = [
        "3.3 V", "5 V", "GPIO 2", "5 V", "GPIO 3", "GND", "GPIO 4", "GPIO 14",
        "GND", "GPIO 15", "GPIO 17", "GPIO 18", "GPIO 27", "GND", "GPIO 22", "GPIO 23",
        "3.3 V", "GPIO 24", "GPIO 10", "GND", "GPIO 9", "GPIO 25", "GPIO 11", "GPIO 8",
        "GND", "GPIO 7", "GPIO 0", "GPIO 1", "GPIO 5", "GND", "GPIO 6", "GPIO 12",
        "GPIO 13", "GND", "GPIO 19", "GPIO 16", "GPIO 26", "GPIO 20", "GND", "GPIO 21"
]

// Physical numbering from the vendor hardware interface tables.
// A dash marks a pin whose documented function varies across revisions.
var rock5a = [
    "3.3 V", "5 V", "—", "5 V", "—", "GND", "GPIO1_B3", "GPIO0_B5",
    "GND", "GPIO0_B6", "—", "GPIO4_A1", "—", "GND", "GPIO4_B4", "—",
    "3.3 V", "—", "—", "GND", "—", "GPIO1_B5", "—", "—",
    "GND", "—", "—", "—", "GPIO1_B2", "GND", "GPIO1_B1", "GPIO4_B0",
    "GPIO1_B4", "GND", "GPIO4_A0", "GPIO4_A2", "—", "GPIO4_A5", "GND", "GPIO4_B1"
]

var rock5b = [
    "3.3 V", "5 V", "GPIO4_B3", "5 V", "GPIO4_B2", "GND", "GPIO3_C3", "GPIO0_B5",
    "GND", "GPIO0_B6", "GPIO3_C1", "GPIO3_B5", "GPIO3_B7", "GND", "GPIO3_C0", "GPIO3_A4",
    "3.3 V", "GPIO4_C4", "GPIO1_B2", "GND", "GPIO1_B1", "SARADC_IN4", "GPIO1_B3", "GPIO1_B4",
    "GND", "GPIO1_B5", "GPIO4_C6", "GPIO4_C5", "—", "GND", "—", "GPIO3_C2",
    "GPIO3_A7", "GND", "GPIO3_B6", "GPIO3_B1", "GPIO0_A0", "GPIO3_B2", "GND", "GPIO3_B3"
]

var rock3a = [
    "3.3 V", "5 V", "GPIO1_A0", "5 V", "GPIO1_A1", "GND", "—", "GPIO0_D1",
    "GND", "GPIO0_D0", "GPIO3_C4", "GPIO3_A3", "GPIO3_C5", "GND", "GPIO0_C0", "—",
    "—", "GPIO3_B2", "GPIO4_C3", "GND", "GPIO4_C5", "—", "GPIO4_C2", "GPIO4_C6",
    "GND", "GPIO4_D1", "—", "—", "GPIO2_D7", "GND", "GPIO3_A0", "GPIO3_C2",
    "GPIO3_C3", "GND", "GPIO3_A4", "GPIO3_A2", "—", "GPIO3_A6", "GND", "GPIO3_A5"
]

var rock3b = [
    "3.3 V", "5 V", "GPIO1_A0", "5 V", "GPIO1_A1", "GND", "GPIO0_B5", "GPIO0_D1",
    "GND", "GPIO0_D0", "GPIO3_C4", "GPIO3_A3", "—", "GND", "GPIO0_C0", "GPIO0_B6",
    "3.3 V", "GPIO3_B2", "GPIO4_C3", "GND", "GPIO4_C5", "GPIO0_C1", "GPIO4_C2", "GPIO4_C6",
    "GND", "GPIO4_D1", "GPIO0_B4", "GPIO0_B3", "GPIO2_D7", "GND", "GPIO3_A0", "GPIO3_C2",
    "GPIO3_C3", "GND", "GPIO3_A4", "GPIO3_A2", "SARADC_VIN5", "GPIO3_A6", "GND", "GPIO3_A5"
]

var rock3ab = [
    "3.3 V", "5 V", "GPIO1_A0", "5 V", "GPIO1_A1", "GND", "—", "GPIO0_D1",
    "GND", "GPIO0_D0", "GPIO3_C4", "GPIO3_A3", "—", "GND", "GPIO0_C0", "—",
    "—", "GPIO3_B2", "GPIO4_C3", "GND", "GPIO4_C5", "—", "GPIO4_C2", "GPIO4_C6",
    "GND", "GPIO4_D1", "—", "—", "GPIO2_D7", "GND", "GPIO3_A0", "GPIO3_C2",
    "GPIO3_C3", "GND", "GPIO3_A4", "GPIO3_A2", "—", "GPIO3_A6", "GND", "GPIO3_A5"
]

var rock3c = [
    "3.3 V", "5 V", "GPIO1_A0", "5 V", "GPIO1_A1", "GND", "GPIO3_C4", "GPIO0_D1",
    "GND", "GPIO0_D0", "GPIO3_A1", "GPIO3_A3", "GPIO3_A2", "GND", "GPIO3_B0", "GPIO3_B1",
    "3.3 V", "GPIO3_B2", "GPIO4_C3", "GND", "GPIO4_C5", "GPIO3_C1", "GPIO4_C2", "GPIO4_C6",
    "GND", "GPIO4_D1", "GPIO4_B2", "GPIO4_B3", "GPIO3_B3", "GND", "GPIO3_B4", "GPIO3_C2",
    "GPIO3_C3", "GND", "GPIO3_A4", "GPIO3_A7", "GPIO1_A4", "GPIO3_A6", "GND", "GPIO3_A5"
]

var a7z = [
    "3.3 V", "5 V", "PJ23", "5 V", "PJ22", "GND", "PB0", "PB9",
    "GND", "PB10", "PB1", "PB5", "PL6", "GND", "PL7", "PJ24",
    "3.3 V", "PJ25", "PD12", "GND", "PD13", "PL5", "PD11", "PD10",
    "GND", "PD14", "PD17", "PD16", "PB2", "GND", "PB3", "PM5",
    "PM3", "GND", "PB6", "PB4", "PM4", "PB8", "GND", "PB7"
]

var a7s = [
    "3.3 V", "5 V", "PJ23", "5 V", "PJ22", "GND", "PB0", "PB9",
    "GND", "PB10", "PB1", "PB5", "PL6", "GND", "PL7", "PJ24",
    "3.3 V", "PJ25", "PD12", "GND", "PD13", "PL5", "PD11", "PD10",
    "GND", "PD14", "PD17", "PD16", "PB2", "GND"
]

var a7sAux = [
    "PB3", "PM3", "PM4", "GND", "PB6", "PB4", "PB8", "PB7",
    "GND", "PG0", "PG1", "PG2", "PG3", "PG4", "PG5"
]


function board(name, chip, brand, art, pins, aux) {
    return {name: name, chip: chip, brand: brand, art: art, pins: pins || [], aux: aux || []}
}

// IDs follow openhd_platform.h. Some identify a family or compute module;
// the device-tree model can disambiguate the physical board in these cases.
function profile(platform, deviceModel) {
    var model = (deviceModel || "").toLowerCase()
    switch (platform) {
    case 1: return board("PC / x86-64", "x86-64", "", "pc")
    case 10:
        if (model.indexOf("raspberry pi zero 2") >= 0)
            return board("Raspberry Pi Zero 2 W", "RP3A0", "BROADCOM", "pi-zero", pi)
        if (model.indexOf("raspberry pi zero") >= 0)
            return board("Raspberry Pi Zero", "BCM2835", "BROADCOM", "pi-zero", pi)
        if (/raspberry pi [23] model/.test(model))
            return board(deviceModel, model.indexOf("raspberry pi 2") >= 0 ? "BROADCOM" : "BCM2837",
                         "", "pi3", pi)
        return board("Raspberry Pi 3 / earlier", "", "BROADCOM", "module")
    case 11: return board("Raspberry Pi 4 Model B", "BCM2711", "BROADCOM", "pi4", pi)
    case 12: return board("Raspberry Pi Compute Module 4", "BCM2711", "BROADCOM", "module")
    case 13:
        if (/compute module 5|\bcm5\b/.test(model))
            return board("Raspberry Pi Compute Module 5", "BCM2712", "BROADCOM", "module")
        return board("Raspberry Pi 5", "BCM2712", "BROADCOM", "pi5", pi)
    case 20:
        if (/rock[- ]?3[ab]/.test(model)) return profile(34, deviceModel)
        if (/rock[- ]?3c/.test(model)) return profile(35, deviceModel)
        if (model.indexOf("zero 3e") >= 0)
            return board("Radxa ZERO 3E", "RK3566", "ROCKCHIP", "zero", zero)
        return board("Radxa ZERO 3W", "RK3566", "ROCKCHIP", "zero", zero)
    case 21: return board("Radxa ROCK 5A", "RK3588S", "ROCKCHIP", "rock5a", rock5a)
    case 22: return board("Radxa ROCK 5B", "RK3588", "ROCKCHIP", "rock5b", rock5b)
    case 23:
        if (model && model.indexOf("cm5") < 0)
            return board(deviceModel, "RV1126", "ROCKCHIP", "module")
        return board("Radxa CM5 / RV1126 family", "", "ROCKCHIP", "module")
    case 24: return board("Radxa CM3", "RK3566", "ROCKCHIP", "module")
    case 25:
    case 26: return board(deviceModel || "Luckfox Pico / RV110X", "RV110X", "ROCKCHIP", "pico")
    case 27: return board("Luckfox Lyra", "RK3506", "ROCKCHIP", "pico")
    case 28: return board("OpenHD Core X21", "X21", "OPENHD", "openhd")
    case 29: return board("Luckfox Aura", "RV1126B", "ROCKCHIP", "pico")
    case 30: return board("OpenHD Core X20", "X20", "OPENHD", "openhd")
    case 31: return board("Radxa Cubie A7S", "A733", "ALLWINNER", "a7s", a7s, a7sAux)
    case 32: return board("Radxa Cubie A7Z", "A733", "ALLWINNER", "a7z", a7z)
    case 34:
        if (model.indexOf("rock 3a") >= 0 || model.indexOf("rock3a") >= 0)
            return board("Radxa ROCK 3A", "RK3568", "ROCKCHIP", "rock3", rock3a)
        if (model.indexOf("rock 3b") >= 0 || model.indexOf("rock3b") >= 0)
            return board("Radxa ROCK 3B", "RK3568", "ROCKCHIP", "rock3", rock3b)
        return board("Radxa ROCK 3A / 3B", "RK3568", "ROCKCHIP", "rock3", rock3ab)
    case 35: return board("Radxa ROCK 3C", "RK3566", "ROCKCHIP", "rock3c", rock3c)
    case 36: return board("OpenIPC SigmaStar", "", "SIGMASTAR", "module")
    case 38: return board("Radxa CM3 on OCHIN", "RK3566", "ROCKCHIP", "carrier")
    case 40: return board("NVIDIA Xavier", "XAVIER", "NVIDIA", "module")
    case 46: return board("Qualcomm QRB5165", "QRB5165", "QUALCOMM", "module")
    case 47: return board("Qualcomm QCS405", "QCS405", "QUALCOMM", "module")
    case 51: return board("Orqa", "", "ORQA", "module")
    case 52: return board("UVX Mod", "", "UVX", "module")
    case 61: return board("NXP i.MX8", "i.MX8", "NXP", "module")
    default: return board(deviceModel || qsTranslate("PortsBoardPinout", "Unknown hardware"), "", "", "module")
    }
}
