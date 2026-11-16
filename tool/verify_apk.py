#!/usr/bin/env python3
"""Verify real ELF architecture, not just the ZIP directory name."""
import hashlib
from pathlib import Path
import struct
import sys
import zipfile

apk = Path(sys.argv[1] if len(sys.argv)>1 else 'build/app/outputs/flutter-apk/app-release.apk')
with zipfile.ZipFile(apk) as z:
    native = [n for n in z.namelist() if n.startswith('lib/') and n.endswith('.so')]
    assert native, 'Aucune bibliothèque native'
    assert 'lib/arm64-v8a/libapp.so' in native, 'libapp.so manquant'
    assert 'lib/arm64-v8a/libflutter.so' in native, 'libflutter.so manquant'
    for name in native:
        assert name.startswith('lib/arm64-v8a/'), f'ABI inattendue : {name}'
        data = z.read(name)
        assert data[:4] == b'\x7fELF' and data[4] == 2, f'Pas ELF64 : {name}'
        endian = '<' if data[5] == 1 else '>'
        assert struct.unpack_from(endian+'H', data,18)[0] == 183, f'Pas AArch64 : {name}'
        print(f'OK ELF64 / AArch64 : {name} ({len(data)} octets)')
print('SHA256', hashlib.sha256(apk.read_bytes()).hexdigest())
print('Taille', apk.stat().st_size, 'octets')
