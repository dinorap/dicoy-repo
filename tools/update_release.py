import hashlib, os, datetime

files = ['Packages', 'Packages.gz', 'Packages.bz2']
lines = [
    'Origin: DiCoy Local',
    'Label: DiCoy Local',
    'Suite: stable',
    'Version: 1.0',
    'Codename: ios',
    'Architectures: iphoneos-arm64',
    'Components: main',
    'Description: VCAM local builds for iPhone 7 / iOS 15 (rootless)',
    'Date: ' + datetime.datetime.now(datetime.timezone.utc).strftime('%a, %d %b %Y %H:%M:%S GMT'),
    'SHA256:'
]
for fn in files:
    full = os.path.join('F:/Works/IOS', fn)
    with open(full, 'rb') as f:
        data = f.read()
    h = hashlib.sha256(data).hexdigest()
    sz = len(data)
    lines.append(f' {h} {sz} {fn}')

with open('F:/Works/IOS/Release', 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines) + '\n')

print('Release updated successfully')
