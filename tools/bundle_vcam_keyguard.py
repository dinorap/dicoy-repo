import io
import tarfile
import gzip
import time
import os
import shutil

def make_ar_header(name, size):
    return (f"{name:<16}" +
            f"{int(time.time()):<12}" +
            "0     " +
            "0     " +
            "100644  " +
            f"{size:<10}" +
            "`\n").encode("ascii")

def unpack_deb(deb_path, out_dir):
    os.makedirs(out_dir, exist_ok=True)
    with open(deb_path, "rb") as f:
        data = f.read()
    assert data[:8] == b"!<arch>\n", f"{deb_path} is not an ar archive"
    pos = 8
    while pos < len(data):
        h = data[pos:pos+60]
        if len(h) < 60: break
        name = h[:16].decode("ascii", errors="ignore").strip()
        size = int(h[48:58].decode("ascii", errors="ignore").strip())
        pos += 60
        fdata = data[pos:pos+size]
        if size % 2 == 1: pos += 1
        pos += size
        if "control" in name:
            os.makedirs(os.path.join(out_dir, "control"), exist_ok=True)
            t = tarfile.open(fileobj=io.BytesIO(fdata))
            t.extractall(os.path.join(out_dir, "control"))
        elif "data" in name:
            os.makedirs(os.path.join(out_dir, "data"), exist_ok=True)
            t = tarfile.open(fileobj=io.BytesIO(fdata))
            t.extractall(os.path.join(out_dir, "data"))

def pack_deb(stage_dir, out_deb_path):
    # 1. create control.tar.gz
    control_buf = io.BytesIO()
    with gzip.GzipFile(fileobj=control_buf, mode="wb", mtime=0) as gz:
        with tarfile.open(fileobj=gz, mode="w:") as tar:
            control_dir = os.path.join(stage_dir, "control")
            for item in sorted(os.listdir(control_dir)):
                full_path = os.path.join(control_dir, item)
                arcname = f"./{item}"
                tar.add(full_path, arcname=arcname)
    control_bytes = control_buf.getvalue()

    # 2. create data.tar.gz
    data_buf = io.BytesIO()
    with gzip.GzipFile(fileobj=data_buf, mode="wb", mtime=0) as gz:
        with tarfile.open(fileobj=gz, mode="w:") as tar:
            data_dir = os.path.join(stage_dir, "data")
            for root, dirs, files in os.walk(data_dir):
                dirs.sort()
                files.sort()
                rel_root = os.path.relpath(root, data_dir)
                if rel_root == ".":
                    tar_root = "."
                else:
                    tar_root = rel_root.replace("\\", "/")
                for d in dirs:
                    d_path = os.path.join(root, d)
                    arcname = f"{tar_root}/{d}" if tar_root != "." else d
                    ti = tar.gettarinfo(d_path, arcname=arcname)
                    ti.uid = 0
                    ti.gid = 0
                    ti.uname = "root"
                    ti.gname = "wheel"
                    tar.addfile(ti)
                for f in files:
                    f_path = os.path.join(root, f)
                    arcname = f"{tar_root}/{f}" if tar_root != "." else f
                    ti = tar.gettarinfo(f_path, arcname=arcname)
                    ti.uid = 0
                    ti.gid = 0
                    ti.uname = "root"
                    ti.gname = "wheel"
                    with open(f_path, "rb") as fp:
                        tar.addfile(ti, fp)
    data_bytes = data_buf.getvalue()

    # 3. assemble deb
    with open(out_deb_path, "wb") as deb:
        deb.write(b"!<arch>\n")
        
        # debian-binary
        deb_binary = b"2.0\n"
        deb.write(make_ar_header("debian-binary", len(deb_binary)))
        deb.write(deb_binary)
        if len(deb_binary) % 2 == 1: deb.write(b"\n")
        
        # control.tar.gz
        deb.write(make_ar_header("control.tar.gz", len(control_bytes)))
        deb.write(control_bytes)
        if len(control_bytes) % 2 == 1: deb.write(b"\n")
        
        # data.tar.gz
        deb.write(make_ar_header("data.tar.gz", len(data_bytes)))
        deb.write(data_bytes)
        if len(data_bytes) % 2 == 1: deb.write(b"\n")

    print(f"Successfully generated {out_deb_path} ({os.path.getsize(out_deb_path)} bytes)")

def bundle_vcam_keyguard(base_deb, keyguard_deb, sandy_profile, out_deb):
    work_dir = "temp_bundle_vcam"
    if os.path.exists(work_dir):
        shutil.rmtree(work_dir)
    os.makedirs(work_dir)

    print("Unpacking base VCAM deb...")
    unpack_deb(base_deb, os.path.join(work_dir, "base"))

    print("Unpacking KeyGuard deb...")
    unpack_deb(keyguard_deb, os.path.join(work_dir, "kg"))

    # Copy KeyGuard dylib and plist into base data
    kg_data = os.path.join(work_dir, "kg", "data")
    base_data = os.path.join(work_dir, "base", "data")

    # Locate DynamicLibraries in base
    base_dylibs = os.path.join(base_data, "var", "jb", "Library", "MobileSubstrate", "DynamicLibraries")
    os.makedirs(base_dylibs, exist_ok=True)

    kg_dylibs = os.path.join(kg_data, "var", "jb", "Library", "MobileSubstrate", "DynamicLibraries")
    for f in os.listdir(kg_dylibs):
        src_f = os.path.join(kg_dylibs, f)
        dst_f = os.path.join(base_dylibs, f)
        shutil.copy2(src_f, dst_f)
        print(f"Copied {f} to {base_dylibs}")

    # Copy libSandy profile
    base_sandy = os.path.join(base_data, "var", "jb", "Library", "libSandy")
    os.makedirs(base_sandy, exist_ok=True)
    if os.path.exists(sandy_profile):
        shutil.copy2(sandy_profile, os.path.join(base_sandy, "DiCoyKeyGuard.plist"))
        print(f"Copied DiCoyKeyGuard.plist to {base_sandy}")

    # Update control file
    control_file = os.path.join(work_dir, "base", "control", "control")
    with open(control_file, "r", encoding="utf-8") as f:
        ctrl = f.read()

    # Update version to 1.2.3+local27
    ctrl = ctrl.replace("Version: 1.2.3+local26", "Version: 1.2.3+local27")
    ctrl = ctrl.replace("Description: Timed virtual camera for Camera, BeautyCam, Google Lens and Demaecan with a volume-button menu.",
                        "Description: Timed virtual camera with Activation License KeyGuard for Camera, BeautyCam, Google Lens and Demaecan.")
    with open(control_file, "w", encoding="utf-8") as f:
        f.write(ctrl)

    # Update postinst script permissions
    postinst_file = os.path.join(work_dir, "base", "control", "postinst")
    if os.path.exists(postinst_file):
        with open(postinst_file, "r", encoding="utf-8") as f:
            p_content = f.read()
        p_extra = """
# KeyGuard license directory setup
mkdir -p "$CAMERA_DIR"
chown -R mobile:mobile "/var/mobile/Library/Application Support/VCAM" 2>/dev/null || true
chmod -R 777 "/var/mobile/Library/Application Support/VCAM" 2>/dev/null || true
"""
        if "KeyGuard license directory setup" not in p_content:
            p_content = p_content.replace('echo "=== DiCoy postinst done ==="', p_extra + '\necho "=== DiCoy postinst done ==="')
            with open(postinst_file, "w", encoding="utf-8") as f:
                f.write(p_content)

    # Pack into new deb
    pack_deb(os.path.join(work_dir, "base"), out_deb)
    shutil.rmtree(work_dir)

if __name__ == "__main__":
    bundle_vcam_keyguard(
        "debs/com.dicoy.dicoy_1.2.3+local26_iphoneos-arm64.deb",
        "debs/com.dicoy.keyguard_1.1_iphoneos-arm64.deb",
        "src/DiCoyKeyGuard/DiCoyKeyGuard.plist",
        "debs/com.dicoy.dicoy_1.2.3+local27_iphoneos-arm64.deb"
    )
