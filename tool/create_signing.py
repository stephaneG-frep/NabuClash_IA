#!/usr/bin/env python3
"""Create a project-local release identity. Never prints passwords."""
from pathlib import Path
import os
import secrets
import shutil
import subprocess

root = Path(__file__).resolve().parents[1]
private = root / '.private'
private.mkdir(exist_ok=True, mode=0o700)
key, props = private / 'nabuclash-release.jks', private / 'signing.properties'
if key.exists() or props.exists():
    if not (key.exists() and props.exists()):
        raise SystemExit('Signature incomplète : restaurer les fichiers originaux de .private/.')
    print('Signature existante conservée.')
    raise SystemExit(0)
keytool = shutil.which('keytool')
if not keytool:
    candidate = Path('/opt/android-studio/jbr/bin/keytool')
    if candidate.exists():
        keytool = str(candidate)
if not keytool:
    raise SystemExit('Installer JDK 17+ et rendre keytool accessible dans PATH.')
password = secrets.token_urlsafe(32)
subprocess.run([keytool, '-genkeypair', '-keystore', str(key), '-alias', 'nabuclash',
                '-keyalg', 'RSA', '-keysize', '3072', '-validity', '10000',
                '-storepass:env', 'NABU_SIGN_PASSWORD', '-keypass:env', 'NABU_SIGN_PASSWORD',
                '-dname', 'CN=NabuClash AI, OU=Mobile, O=NabuClash, C=FR'],
               env={**os.environ, 'NABU_SIGN_PASSWORD': password}, check=True,
               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
props.write_text(f'storeFile={key.as_posix()}\nstorePassword={password}\nkeyAlias=nabuclash\nkeyPassword={password}\n')
key.chmod(0o600)
props.chmod(0o600)
print('Signature créée dans .private/. Sauvegarder ce dossier hors Git et hors ZIP public.')
