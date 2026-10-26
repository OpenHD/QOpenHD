"""Probe Vivante's display-independent EGLDevice interface on the target."""
import ctypes as c
import os
import sys

egl = c.CDLL("libEGL.so.1")
egl.eglGetProcAddress.argtypes = [c.c_char_p]
egl.eglGetProcAddress.restype = c.c_void_p
def proc(name, result, *args):
    address = egl.eglGetProcAddress(name.encode())
    if not address:
        raise RuntimeError(f"Missing EGL procedure {name}")
    return c.CFUNCTYPE(result, *args)(address)

query = proc("eglQueryDevicesEXT", c.c_uint, c.c_int, c.POINTER(c.c_void_p), c.POINTER(c.c_int))
platform = proc("eglGetPlatformDisplayEXT", c.c_void_p, c.c_uint, c.c_void_p, c.POINTER(c.c_int))
egl.eglInitialize.argtypes = [c.c_void_p, c.POINTER(c.c_int), c.POINTER(c.c_int)]
egl.eglInitialize.restype = c.c_uint
egl.eglQueryString.argtypes = [c.c_void_p, c.c_int]
egl.eglQueryString.restype = c.c_char_p
egl.eglGetError.restype = c.c_uint
egl.eglTerminate.argtypes = [c.c_void_p]
devices = (c.c_void_p * 16)()
count = c.c_int()
if not query(16, devices, c.byref(count)):
    raise RuntimeError(f"eglQueryDevicesEXT: 0x{egl.eglGetError():x}")
print(f"EGL devices: {count.value}")
success = False
for device in devices[:count.value]:
    display = platform(0x313F, device, None)  # EGL_PLATFORM_DEVICE_EXT
    major, minor = c.c_int(), c.c_int()
    if display and egl.eglInitialize(display, c.byref(major), c.byref(minor)):
        print(f"Initialized EGL {major.value}.{minor.value}")
        print("Vendor:", egl.eglQueryString(display, 0x3053).decode())
        print("Extensions:", egl.eglQueryString(display, 0x3055).decode())
        success = True
    else:
        print(f"EGLDevice initialize failed: 0x{egl.eglGetError():x}")
# This is a short-lived capability probe. Some Vivante BSP builds block in
# eglTerminate after initializing a device display without creating a context.
# Exit the isolated process and let the kernel release its device descriptors.
sys.stdout.flush()
os._exit(0 if success else 1)
