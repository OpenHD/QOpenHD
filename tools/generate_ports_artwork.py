"""Generate the Ports board illustrations and their QML geometry.

Run with Python and Pillow. Shapes are original drawings based on the linked
mechanical drawings and board views. All physical outlines and pin spacing are
in millimetres. Output includes transparent padding for overhanging sockets.
"""

from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path
import json
import math
import re

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
FEATURES = ROOT / "qml/ui/configpopup/features"
ART = FEATURES / "artwork"
SCALE = 16
OUTPUT_SCALE = 10
HEADER_PITCH = 2.54
INK = "#091721"
GOLD = "#e6b860"
PALETTES = {
    "pi": ("#40814f", "#275c41", "#93b67a", "#68a271", "#47785a"),
    "radxa": ("#22765f", "#15473c", "#65b499", "#4a8f70", "#29664f"),
    "luckfox": ("#353744", "#20242e", "#7d8291", "#555c6d", "#3a4356"),
    "openhd": ("#243f51", "#162939", "#6a9db1", "#3c6178", "#304f63"),
    "module": ("#334a55", "#213240", "#6a8798", "#526d80", "#3b5866"),
    "ochin": ("#735039", "#422b25", "#ab8469", "#895c45", "#684633"),
}


@dataclass(frozen=True)
class Header:
    x: float
    y: float
    rows: int
    pitch: float = HEADER_PITCH
    columns: int = 2
    column_gap: float = HEADER_PITCH
    order: str = "odd-left"

    def points(self):
        for row in range(self.rows):
            for column in range(self.columns):
                yield self.x + column * self.column_gap, self.y + row * self.pitch


@dataclass(frozen=True)
class Part:
    kind: str
    x: float
    y: float
    w: float
    h: float
    name: str = ""
    sub: str = ""

    def bounds(self):
        return self.x, self.y, self.x + self.w, self.y + self.h


@dataclass(frozen=True)
class Board:
    width: float
    height: float
    palette: str
    parts: tuple[Part, ...]
    holes: tuple[tuple[float, float], ...] = ()
    header: Header | None = None
    aux: Header | None = None
    outline: str = "pcb"
    radius: float = 2.0

    def bounds(self):
        bounds = [part.bounds() for part in self.parts]
        # Strokes and drop shadows are included even where ports extend off the PCB.
        return (
            math.floor(min([0] + [b[0] for b in bounds]) - 2),
            math.floor(min([0] + [b[1] for b in bounds]) - 2),
            math.ceil(max([self.width] + [b[2] for b in bounds]) + 3),
            math.ceil(max([self.height] + [b[3] for b in bounds]) + 3),
        )


def mount_holes(width, height, inset=3.5, bottom=None):
    bottom = height - inset if bottom is None else bottom
    return ((inset, inset), (width - inset, inset), (inset, bottom), (width - inset, bottom))


def pi_b(model):
    # https://www.raspberrypi.com/documentation/computers/sbcs.html
    # Pi 4 mechanical drawing RP-008341, rotated to read the header top-to-bottom.
    pi4 = model == 4
    pi5 = model == 5
    usb = (
        Part("usb2", 4, 67, 14, 20),
        Part("usb3", 21, 67, 14, 20),
        Part("ethernet", 39, 66, 15.5, 22),
    ) if pi4 else (
        Part("ethernet", 3, 66, 15.5, 22),
        Part("usb3" if pi5 else "usb2", 22, 67, 14, 20),
        Part("usb2", 40, 67, 14, 20),
    )
    small_io = (
        Part("usb-c" if model >= 4 else "power", -1.5, 8, 10, 8.5),
        Part("hdmi", -1.5, 21, 9, 8 if model >= 4 else 13),
    )
    if model >= 4:
        small_io += (Part("hdmi", -1.5, 32, 9, 8),)
    if not pi5:
        small_io += (Part("audio", -1.2, 48.6, 10.7, 9),)
    parts = (
        Part("soc", 23, 22, 16, 16, {2: "BCM2836", 3: "BCM2837", 4: "BCM2711", 5: "BCM2712"}[model],
             "BROADCOM"),
        Part("chip", 24, 41, 14, 9, "LPDDR4X" if pi5 else "LPDDR4" if pi4 else "RAM"),
        Part("chip", 13.2, 53.5, 10, 9, "RP1" if pi5 else "VL805" if pi4 else "USB"),
        Part("chip", 27, 56, 8, 7, "LAN"),
    )
    if model >= 3:
        parts += (Part("shield", 38, 6, 9, 10, "Wi-Fi"),)
    if pi5:
        parts += (Part("ribbon", 4, 43, 12, 2.3), Part("ribbon", 4, 47.5, 12, 2.3),
                  Part("socket", 17, 4, 7, 2.5, "FAN"))
    else:
        parts += (Part("ribbon", 16, 3.0, 18.5, 2.5), Part("ribbon", 4, 43, 15, 2.5))
    return Board(56, 85, "pi", parts + small_io + usb, mount_holes(56, 85, bottom=61.5),
                 Header(50.16, 7.6, 20), radius=3)


def pi_zero(wireless, zero2=False):
    # https://www.raspberrypi.com/documentation/computers/zero.html
    parts = (
        Part("soc", 9, 22, 11, 11, "RP3A0" if zero2 else "BCM2835", "BROADCOM"),
        Part("ribbon", 7, 3, 13, 2.6),
        Part("power", -1.1, 14, 8, 7),
        Part("power", -1.1, 25, 8, 7),
        Part("hdmi", -1.4, 45, 9, 11),
        Part("sd", 8, 56, 13, 8),
    )
    if wireless:
        parts += (Part("shield", 10, 38, 10, 7, "Wi-Fi"),)
    return Board(30, 65, "pi", parts, mount_holes(30, 65), Header(23.95, 8.4, 20))


def rock3(compact=False, carrier_b=False):
    # https://docs.radxa.com/en/rock3/rock3a/download
    # https://docs.radxa.com/en/rock3/rock3b/getting-started/introduction
    # https://docs.radxa.com/en/rock3/rock3c/hardware-design/hardware-interface
    if carrier_b:
        return Board(75, 100, "radxa", (
            Part("soc", 27, 26, 19, 19, "RK3568", "ROCKCHIP"),
            Part("chip", 44, 58.5, 14, 9, "LPDDR4"),
            Part("ribbon", 14, 6, 19, 2.8),
            Part("socket", 46, 67, 18, 4, "M.2"),
            Part("audio", -1, 4, 10, 9),
            Part("usb-c", -1, 14.5, 10, 7.5),
            Part("hdmi", -1.5, 24, 13, 9),
            Part("usb2", -1.8, 35, 20, 13),
            Part("usb3", -1.8, 52.5, 20, 13),
            Part("ethernet", -1.8, 70, 23, 13),
            Part("ethernet", -1.8, 85, 23, 13),
        ), mount_holes(75, 100, 4, 63), Header(67.7, 8.3, 20))
    radio = (Part("shield", 33, 9, 11, 10, "Wi-Fi"),) if compact else ()
    return Board(56, 85, "radxa", (
        Part("soc", 24, 24, 17, 17, "RK3566" if compact else "RK3568", "ROCKCHIP"),
        Part("chip", 24, 44, 15, 9, "LPDDR4"),
        Part("ribbon", 10, 14, 17, 2.7),
        Part("usb-c", -1, 13, 9, 9),
        Part("hdmi", -1.3, 36, 12, 14),
        Part("audio", -1, 55, 10, 9),
        Part("ethernet", 3.5, 65, 16, 21),
        Part("usb3", 22, 66, 14, 20),
        Part("usb2", 39, 66, 14, 20),
    ) + radio, mount_holes(56, 85, 3.5, 61.5), Header(49.9, 8.0, 20))


def rock5(model_b):
    # https://docs.radxa.com/en/rock5/rock5a/hardware-design/hardware-interface
    # https://docs.radxa.com/en/rock5/rock5b/hardware-design/hardware-interface
    if model_b:
        return Board(75, 100, "radxa", (
            Part("soc", 24, 23, 20.5, 20.5, "RK3588", "ROCKCHIP"),
            Part("chip", 48, 23, 14, 10, "LPDDR4X"),
            Part("chip", 38, 8, 14, 10, "LPDDR4X"),
            Part("hdmi", 65, 64, 11, 8.5),
            Part("audio", -1, 3, 10, 7.5),
            Part("usb-c", -1, 11.6, 10, 7.8),
            Part("hdmi", -1.6, 21, 12, 9.5),
            Part("hdmi", -1.6, 34, 12, 9.5),
            Part("socket", 55, 77, 5, 16, "M.2"),
            Part("usb2", -1.8, 47, 17, 13),
            Part("usb3", -1.8, 64, 17, 13),
            Part("ethernet", -1.8, 81, 21.5, 16),
        ), mount_holes(75, 100, 3.7) + ((20.4, 61.7), (71.3, 61.7)),
                     Header(67.9, 8, 20))
    return Board(56, 85, "radxa", (
        Part("soc", 21, 27, 16, 16, "RK3588S", "ROCKCHIP"),
        Part("chip", 33, 47, 13, 9, "LPDDR4X"),
        Part("chip", 18, 47, 12, 9, "LPDDR4X"),
        Part("ribbon", 18, 5, 17, 2.6),
        Part("usb-c", -1, 8, 10, 8.5),
        Part("hdmi", -1.4, 21, 11.4, 8),
        Part("hdmi", -1.4, 34, 11.4, 8),
        Part("audio", -1, 48, 10, 9),
        Part("usb2", 2.5, 66, 14, 21),
        Part("usb3", 20.0, 66, 14, 21),
        Part("ethernet", 38, 65, 16.5, 22),
    ), mount_holes(56, 85, 3.5, 62), Header(49.9, 7.7, 20))


def radxa_zero_3w():
    # Top-side mechanical view, with the CON1 pin-1 triangle at the HDMI end.
    # https://dl.radxa.com/zero3/docs/hw/3w/radxa_zero_3w_product_brief.pdf
    return Board(30, 65, "radxa", (
        Part("shield", 8.9, 7.0, 10.5, 9.5, "Wi-Fi"),
        Part("soc", 7.0, 20.0, 12.3, 12.5, "RK3566", "ROCKCHIP"),
        Part("chip", 7.7, 37.0, 10.3, 8.5, "LPDDR4"),
        Part("chip", 9.9, 49.6, 8.5, 7.0, "PMIC"),
        Part("hdmi", -1.0, 8.75, 8.0, 7.5),
        Part("usb-c", -1.2, 37.5, 8.5, 8.1),
        Part("usb-c", -1.2, 50.65, 8.5, 8.1),
    ), mount_holes(30, 65, 3.6), Header(25.4, 8.32, 20))


def radxa_zero_3e():
    return Board(30, 65, "radxa", (
        Part("chip", 11.6, 8.4, 8.5, 7.0, "PMIC"),
        Part("chip", 11.0, 20, 10.3, 8.5, "LPDDR4"),
        Part("soc", 10.7, 32.5, 12.3, 12.5, "RK3566", "ROCKCHIP"),
        Part("ethernet", 16.2, 47.4, 14.6, 12.2),
        Part("usb-c", 22.7, 9.6, 8.5, 8.1),
        Part("usb-c", 22.7, 21.4, 8.5, 8.1),
        Part("hdmi", 23.3, 35.6, 8.0, 7.5),
    ), mount_holes(30, 65, 3), Header(2.9, 8.5, 20))


def pico(height, chip, ethernet=False, header=None):
    # https://wiki.luckfox.com/Luckfox-Pico-RV1106/Downloads/
    # https://www.luckfox.com/Luckfox-Lyra and /Luckfox-Lyra-Plus
    parts = (
        Part("usb-c", 6.4, -1.0, 8.2, 6.5),
        Part("ribbon", 4.3, 14, 12.4, 2.6),
        Part("soc", 5.3, 22, 10.4, 10, chip, "ROCKCHIP"),
        Part("chip", 6, 37, 9, 7, "RAM"),
    )
    if ethernet:
        parts += (Part("ethernet", 2.8, height - 19, 15.4, 20),)
    return Board(21, height, "luckfox", parts, header=header, radius=1.2)


def module(chip, label, palette, width=55, height=40, edge=False):
    parts = (
        Part("soc", width * 0.31, height * 0.30, width * 0.29, height * 0.40, chip, label),
        Part("chip", width * 0.67, height * 0.24, width * 0.22, height * 0.19, "RAM"),
        Part("chip", width * 0.67, height * 0.54, width * 0.22, height * 0.19, "eMMC"),
        Part("chip", width * 0.14, height * 0.35, width * 0.11, height * 0.20, "PMIC"),
    )
    if edge:
        parts += (Part("edge", width * 0.10, height - 3, width * 0.80, 3.1),)
    return Board(width, height, palette, parts, mount_holes(width, height, 3.4) if not edge else (),
                 radius=1.1)


def family(chip, brand, palette="module"):
    return Board(44, 35, palette, (Part("soc", 5, 5, 34, 25, chip, brand),), outline="family")


# The identifiers here describe physical variants, not OpenHD's platform IDs.
# Families without an identified board get a chip or host illustration without dimensions.
BOARDS = {
    "pi2": pi_b(2),
    "pi3": pi_b(3),
    "pi3a": Board(56, 65, "pi", (
        Part("soc", 23, 23, 16, 16, "BCM2837B0", "BROADCOM"),
        Part("shield", 32, 42, 13, 8, "Wi-Fi"),
        Part("power", -1, 8, 9, 8), Part("hdmi", -1, 23, 11, 13),
        Part("audio", -1, 42, 10, 8), Part("usb2", 29, 52, 15, 14),
        Part("ribbon", 13, 5, 18, 2.5),
    ), mount_holes(56, 65, 3.5, 61.5), Header(49.9, 8.0, 20)),
    "pi4": pi_b(4),
    "pi5": pi_b(5),
    "pi-zero": pi_zero(False),
    "pi-zero-w": pi_zero(True),
    "pi-zero2": pi_zero(True, True),
    "pi-cm3": module("BCM2837", "BROADCOM", "pi", 67.6, 30, True),
    "pi-cm4": module("BCM2711", "BROADCOM", "pi"),
    "pi-cm4s": module("BCM2711", "BROADCOM", "pi", 67.6, 30, True),
    "pi-cm5": module("BCM2712", "BROADCOM", "pi"),
    "zero": radxa_zero_3w(),
    "zero-e": radxa_zero_3e(),
    "rock3": rock3(),
    "rock3b": rock3(carrier_b=True),
    "rock3c": rock3(compact=True),
    "rock5a": rock5(False),
    "rock5b": rock5(True),
    "radxa-cm3": module("RK3566", "ROCKCHIP", "radxa", 55, 40.1),
    "radxa-cm3j": module("RK3568J", "ROCKCHIP", "radxa"),
    "radxa-cm5": module("RK3588S", "ROCKCHIP", "radxa"),
    # https://docs.radxa.com/en/cubie/a7z/hardware-use/pin-gpio
    "a7z": Board(30, 65, "radxa", (
        Part("soc", 6, 21, 13.3, 13.3, "A733", "ALLWINNER"),
        Part("chip", 7.7, 38, 13.0, 9.5, "LPDDR4X"),
        Part("chip", 8.4, 51.2, 10, 9.2, "AXP318W"),
        Part("shield", 9.3, 7.5, 12.0, 10.3, "Wi-Fi"),
        Part("hdmi", -1.4, 10, 8, 8),
        Part("usb-c", -1.4, 38.3, 9, 8),
        Part("usb-c", -1.4, 50.5, 9, 8),
    ), mount_holes(30, 65, 3), Header(23.8, 8.5, 20)),
    # https://docs.radxa.com/en/cubie/a7s/hardware-use/hardware-info
    "a7s": Board(51, 51, "radxa", (
        Part("soc", 17, 24, 11, 11, "A733", "ALLWINNER"),
        Part("chip", 31, 17, 11, 11, "eMMC"),
        Part("shield", 7, 35.5, 11, 10.2, "Wi-Fi"),
        Part("ribbon", 24, 46.5, 15, 2.3),
        Part("ethernet", 6, -1.3, 14.8, 15.4),
        Part("usb2", 23, -1.2, 8, 10),
        Part("usb-c", 32.4, -1.2, 5.8, 7),
        Part("usb-c", 39.4, -1.2, 5.6, 7),
    ), mount_holes(51, 51, 3.2), Header(46.2, 7.4, 15),
                 Header(1.9, 7.4, 15, HEADER_PITCH, 1)),
    "pico": pico(51, "RV1103", header=Header(1.61, 1.37, 20, column_gap=17.78, order="around")),
    "pico-plus": pico(72, "RV1103", True, Header(1.61, 1.37, 20, column_gap=17.78, order="around")),
    "lyra": pico(51, "RK3506", header=Header(1.61, 1.57, 20, column_gap=17.78, order="around")),
    "lyra-plus": pico(72, "RK3506G2", True, Header(1.61, 1.57, 20, column_gap=17.78)),
    "lyra-ultra": Board(50, 50, "luckfox", (
        Part("usb-c", 21, -1.1, 8.2, 6.3),
        Part("soc", 27, 11, 13.2, 13.3, "RK3506B", "ROCKCHIP"),
        Part("chip", 9, 11, 12, 10, "eMMC"),
        Part("ribbon", 8, 27, 13.5, 2.6),
        Part("ethernet", 6, 32, 16, 19.5),
        Part("usb2", 25, 37, 8.5, 14),
        Part("shield", 33, 33, 10.3, 10.3, "Wi-Fi"),
    ), mount_holes(50, 50, 2.5)),
    "lyra-zero": Board(30, 65, "luckfox", (
        Part("usb-c", -1, 12, 7.8, 8.2), Part("usb-c", -1, 26, 7.8, 8.2),
        Part("soc", 9, 23, 13.3, 12.4, "RK3506B", "ROCKCHIP"),
        Part("shield", 11, 39, 10.5, 9.8, "Wi-Fi"),
        Part("ribbon", 8.6, 8, 13.7, 2.5),
        Part("sd", 7, 53, 14, 8),
    ), mount_holes(30, 65, 3.5), Header(23.9, 8.2, 20)),
    "lyra-pi": Board(56, 85, "luckfox", (
        Part("soc", 21, 21, 15, 15, "RK3506B", "ROCKCHIP"),
        Part("shield", 8, 13, 10, 10, "Wi-Fi"),
        Part("chip", 21, 40, 12, 9, "RAM"),
        Part("ethernet", 4, 65, 15, 21), Part("ethernet", 22, 65, 15, 21),
        Part("usb2", 40, 66, 13, 20), Part("usb-c", -1, 11, 9, 8),
    ), mount_holes(56, 85, 3.5, 61.5), Header(50.0, 7.6, 20)),
    # https://ochin.cloud/files/chnCM4v2-Manual.pdf
    "ochin": Board(55, 40, "ochin", (
        Part("soc", 17, 10, 14.5, 13, "RK3566", "ROCKCHIP"),
        Part("chip", 34, 13, 10.5, 8, "RAM"), Part("ribbon", 15, 3.8, 20, 2.6),
        Part("socket", 10, 33.5, 13, 5, "UART"),
        Part("usb-c", 45, 19, 11, 7.5), Part("socket", 31.4, 33.5, 12, 5, "I/O"),
    ), mount_holes(55, 40, 3.5)),
    # https://www.nvidia.com/en-au/autonomous-machines/embedded-systems/jetson-xavier-nx/
    "xavier-nx": module("XAVIER NX", "NVIDIA", "module", 69.6, 45, True),
    "xavier-agx": module("AGX XAVIER", "NVIDIA", "module", 100, 87),
    "rb5": Board(85, 54, "module", (
        Part("soc", 27, 14, 28, 23, "QRB5165", "QUALCOMM"),
        Part("chip", 60, 17, 12, 12, "RAM"),
        Part("ribbon", 22, 3, 24, 3), Part("ribbon", 21, 45, 18, 3),
        Part("usb-c", 74, 24, 12, 8), Part("usb3", 72, 37, 14, 13),
        Part("socket", 5, 8, 4, 28),
    ), mount_holes(85, 54)),
    "rb5-som": module("QRB5165", "QUALCOMM", "module", 50, 29),
    "pc": Board(57, 34, "module", (
        Part("soc", 14, 7, 29, 20, "x86-64", "PC"),
        Part("usb3", 46, 9, 10, 16), Part("usb2", 1, 9, 10, 16),
    ), outline="host"),
    "pi-family": family("RASPBERRY PI", "BROADCOM", "pi"),
    "rock3-family": Board(34, 57, "radxa", (
        Part("soc", 0, 19, 22, 18, "RK3568", "RADXA"),
    ), header=Header(26.5, 3.5, 20), outline="family"),
    "rv1126": family("RV1126", "ROCKCHIP", "radxa"),
    "pico-family": family("RV110X", "LUCKFOX", "luckfox"),
    "lyra-family": family("RK3506", "LUCKFOX LYRA", "luckfox"),
    # https://www.luckfox.com/Luckfox-Aura
    "aura": Board(56, 85, "luckfox", (
        Part("soc", 21, 28, 16, 15, "RV1126B", "ROCKCHIP"),
        Part("chip", 20, 14, 12, 9.5, "eMMC"),
        Part("shield", 36, 8, 11, 9, "Wi-Fi"),
        Part("chip", 24, 49, 13, 9, "LPDDR4X"),
        Part("ribbon", 4, 48.8, 15, 2.6), Part("ribbon", 4, 55, 15, 2.6),
        Part("ribbon", 18, 2.5, 17.5, 2.6),
        Part("usb-c", -1.2, 9, 9.3, 8.1), Part("usb-c", -1, 23.4, 9.3, 8.1),
        Part("audio", -1, 35.4, 10.3, 8.9),
        Part("ethernet", 2.5, 66, 17, 21),
        Part("usb2", 22.0, 67, 14.5, 20), Part("usb2", 39.5, 67, 14.5, 20),
    ), mount_holes(56, 85, 3.5, 61.5), Header(50.0, 7.6, 20)),
    "x20": family("X20", "OPENHD", "openhd"),
    "x21": family("X21", "OPENHD", "openhd"),
    "sigmastar": family("SIGMASTAR", "OPENIPC"),
    "xavier": family("XAVIER", "NVIDIA"),
    "qrb5165": family("QRB5165", "QUALCOMM"),
    "qcs405": family("QCS405", "QUALCOMM"),
    "orqa": family("ORQA", "HARDWARE"),
    "uvx": family("UVX MOD", "HARDWARE"),
    "imx8": family("i.MX8", "NXP"),
    "unknown": family("OPENHD", ""),
}


class Drawing:
    def __init__(self, board):
        self.board = board
        self.left, self.top, self.right, self.bottom = board.bounds()
        self.w = self.right - self.left
        self.h = self.bottom - self.top
        self.image = Image.new("RGBA", (self.w * SCALE, self.h * SCALE))
        self.d = ImageDraw.Draw(self.image)

    def point(self, x, y):
        return round((x - self.left) * SCALE), round((y - self.top) * SCALE)

    def area(self, x, y, w, h):
        return (*self.point(x, y), *self.point(x + w, y + h))

    def round(self, x, y, w, h, fill, edge=None, radius=.65, weight=.35):
        self.d.rounded_rectangle(self.area(x, y, w, h), radius=round(radius*SCALE),
                                 fill=fill, outline=edge, width=max(1, round(weight*SCALE)))

    def ellipse(self, x, y, r, fill, edge=None, weight=.26):
        self.d.ellipse(self.area(x-r, y-r, 2*r, 2*r), fill=fill, outline=edge,
                       width=max(1, round(weight*SCALE)))

    def line(self, points, color, width=.22):
        self.d.line([self.point(*point) for point in points], fill=color,
                    width=max(1, round(width*SCALE)), joint="curve")

    @staticmethod
    @lru_cache
    def font(px):
        return ImageFont.truetype(ROOT / "qml/osdfonts/Archivo-Bold.ttf", px)

    def label(self, name, x, y, w, max_height, color):
        if not name:
            return
        size = round(max_height*SCALE)
        while size > 6 and self.d.textlength(name, font=self.font(size)) > w * SCALE:
            size -= 1
        self.d.text(self.point(x, y), name, fill=color, font=self.font(size), anchor="mm")

    def tracks(self, start, end):
        w, h = self.board.width, self.board.height
        if self.board.outline != "pcb":
            return
        for index in range(9):
            x = w * (.16 + index % 3 * .055)
            y = h * (.18 + index * .074)
            self.line(((x, y), (x+w*.09, y), (x+w*.15, y+h*.04), (w*.79, y+h*.04)),
                      start if index % 3 == 0 else end, .16)
            self.ellipse(x, y, .26, "#c7ad6d", end)

    def pcb(self):
        w, h = self.board.width, self.board.height
        front, shade, light, trace, via = PALETTES[self.board.palette]
        if self.board.outline == "family":
            return
        self.round(.7, .95, w, h, "#0b1722", radius=self.board.radius+.2)
        self.round(0, 0, w, h, shade, INK, self.board.radius, .52)
        self.round(.4, .35, w-.8, h-.78, front, radius=max(.4, self.board.radius-.2))
        self.line(((1, h-3), (1, 2), (2, 1), (w-2, 1)), light, .30)
        self.line(((w-1, 3), (w-1, h-2), (w-2, h-1), (3, h-1)), via, .34)
        self.tracks(trace, via)
        for x, y in self.board.holes:
            self.ellipse(x, y, 2.02, "#bf8c43", INK, .34)
            self.ellipse(x, y, 1.75, "#e7c375", "#9e713e", .25)
            self.ellipse(x, y, 1.20, "#10232a", "#6a5b40", .27)

    def chip(self, part, metal=False):
        x, y, w, h = part.x, part.y, part.w, part.h
        for index in range(7):
            px = x + w * (.11 + .13 * index)
            self.line(((px,y-.64),(px,y+.25)), "#a6aca3", .25)
            self.line(((px,y+h-.25),(px,y+h+.64)), "#a6aca3", .25)
        self.round(x+.48, y+.55, w, h, "#111f29", radius=.62)
        self.round(x, y, w, h, "#708393" if metal else "#293c48", INK, .67, .46)
        self.round(x+.46, y+.46, w-.95, h-.91, "#a9b9c1" if metal else "#3b5360", radius=.37)
        self.round(x+.69, y+1.0, w-1.37, h-1.64, "#91a7b3" if metal else "#304654", radius=.27)
        self.line(((x+.72,y+h-.85),(x+.72,y+.83),(x+w-.97,y+.83)),
                  "#d0d8d7" if metal else "#6b858d", .24)
        self.ellipse(x+1.42, y+1.64, .36, "#536775", INK, .15)
        if part.sub:
            self.label(part.sub, x+w/2, y+h*.38, w-2.4, min(h*.18, 2.0),
                       "#213743" if metal else "#b8cbd3")
        self.label(part.name, x+w/2, y+h*(.64 if part.sub else .53), w-2.12,
                   min(h*.27, 4.2), "#0c2634" if metal else "#eef4ef")

    def ribbon(self, part):
        x, y, w, h = part.x, part.y, part.w, part.h
        self.round(x, y, w, h, "#202e32", INK, .45, .29)
        self.round(x+.42, y+.26, w-.84, h*.30, "#66746e", radius=.15)
        self.round(x+.38, y+h*.42, w-.76, h*.34, "#101e23", radius=.14)
        for index in range(int((w-1.3)/.54)):
            px = x+.68+index*.54
            self.line(((px,y+h*.54),(px,y+h*.83)), "#c4a773", .16)

    def connector(self, part):
        x, y, w, h = part.x, part.y, part.w, part.h
        color = {"usb3":"#3777a4", "ethernet":"#8d7654", "audio":"#242a32",
                 "usb-c":"#374c58", "power":"#394657", "hdmi":"#6d614e",
                 "sd":"#303943", "socket":"#443b31"}.get(part.kind,"#313e49")
        self.round(x+.44, y+.58, w, h, "#172735", INK, .7)
        self.round(x, y, w, h, "#6c7d88", INK, .63, .46)
        self.round(x+.42, y+.37, w-.86, h-.83, "#a1aeb2", radius=.34)
        self.line(((x+.64,y+h-.76),(x+.64,y+.64),(x+w-1,y+.64)), "#cad4d0", .28)
        self.round(x+w*.50, y+h*.18, w*.35, h*.64, color, "#1b2b35", .34, .35)
        if part.kind in ("usb3", "usb2", "ethernet"):
            self.line(((x+w*.58,y+h*.25),(x+w*.58,y+h*.75)), "#829ba6", .34)
        self.label(part.name, x+w*.39, y+h*.52, w*.56, 1.5, "#21303d")

    def header(self, header):
        last_x = header.x + (header.columns-1)*header.column_gap
        last_y = header.y + (header.rows-1)*header.pitch
        edge = min(1.20, header.pitch*.46)
        r = min(.83, header.pitch*.34)
        if header.column_gap > header.pitch * 3:
            for x in (header.x, last_x):
                self.round(x-edge, header.y-edge, edge*2, last_y-header.y+edge*2,
                           "#172b34", INK, edge*.46, .25)
        else:
            self.round(header.x-edge, header.y-edge, last_x-header.x+edge*2,
                       last_y-header.y+edge*2, "#172b34", INK, edge*.46, min(.31, edge*.36))
        for index, (x, y) in enumerate(header.points()):
            if index == 0 and header.columns == 2:
                self.round(x-r, y-r, 2*r, 2*r, GOLD, "#6f4c29", .22, .18)
            else:
                self.ellipse(x, y, r, GOLD, "#6f4c29", .16)
            self.ellipse(x, y, r*.51, "#fff0bc", "#a57e47", .12)

    def render(self):
        self.pcb()
        for part in self.board.parts:
            if part.kind in ("soc", "chip", "shield"):
                self.chip(part, part.kind != "chip")
            elif part.kind == "ribbon":
                self.ribbon(part)
            elif part.kind == "edge":
                self.round(part.x, part.y, part.w, part.h, "#36514c", INK)
                for step in range(int(part.w/.72)):
                    x = part.x+.28+step*.72
                    self.line(((x,part.y+.35),(x,part.y+part.h-.28)), GOLD, .36)
            else:
                self.connector(part)
        for header in (self.board.header, self.board.aux):
            if header:
                self.header(header)
        return self.image.resize((self.w*OUTPUT_SCALE, self.h*OUTPUT_SCALE), Image.Resampling.LANCZOS)

    def geometry(self):
        def describe(header):
            return dict(x=header.x-self.left, y=header.y-self.top, rows=header.rows,
                        pitch=header.pitch, columns=header.columns, columnGap=header.column_gap,
                        order=header.order) if header else None
        return dict(w=self.w, h=self.h,
                    pcb=[-self.left,-self.top,self.board.width,self.board.height] if self.board.outline=="pcb" else None,
                    header=describe(self.board.header), aux=describe(self.board.aux))


def main():
    ART.mkdir(exist_ok=True)
    table = {}
    for name, board in sorted(BOARDS.items()):
        drawing = Drawing(board)
        drawing.render().save(ART / f"{name}.png", optimize=True)
        table[name] = drawing.geometry()

    lines = [".pragma library", "", "// Generated by tools/generate_ports_artwork.py.",
             "// Dimensions and connector positions are in millimetres.", "var boards = {"]
    lines.extend(f"    {json.dumps(name)}: {json.dumps(geometry, separators=(', ', ': '))},"
                 for name, geometry in table.items())
    lines[-1] = lines[-1].rstrip(",")
    lines.extend(("}", ""))
    (FEATURES / "PortsBoardArtwork.js").write_text("\n".join(lines), encoding="utf-8")

    qrc = ROOT / "qml/qml.qrc"
    qrc_text = qrc.read_text(encoding="utf-8")
    asset_root = "ui/configpopup/features"
    qrc_text = re.sub(r"^        <file>" + asset_root + r"/(?:artwork/[^<]+|PortsBoardArtwork\.js)</file>\n",
                      "", qrc_text, flags=re.MULTILINE)
    anchor = f"        <file>{asset_root}/PortsBoardArt.qml</file>\n"
    resources = [f"{asset_root}/PortsBoardArtwork.js"] + [f"{asset_root}/artwork/{name}.png" for name in table]
    qrc.write_text(qrc_text.replace(anchor, anchor + "".join(f"        <file>{path}</file>\n" for path in resources)),
                   encoding="utf-8")


if __name__ == "__main__":
    main()
