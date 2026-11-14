"""Rebuild setup/graywing-setup.sh and setup/PASTE-INTO-CLOUD-SHELL.txt.

Edit tools/graywing-setup.template.sh (or setup/upload-my-files.sh), then run from the repo root:
    python tools/build-setup.py . tools/graywing-setup.template.sh
The template's @@UPLOAD_MY_FILES@@ line is replaced by upload-my-files.sh, which setup installs as ~/bin/upload-my-files.
"""
import sys
repo, tpl = sys.argv[1], sys.argv[2]
up = open(f"{repo}/setup/upload-my-files.sh", encoding="utf-8", newline="").read()
t = open(tpl, encoding="utf-8", newline="").read()
for bad in ("UPLOAD_MY_FILES_EOF", "GRAYWING_SETUP_EOF", "\r"):
    assert bad not in up, bad
assert t.count("@@UPLOAD_MY_FILES@@\n") == 1
s = t.replace("@@UPLOAD_MY_FILES@@\n", up if up.endswith("\n") else up + "\n")
assert "\r" not in s and "GRAYWING_SETUP_EOF" not in s
open(f"{repo}/setup/graywing-setup.sh", "w", encoding="utf-8", newline="").write(s)
paste = ("cat > ~/graywing-setup.sh <<'GRAYWING_SETUP_EOF'\n" + s + "GRAYWING_SETUP_EOF\n"
         "bash ~/graywing-setup.sh\n"
         "export PATH=\"$HOME/bin:$PATH\"   # so upload-my-files works in this terminal too\n")
open(f"{repo}/setup/PASTE-INTO-CLOUD-SHELL.txt", "w", encoding="utf-8", newline="").write(paste)
print("built", len(s.splitlines()), "lines")
