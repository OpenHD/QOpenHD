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


// https://wiki.luckfox.com/Luckfox-Pico-Plus-Mini/GPIO/
var pico = [
    "GPIO1_B2", "GPIO1_B3", "GND", "GPIO1_C7", "GPIO1_C6", "GPIO1_C5", "GPIO1_C4", "GND",
    "GPIO1_D2", "GPIO1_D3", "GPIO1_A2", "GPIO1_C0", "GND", "GPIO1_C1", "GPIO1_C2", "GPIO1_C3",
    "GPIO0_A4", "GND", "GPIO1_D0", "GPIO1_D1", "GPIO4_B1", "GPIO4_B0", "GND", "GPIO4_A6",
    "GPIO4_A2", "GPIO4_A3", "GPIO4_A4", "GND", "NC", "NC", "GPIO4_C0", "GPIO4_C1",
    "GND", "NC", "NC", "3.3 V OUT", "3V3_EN", "GND", "VSYS", "VBUS"
]

var picoPlus = pico.slice(0, 20).concat([
    "GPIO3_A6", "GPIO3_A7", "GND", "GPIO3_A5", "GPIO3_A4", "GPIO3_A2", "GPIO3_A3", "GND",
    "GPIO3_A1", "NC", "GPIO4_C0", "GPIO4_C1", "GND", "NC", "NC", "3.3 V OUT",
    "3V3_EN", "GND", "VSYS", "VBUS"
])

// https://www.luckfox.com/Luckfox-Aura
var aura = [
    "3.3 V", "5 V", "GPIO0_D1", "5 V", "GPIO0_D0", "GND", "GPIO5_B4", "GPIO5_A2",
    "GND", "GPIO5_A3", "GPIO5_C2", "GPIO5_C5", "GPIO5_C3", "GND", "GPIO5_C4", "GPIO5_C6",
    "3.3 V", "GPIO5_C7", "GPIO5_D2", "GND", "GPIO5_D3", "GPIO5_B6", "GPIO5_D1", "GPIO5_D0",
    "GND", "GPIO5_B7", "GPIO5_A7", "GPIO5_A1", "GPIO5_B5", "GND", "GPIO5_B2", "GPIO5_B0",
    "GPIO5_B1", "GND", "GPIO5_A5", "GPIO5_A0", "GPIO5_B3", "GPIO5_A4", "GND", "GPIO5_A6"
]

// https://wiki.luckfox.com/Luckfox-Lyra/Pinout/
var lyra = [
    "GPIO0_C6", "GPIO0_C7", "GND", "GPIO0_B4", "GPIO0_B5", "GPIO0_A0", "GPIO0_A1", "GND",
    "GPIO0_B3", "GPIO0_B2", "GPIO0_B1", "GPIO0_B0", "GND", "GPIO0_A7", "GPIO0_A6", "GPIO0_A5",
    "GPIO0_A4", "GND", "GPIO0_A3", "GPIO0_A2", "GPIO1_D3", "GPIO1_D2", "GND", "GPIO1_D1",
    "GPIO1_C3", "GPIO1_C2", "GPIO1_B3", "GND", "GPIO1_B2", "RESET", "GPIO4_B2", "GPIO4_B3",
    "GND", "GPIO1_B1", "NC", "3.3 V OUT", "3V3_EN", "GND", "VSYS", "VBUS"
]

var lyraPlus = [
    "GPIO0_C6", "VBUS", "GPIO0_C7", "VSYS", "GND", "GND", "GPIO0_B4", "3V3_EN",
    "GPIO0_B5", "3.3 V OUT", "GPIO0_A0", "NC", "GPIO0_A1", "GPIO1_B1", "GND", "GND",
    "GPIO0_B3", "GPIO4_B3", "GPIO0_B2", "GPIO4_B2", "GPIO0_B1", "RESET", "GPIO0_B0", "GPIO1_B2",
    "GND", "GND", "GPIO0_A7", "GPIO1_B3", "GPIO0_A6", "GPIO1_C2", "GPIO0_A5", "GPIO1_C3",
    "GPIO0_A4", "GPIO1_D1", "GND", "GND", "GPIO0_A3", "GPIO1_D2", "GPIO0_A2", "GPIO1_D3"
]

var lyraZero = [
    "3.3 V OUT", "VSYS", "GPIO0_A0", "VSYS", "GPIO0_A1", "GND", "GPIO0_A2", "GPIO0_C6",
    "GND", "GPIO0_C7", "GPIO0_A3", "GPIO0_B6", "GPIO0_A4", "GND", "GPIO0_A5", "GPIO0_B5",
    "3.3 V OUT", "GPIO0_B4", "GPIO0_A6", "GND", "GPIO0_A7", "GPIO0_B3", "GPIO0_B0", "GPIO0_B2",
    "GND", "GPIO0_B1", "GPIO1_B1", "GPIO1_D3", "GPIO1_B2", "GND", "GPIO1_B3", "GPIO1_D2",
    "GPIO1_C2", "GND", "GPIO0_C0", "GPIO1_D1", "GPIO1_C3", "GPIO0_C1", "GND", "GPIO0_C2"
]

var lyraPi = [
    "3.3 V OUT", "VSYS", "GPIO0_A0", "VSYS", "GPIO0_A1", "GND", "GPIO0_A2", "GPIO0_C6",
    "GND", "GPIO0_C7", "GPIO0_A3", "GPIO0_B6", "GPIO0_A4", "GND", "GPIO0_A5", "GPIO0_B5",
    "3.3 V OUT", "GPIO0_B4", "GPIO0_A6", "GND", "GPIO0_A7", "GPIO0_B3", "GPIO0_B0", "GPIO0_B2",
    "GND", "GPIO0_B1", "GPIO1_B1", "GPIO1_D3", "GPIO1_B2", "GND", "GPIO1_B3", "GPIO1_D2",
    "GPIO1_C2", "GND", "GPIO1_A1", "GPIO1_A5", "GPIO1_A2", "GPIO1_A4", "GND", "GPIO1_A3"
]

// Available UART muxes from the board pinouts. The live device metadata
// determines which of these muxes is actually driving a Linux serial device.
var zeroUarts = [
    ["UART2 M0", 10, 8], ["UART3 M0", 3, 5], ["UART4 M1", 16, 18],
    ["UART5 M1", 33, 32], ["UART9 M1", 24, 21]
]
var piHeaderUart = [["UART on GPIO14/15", 10, 8]]
var cubieUarts = [
    ["UART0", 10, 8], ["UART0", 11, 7], ["UART2", 11, 7],
    ["UART3", 3, 5], ["UART3", 27, 28], ["UART4", 18, 16]
]
var picoUarts = [["UART2 M1", 2, 1], ["UART3 M1", 20, 19], ["UART4 M1", 7, 6]]

var uartOptionsByBoard = {
    "zero": zeroUarts, "zero-e": zeroUarts, "rock3c": zeroUarts,
    "pi2": piHeaderUart, "pi3": piHeaderUart, "pi3a": piHeaderUart,
    "pi-zero": piHeaderUart, "pi-zero-w": piHeaderUart, "pi-zero2": piHeaderUart,
    "pi4": piHeaderUart.concat([["UART2", 28, 27], ["UART3", 29, 7], ["UART4", 21, 24], ["UART5", 33, 32]]),
    "pi5": [["UART0", 10, 8], ["UART1", 28, 27], ["UART2", 29, 7], ["UART3", 21, 24], ["UART4", 33, 32]],
    "rock3-family": [["UART2 M0", 10, 8], ["UART3 M0", 3, 5], ["UART5 M1", 33, 32], ["UART9 M1", 24, 21]],
    "rock5a": [["UART2 M0", 10, 8], ["UART4 M2", 29, 7], ["UART8 M0", 40, 32]],
    "rock5b": [["UART2 M0", 10, 8], ["UART2 M2", 38, 36], ["UART3 M1", 35, 12],
               ["UART4 M2", 19, 23], ["UART7 M1", 11, 15], ["UART7 M2", 24, 26]],
    "a7z": cubieUarts, "a7s": cubieUarts,
    "aura": [["UART4 M1", 10, 8], ["UART5 M1", 35, 38], ["UART6 M0", 33, 32], ["UART7 M0", 29, 7]],
    "pico": picoUarts, "pico-plus": picoUarts.concat([["UART5 M0", 22, 21]]),
    "lyra": [["UART0", 2, 1]], "lyra-plus": [["UART0", 3, 1]],
    "lyra-zero": [["UART0", 10, 8]], "lyra-pi": [["UART0", 10, 8]]
}
uartOptionsByBoard.rock3 = uartOptionsByBoard["rock3-family"]
uartOptionsByBoard.rock3b = uartOptionsByBoard["rock3-family"]

function uartOptions(art) {
    return uartOptionsByBoard[art] || []
}

function uartName(art, rx, tx, fallback) {
    var route = uartOptions(art).find(function(option) { return option[1] === rx && option[2] === tx })
    return route ? route[0] : fallback
}

// Physical pin numbers. These are available functions, separate from live mux routes.
function pinFunction(art, pin) {
    if (art === "pi4") {
        return ({
            3: "I²C SDA", 5: "I²C SCL", 8: "UART TX", 10: "UART RX",
            12: "PCM CLK / PWM0", 19: "SPI MOSI", 21: "SPI MISO", 23: "SPI SCLK",
            24: "SPI CE0", 26: "SPI CE1", 27: "ID EEPROM SDA", 28: "ID EEPROM SCL",
            32: "PWM0", 33: "PWM1", 35: "PCM FS / PWM1", 38: "PCM DIN", 40: "PCM DOUT"
        })[pin] || ""
    }
    if (art === "a7s" || art === "a7z") {
        return ({
            3: "UART3 RX", 5: "UART3 TX", 7: "UART2 / UART0 TX",
            8: "UART0 TX", 10: "UART0 RX", 11: "UART2 / UART0 RX",
            13: "S-UART0 TX", 15: "S-UART0 RX", 16: "UART4 TX", 18: "UART4 RX",
            27: "UART3 RX", 28: "UART3 TX"
        })[pin] || ""
    }
    if (art === "pico" || art === "pico-plus") {
        return ({
            1: "UART2 TX", 2: "UART2 RX", 6: "UART4 TX", 7: "UART4 RX",
            19: "UART3 TX", 20: "UART3 RX"
        })[pin] || (art === "pico-plus" && pin === 21 ? "UART5 TX"
                   : art === "pico-plus" && pin === 22 ? "UART5 RX" : "")
    }
    if (art === "aura") {
        return ({
            7: "UART7 TX", 8: "UART4 TX", 10: "UART4 RX", 29: "UART7 RX",
            32: "UART6 TX", 33: "UART6 RX", 35: "UART5 RX", 38: "UART5 TX"
        })[pin] || ""
    }
    if (art === "lyra") return pin === 1 ? "UART0 TX" : pin === 2 ? "UART0 RX" : ""
    if (art === "lyra-plus") return pin === 1 ? "UART0 TX" : pin === 3 ? "UART0 RX" : ""
    if (art === "lyra-zero" || art === "lyra-pi")
        return pin === 8 ? "UART0 TX" : pin === 10 ? "UART0 RX" : ""
    return ""
}

function board(name, art, pins, aux) {
    return {name: name, art: art, pins: pins || [], aux: aux || [], raspberryGpio: pins === pi}
}

// Platform IDs identify an SoC family in several cases. Only select a physical
// board for a unique platform or for an identifiable device-tree model.
function profile(platform, deviceModel) {
    var model = (deviceModel || "").toLowerCase().replace(/[-_]+/g, " ")
    switch (platform) {
    case 1:
        return board(deviceModel || "PC / x86-64", "pc")
    case 10:
        if (/compute module (3|1)|\bcm3\b/.test(model))
            return board(deviceModel, "pi-cm3")
        if (model.indexOf("raspberry pi zero 2") >= 0)
            return board("Raspberry Pi Zero 2 W", "pi-zero2", pi)
        if (model.indexOf("raspberry pi zero w") >= 0)
            return board("Raspberry Pi Zero W", "pi-zero-w", pi)
        if (model.indexOf("raspberry pi zero") >= 0)
            return board("Raspberry Pi Zero", "pi-zero", pi)
        if (model.indexOf("raspberry pi 3 model a") >= 0)
            return board("Raspberry Pi 3 Model A+", "pi3a", pi)
        if (/raspberry pi 3 model b/.test(model))
            return board(deviceModel, "pi3", pi)
        if (/raspberry pi 2 model b/.test(model))
            return board(deviceModel, "pi2", pi)
        return board("Raspberry Pi 3 / earlier", "pi-family")
    case 11:
        return board("Raspberry Pi 4 Model B", "pi4", pi)
    case 12:
        if (model.indexOf("compute module 4s") >= 0)
            return board("Raspberry Pi Compute Module 4S", "pi-cm4s")
        return board("Raspberry Pi Compute Module 4", "pi-cm4")
    case 13:
        if (/compute module 5|\bcm5\b/.test(model))
            return board("Raspberry Pi Compute Module 5", "pi-cm5")
        return board("Raspberry Pi 5", "pi5", pi)
    case 20:
        if (/rock ?3[ab]/.test(model)) return profile(34, deviceModel)
        if (/rock ?3c/.test(model)) return profile(35, deviceModel)
        return /zero ?3e/.test(model) ? board("Radxa ZERO 3E", "zero-e", zero)
                                       : board("Radxa ZERO 3W", "zero", zero)
    case 21:
        return board("Radxa ROCK 5A", "rock5a", rock5a)
    case 22:
        return board(/5b(\+| plus)/.test(model) ? "Radxa ROCK 5B+" : "Radxa ROCK 5B", "rock5b", rock5b)
    case 23:
        if (model.indexOf("cm5") >= 0 || model.indexOf("compute module 5") >= 0)
            return board("Radxa CM5", "radxa-cm5")
        return board(deviceModel || "Radxa CM5 / RV1126 family", "rv1126")
    case 24:
        if (/cm3[ij]/.test(model))
            return board(deviceModel, "radxa-cm3j")
        return board("Radxa CM3", "radxa-cm3")
    case 25:
    case 26:
        if (/luckfox pico plus\b/.test(model))
            return board("Luckfox Pico Plus", "pico-plus", picoPlus)
        if (/^luckfox pico( v[0-9.]+)?$/.test(model))
            return board("Luckfox Pico", "pico", pico)
        return board(deviceModel || "Luckfox Pico / RV110X", "pico-family")
    case 27:
        if (model.indexOf("lyra ultra") >= 0)
            return board(deviceModel, "lyra-ultra")
        if (model.indexOf("lyra plus") >= 0)
            return board("Luckfox Lyra Plus", "lyra-plus", lyraPlus)
        if (model.indexOf("lyra zero") >= 0)
            return board("Luckfox Lyra Zero W", "lyra-zero", lyraZero)
        if (model.indexOf("lyra pi") >= 0)
            return board(deviceModel, "lyra-pi", lyraPi)
        if (/^luckfox lyra( b)?( v[0-9.]+)?$/.test(model))
            return board(deviceModel, "lyra", lyra)
        return board(deviceModel || "Luckfox Lyra", "lyra-family")
    case 28: return board(deviceModel || "OpenHD Core X21", "x21")
    case 29: return board(deviceModel || "Luckfox Aura", "aura", aura)
    case 30: return board(deviceModel || "OpenHD Core X20", "x20")
    case 31: return board("Radxa Cubie A7S", "a7s", a7s, a7sAux)
    case 32: return board("Radxa Cubie A7Z", "a7z", a7z)
    case 34:
        if (/rock ?3a/.test(model))
            return board("Radxa ROCK 3A", "rock3", rock3a)
        if (/rock ?3b/.test(model))
            return board("Radxa ROCK 3B", "rock3b", rock3b)
        return board("Radxa ROCK 3A / 3B", "rock3-family", rock3ab)
    case 35: return board("Radxa ROCK 3C", "rock3c", rock3c)
    case 36: return board(deviceModel || "OpenIPC SigmaStar", "sigmastar")
    case 38: return board("Radxa CM3 on OCHIN", "ochin")
    case 40:
        if (model.indexOf("xavier nx") >= 0)
            return board("NVIDIA Jetson Xavier NX", "xavier-nx")
        if (model.indexOf("agx xavier") >= 0)
            return board("NVIDIA Jetson AGX Xavier", "xavier-agx")
        return board(deviceModel || "NVIDIA Xavier", "xavier")
    case 46:
        if (model.indexOf("rb5") >= 0)
            return board(deviceModel, "rb5")
        if (model.indexOf("5165rb") >= 0)
            return board(deviceModel, "rb5-som")
        return board(deviceModel || "Qualcomm QRB5165", "qrb5165")
    case 47: return board(deviceModel || "Qualcomm QCS405", "qcs405")
    case 51: return board(deviceModel || "Orqa", "orqa")
    case 52: return board(deviceModel || "UVX Mod", "uvx")
    case 61: return board(deviceModel || "NXP i.MX8", "imx8")
    default: return board(deviceModel || qsTranslate("PortsBoardPinout", "Unknown hardware"), "unknown")
    }
}
