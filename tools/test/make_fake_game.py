#!/usr/bin/env python3
"""Builds a throw-away fake Vice City folder so install.ps1 can be exercised
without the real game: a minimal PE 'gta-vc.exe' carrying the 1.0 version id,
a tiny IMG v1 archive, handling.cfg and carcols.dat."""
import os, struct, sys

def make_pe(version_id):
    image_base = 0x400000
    rva = 0x61C11C - image_base            # where CLEO looks
    sec_va, sec_raw, sec_size = 0x21C000, 0x400, 0x1000
    dos = bytearray(0x40); dos[:2] = b'MZ'; struct.pack_into('<I', dos, 0x3C, 0x40)
    opt = bytearray(0xE0); struct.pack_into('<H', opt, 0, 0x10B); struct.pack_into('<I', opt, 28, image_base)
    fh = struct.pack('<IHHIIIHH', 0x4550, 0x14C, 1, 0, 0, 0, len(opt), 0x102)
    sec = bytearray(40); sec[:5] = b'.data'
    struct.pack_into('<IIII', sec, 8, sec_size, sec_va, sec_size, sec_raw)
    hdr = bytes(dos) + fh + bytes(opt) + bytes(sec)
    img = bytearray(sec_raw + sec_size); img[:len(hdr)] = hdr
    struct.pack_into('<I', img, sec_raw + (rva - sec_va), version_id)
    return bytes(img)

def make_img(names_sizes):
    dirb, imgb = bytearray(), bytearray()
    for name, size in names_sizes:
        off = len(imgb) // 2048
        sectors = (size + 2047) // 2048
        dirb += struct.pack('<II', off, sectors) + name.encode().ljust(24, b'\0')
        imgb += (name.encode() * (size // len(name) + 1))[:size].ljust(sectors * 2048, b'\0')
    return bytes(dirb), bytes(imgb)

def main(root, version='1.0'):
    ids = {'1.0': 0x74FF5064, '1.1': 0x00408DC0, 'steam': 0x24E58287}
    os.makedirs(os.path.join(root, 'models'), exist_ok=True)
    os.makedirs(os.path.join(root, 'data', 'maps', 'club'), exist_ok=True)
    open(os.path.join(root, 'gta-vc.exe'), 'wb').write(make_pe(ids[version]))
    d, i = make_img([('infernus.dff', 3000), ('infernus.txd', 5000), ('cheetah.dff', 2048), ('cheetah.txd', 100)])
    open(os.path.join(root, 'models', 'gta3.dir'), 'wb').write(d)
    open(os.path.join(root, 'models', 'gta3.img'), 'wb').write(i)
    open(os.path.join(root, 'data', 'handling.cfg'), 'w').write(
        ";\tthe following data is for cars\nADMIRAL\t\t1650.0\t2.5\t4.9\t0.0\n"
        "INFERNUS\t\t1400.0\t2.1\t4.7\t0.0\t0.0\t-0.4\nCHEETAH\t\t1200.0\t2.0\t4.3\n"
        "% PREDATOR\t\t2200.0\n! ANGEL\t\t500.0\n")
    open(os.path.join(root, 'data', 'carcols.dat'), 'w').write(
        "col\n0,0,0\ncar\nadmiral, 1,1, 2,2\ninfernus, 0,0, 1,1\ncheetah, 3,3\nend\n")
    open(os.path.join(root, 'data', 'maps', 'club', 'CLUB.ipl'), 'w').write("original club ipl\n")
    open(os.path.join(root, 'data', 'default.ide'), 'w').write(
        "# fake\nobjs\nend\ncars\n"
        "130, landstal, landstal, car, LANDSTAL, LANDSTK, richfamily, 10, 7, 0, 164, 0.9\n"
        "141, infernus, infernus, car, INFERNUS, INFERNU, executive, 6, 7, 0, 178, 0.75\n"
        "145, cheetah, cheetah, car, CHEETAH, CHEETAH, executive, 6, 7, 0, 178, 0.75\n"
        "end\n")
    print("fake game written to", root)

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else '1.0')
