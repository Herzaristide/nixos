#!/usr/bin/env python3
"""Set a static color on the MSI SteelSeries KLC keyboard (USB 1038:113a).

Writes HID feature reports directly to /dev/hidrawN via HIDIOCSFEATURE.
We target the hidraw exposed by *interface 0* of the keyboard — interface 1
exists too but the controller silently ignores feature reports sent to it.

This used to go through libhidapi-libusb but that backend ended up opening
the wrong interface (or sending control transfers the controller dropped on
the floor): the writes succeeded with no error and the LEDs never changed.
Going through the kernel's hidraw subsystem is shorter and works.

Only the static-uniform-color path is supported on purpose: animated effects
have been observed to wedge the controller into an unrecoverable state
requiring an EC reset.
"""

import argparse
import errno
import fcntl
import os
import sys
import time

VENDOR_ID = 0x1038
PRODUCT_ID = 0x113A
# 350 ms between region packets — matches the inter-command delay the
# upstream fork settled on. Shorter intervals risked EPROTO.
INTER_COMMAND_DELAY = 0.35
NB_KEYS = 42

REGION_ID_CODES = {
    "alphanum": 0x2A,
    "enter": 0x0B,
    "modifiers": 0x18,
    "numpad": 0x24,
}

REGION_KEYCODES = {
    "alphanum": [
        4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22,
        23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39,
        58, 59, 60, 61, 62, 63,
    ],
    "enter": [40, 49, 50, 100, 135, 136, 137, 138, 139, 144, 145] + [0] * 31,
    "modifiers": [
        41, 42, 43, 44, 45, 46, 47, 48, 51, 52, 53, 54, 55, 56, 57, 101, 224,
        225, 226, 227, 228, 229, 230, 240,
    ] + [0] * 18,
    "numpad": [
        64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80,
        81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97,
        98, 99,
    ] + [0] * 6,
}


# HIDIOCSFEATURE ioctl number, computed manually to avoid pulling ctypes
# just for ioctl(IO,W,_SZ) macros.
def _IOC(direction: int, type_: int, nr: int, size: int) -> int:
    return (direction << 30) | (size << 16) | (type_ << 8) | nr


def HIDIOCSFEATURE(size: int) -> int:
    # _IOC_READ | _IOC_WRITE = 3, type 'H' = 0x48, nr 6
    return _IOC(3, 0x48, 0x06, size)


def make_key_colors_packet(region, rgb):
    packet = [0x0E, 0x00, REGION_ID_CODES[region], 0x00]
    keycodes = [kc for kc in REGION_KEYCODES[region] if kc != 0]
    for kc in keycodes:
        packet += rgb + [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, kc]
    pad = NB_KEYS - len(keycodes)
    packet += [0x00] * (pad * 12)
    packet += [0x00] * 14 + [0x08, 0x39]
    return packet


def make_refresh_packet():
    return [0x09] + [0x00] * 63


def find_target_hidraw() -> str:
    """Return the /dev/hidrawN path for VENDOR_ID:PRODUCT_ID interface 0."""
    # The kernel exposes HID IDs in uevent as 8-digit zero-padded hex,
    # e.g. HID_ID=0003:00001038:0000113A.
    needle = f"{VENDOR_ID:08X}:{PRODUCT_ID:08X}"
    matches = []
    for name in sorted(os.listdir("/sys/class/hidraw")):
        try:
            with open(f"/sys/class/hidraw/{name}/device/uevent") as f:
                uevent = f.read()
        except OSError:
            continue
        if needle not in uevent.upper():
            continue
        intf_dir = os.path.realpath(f"/sys/class/hidraw/{name}/device")
        intf_num_path = os.path.join(os.path.dirname(intf_dir), "bInterfaceNumber")
        try:
            with open(intf_num_path) as f:
                intf = int(f.read().strip(), 16)
        except OSError:
            intf = -1
        matches.append((intf, name))
    # Prefer interface 0; fall back to whatever we found.
    for intf, name in matches:
        if intf == 0:
            return f"/dev/{name}"
    if matches:
        return f"/dev/{matches[0][1]}"
    sys.exit(
        f"No /dev/hidraw* exposed by {VENDOR_ID:04x}:{PRODUCT_ID:04x} — "
        "check that bConfigurationValue=1 and the udev rule is loaded."
    )


def main():
    ap = argparse.ArgumentParser(description="Set MSI keyboard to a static color.")
    ap.add_argument("color", help="hex RRGGBB (a leading # is accepted)")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--hidraw", help="override /dev/hidrawN path")
    args = ap.parse_args()

    color_hex = args.color.lstrip("#").lower()
    if len(color_hex) != 6 or any(c not in "0123456789abcdef" for c in color_hex):
        sys.exit(f"Invalid color: {args.color}")
    rgb = [int(color_hex[i:i + 2], 16) for i in (0, 2, 4)]

    packets = {r: bytes(make_key_colors_packet(r, rgb)) for r in REGION_ID_CODES}
    refresh = bytes(make_refresh_packet())

    if args.dry_run:
        for r, p in packets.items():
            keys = sum(1 for kc in REGION_KEYCODES[r] if kc != 0)
            print(f"  {r:<10}: {len(p)} bytes ({keys} keys)")
        print(f"  refresh   : {len(refresh)} bytes")
        return

    path = args.hidraw or find_target_hidraw()
    try:
        fd = os.open(path, os.O_RDWR)
    except OSError as e:
        sys.exit(f"open({path}) failed: {e}")

    ok = True
    try:
        for region, data in packets.items():
            try:
                fcntl.ioctl(fd, HIDIOCSFEATURE(len(data)), data)
            except OSError as e:
                print(
                    f"msi-rgb-set: HIDIOCSFEATURE {region} failed: {e} — aborting",
                    file=sys.stderr,
                )
                ok = False
                break
            time.sleep(INTER_COMMAND_DELAY)
        if ok:
            try:
                n = os.write(fd, refresh)
                if n != len(refresh):
                    print(
                        f"msi-rgb-set: short refresh write ({n}/{len(refresh)})",
                        file=sys.stderr,
                    )
                    ok = False
            except OSError as e:
                print(f"msi-rgb-set: refresh write failed: {e}", file=sys.stderr)
                ok = False
    finally:
        try:
            os.close(fd)
        except OSError as e:
            if e.errno != errno.EBADF:
                raise

    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
