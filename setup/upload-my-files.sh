#!/usr/bin/env bash
# upload-my-files - copy your own files from Cloud Shell into the "My Uploads" folder in your Google Drive and
# into the lab's "My uploads" data store, so your Gemini Enterprise agents can use them next to the Graywing data.
#
#   upload-my-files              uploads everything in ~/my-files (subfolders are kept)
#   upload-my-files <folder>     uploads everything in <folder> instead
#
# Put files in ~/my-files first with Cloud Shell's own Upload (the ⋮ menu at the top right of the terminal).
# Word, Excel and PowerPoint files become Google Docs, Sheets and Slides (easier for the agent to read).
# Safe to re-run: files already in "My Uploads" (same name) are skipped, so nothing is duplicated.
# Needs the lab setup (graywing-setup.sh) to have run once: it approves Google Drive access for this sign-in.
# Settings: MY_UPLOADS_FOLDER="Other name" (a top-level My Drive folder, created if missing) or a Drive folder link.
# Everything is logged with timestamps to ~/graywing-lab/setup.log.
set -uo pipefail

# ---- settings -------------------------------------------------------------------------------------------
SRC="${1:-$HOME/my-files}"
TARGET="${MY_UPLOADS_FOLDER:-My Uploads}"
case "$TARGET" in   # a Drive folder link or "id:<folder id>" means that exact folder, not a name
  *drive.google.com/*folders/*|id:*) LABEL="Drive folder you chose" ;;
  *) LABEL="\"$TARGET\" folder" ;;
esac
WORK="${WORK:-$HOME/graywing-lab}"
if [ -f "$HOME/graywing-setup.sh" ]; then SETUP_CMD="bash ~/graywing-setup.sh"   # the paste-in setup leaves this file
else SETUP_CMD="bash <(curl -fsSL https://raw.githubusercontent.com/tridorian/YPO-Chicagoland/main/setup/graywing-setup.sh)"; fi
# ---------------------------------------------------------------------------------------------------------

mkdir -p "$WORK" || { echo "Can't create $WORK"; exit 1; }
LOG="$WORK/setup.log"
STEPS=5
STEP=0
T0=$SECONDS

ts() { date '+%H:%M:%S'; }
elapsed() { local s=$(( SECONDS - T0 )); printf '%d:%02d' $(( s / 60 )) $(( s % 60 )); }
log() { printf '%s  %s\n' "$(ts)" "$*" >> "$LOG"; }
step() {
  STEP=$(( STEP + 1 ))
  printf '\n\033[1;36m[%d/%d]\033[0m \033[1m%s\033[0m  \033[2m(%s elapsed)\033[0m\n' "$STEP" "$STEPS" "$*" "$(elapsed)"
  log "== UPLOAD-MY-FILES $STEP/$STEPS: $*"
}
ok() { printf '      \033[32m✔\033[0m %s\n' "$*"; log "OK    $*"; }
info() { printf '        %s\n' "$*"; log "      $*"; }
warn() { printf '      \033[33m!\033[0m %s\n' "$*"; log "WARN  $*"; }
die() {
  printf '\r\033[K\n      \033[31m✘ %s\033[0m\n\n' "$*"
  printf '      Stopped at step %d of %d after %s. Full log: %s\n' "$STEP" "$STEPS" "$(elapsed)" "$LOG"
  printf '      Fix the problem above (or just wait a minute), then run %s again; it skips what is already there.\n\n' "$ME"
  log "FAIL  $*"
  exit 1
}

# How to run this script again, as the user would type it
if [ "$(command -v upload-my-files 2>/dev/null)" ]; then ME="upload-my-files"; else ME="bash $0"; fi

printf '\n\033[1m  Upload your own files to Google Drive\033[0m\n'
printf '  \033[2mFrom %s to the %s in your Google Drive. Full log: %s\033[0m\n' "$SRC" "$LABEL" "$LOG"
log "######## upload-my-files started (SRC=$SRC TARGET=$TARGET)"

# ---- 1. project and account ------------------------------------------------------------------------------
step "Checking your lab project and sign-in"
PROJECT="${GOOGLE_CLOUD_PROJECT:-$(gcloud config get-value project 2>/dev/null)}"
if [ -z "$PROJECT" ] || [ "$PROJECT" = "(unset)" ]; then
  PROJECT="$(gcloud projects list --format='value(projectId)' --filter='projectId:qwiklabs-gcp-*' --limit=1 2>/dev/null)"
fi
[ -n "$PROJECT" ] || die "No project found. In the console, pick the lab project at the top, then run $ME again."
ACCOUNT="$(gcloud config get-value account 2>/dev/null)"
ok "Project  $PROJECT"
ok "Account  $ACCOUNT"
[ -f "$WORK/links.txt" ] || warn "The lab setup hasn't finished in this Cloud Shell yet (no $WORK/links.txt). Run it first if the next step fails."

# ---- 2. Drive access -------------------------------------------------------------------------------------
step "Checking Google Drive access"
has_drive_scope() {
  local t; t="$(gcloud auth print-access-token 2>/dev/null)" || return 1
  curl -s "https://oauth2.googleapis.com/tokeninfo?access_token=$t" | grep -q 'auth/drive'
}
if has_drive_scope; then
  ok "This sign-in can write to your Google Drive"
else
  log "token has no Drive scope"
  printf '      \033[31m✘ This Cloud Shell sign-in has no Google Drive access yet.\033[0m\n'
  info "Run the lab setup again; it asks for Drive access once and keeps everything else:"
  info "  $SETUP_CMD"
  info "Then run $ME again."
  log "FAIL  no Drive scope; told the user to re-run the setup"
  exit 1
fi

# ---- 3. local files --------------------------------------------------------------------------------------
step "Looking for your files in $SRC"
[ $# -eq 0 ] && mkdir -p "$SRC" 2>/dev/null   # the default ~/my-files is made for you; a folder you name must exist
[ -d "$SRC" ] || die "$SRC is not a folder."
COUNT="$(find "$SRC" -mindepth 1 -name '.*' -prune -o -type f -print 2>/dev/null | wc -l | tr -d ' ')"
if [ "$COUNT" -gt 0 ]; then
  ok "Found $COUNT file$([ "$COUNT" = 1 ] || echo s) ($(du -sh "$SRC" 2>/dev/null | cut -f1))"
  LOCAL="$SRC"
else
  warn "$SRC is empty, so there is nothing to upload yet."
  LOCAL="-"   # still make sure the Drive folder exists, so you can drag files into it in the browser
fi

# ---- 4. upload -------------------------------------------------------------------------------------------
step "Uploading to the $LABEL in your Google Drive"
INTO=(--into "$TARGET")
case "$TARGET" in
  *drive.google.com/*folders/*) FID="${TARGET##*folders/}"; INTO=(--into-id "${FID%%[?/#]*}") ;;
  id:*) INTO=(--into-id "${TARGET#id:}") ;;
esac
cd "$WORK" || die "Can't open $WORK"
cat > drive_upload_lab.py <<'PY_EOF'
"""Upload a local folder into the signed-in user's My Drive (stdlib only; runs in Cloud Shell).

  python3 drive_upload_lab.py <folder> [id_file]                     -> My Drive/<folder's name>/... (demo data)
  python3 drive_upload_lab.py <folder> [id_file] --into "My Uploads" -> <folder>'s contents go into My Drive/My Uploads
  python3 drive_upload_lab.py - [id_file] --into "My Uploads"        -> only find or create My Drive/My Uploads
  --into-id FOLDER_ID targets an existing folder by id instead of a top-level My Drive folder by name.

.xlsx/.xls/.csv, .docx/.doc and .pptx/.ppt are converted to Sheets/Docs/Slides (if Drive can't convert one, it is
uploaded as it is); PDFs, images and everything else stay files. Files over MAX_FILE_MB (default 100) are skipped.
Re-runs reuse folders and skip files that already exist by name, so nothing is duplicated.
Speed: folders are made level by level (in parallel within a level), then files upload WORKERS at a time;
new writes start at most every WRITE_GAP seconds to stay inside Drive's per-user write rate.
Token: $DRIVE_TOKEN if set, else `gcloud auth print-access-token` (refreshed on 401).
Shows a live progress bar; logs one line per file to $UPLOAD_LOG (if set); writes the root folder id to id_file.
Exit code 2 when some files could not be uploaded (the others are done; a re-run retries only the missing ones).
"""
import argparse
import http.client
import json
import mimetypes
import os
import subprocess
import sys
import threading
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime

API = os.environ.get("DRIVE_API", "https://www.googleapis.com/drive/v3")
UPLOAD = os.environ.get("DRIVE_UPLOAD_API", "https://www.googleapis.com/upload/drive/v3")
FOLDER = "application/vnd.google-apps.folder"
SHEET, DOC, SLIDES = ("application/vnd.google-apps." + k for k in ("spreadsheet", "document", "presentation"))
CONVERT = {".xlsx": SHEET, ".xls": SHEET, ".csv": SHEET,
           ".docx": DOC, ".doc": DOC,
           ".pptx": SLIDES, ".ppt": SLIDES}
SOURCE = {".xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
          ".docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
          ".pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation",
          ".xls": "application/vnd.ms-excel", ".doc": "application/msword", ".ppt": "application/vnd.ms-powerpoint",
          ".csv": "text/csv", ".txt": "text/plain", ".md": "text/markdown", ".pdf": "application/pdf",
          ".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".png": "image/png", ".gif": "image/gif",
          ".webp": "image/webp", ".heic": "image/heic"}
WORKERS = int(os.environ.get("UPLOAD_WORKERS", "6"))
WRITE_GAP = float(os.environ.get("WRITE_GAP", "0.3"))
MAX_BYTES = int(float(os.environ.get("MAX_FILE_MB", "100")) * 1024 * 1024)
RESUMABLE_OVER = 5 * 1024 * 1024  # Drive's multipart upload is meant for files up to 5 MB

_token = os.environ.get("DRIVE_TOKEN", "")
_token_lock = threading.Lock()
_write_lock = threading.Lock()
_last_write = 0.0
# Cloud Shell's built-in credential needs a quota project on Drive calls ("drive.googleapis.com API requires a
# quota project"); a gcloud user login doesn't. Send it when given, drop it if the project refuses it.
QUOTA_PROJECT = os.environ.get("QUOTA_PROJECT", "")
_use_quota = bool(QUOTA_PROJECT)


class DriveError(Exception):
    """A request Drive refused or kept failing; fatal for folders, reported per file for uploads."""


def token(refresh=False):
    global _token
    with _token_lock:
        if refresh or not _token:
            _token = subprocess.run(["gcloud", "auth", "print-access-token"],
                                    capture_output=True, text=True).stdout.strip()
        return _token


def api_message(text):
    try:
        return json.loads(text)["error"]["message"]
    except Exception:
        return text[:300]


def pace_write():
    """Space out the start of write requests across all threads."""
    global _last_write
    with _write_lock:
        wait = WRITE_GAP - (time.time() - _last_write)
        if wait > 0:
            time.sleep(wait)
        _last_write = time.time()


def call(method, url, params=None, body=None, headers=None, want_headers=False):
    global _use_quota
    if params:
        url += "?" + urllib.parse.urlencode(params)
    refresh = False
    for attempt in range(8):
        if method != "GET":
            pace_write()
        h = {"Authorization": "Bearer " + token(refresh)}
        if _use_quota:
            h["X-Goog-User-Project"] = QUOTA_PROJECT
        h.update(headers or {})
        refresh = False
        req = urllib.request.Request(url, data=body, headers=h, method=method)
        try:
            with urllib.request.urlopen(req, timeout=180) as r:
                raw = r.read()
                if want_headers:
                    return r.headers
                return json.loads(raw) if raw else {}
        except urllib.error.HTTPError as e:
            text = e.read().decode("utf-8", "replace")
            if e.code == 401 and attempt < 2:
                refresh = True
                continue
            if e.code == 403 and "quota project" in text and not _use_quota and QUOTA_PROJECT:
                _use_quota = True
                continue
            if e.code == 403 and _use_quota and ("USER_PROJECT_DENIED" in text or "serviceusage" in text):
                _use_quota = False
                continue
            if e.code in (429, 500, 502, 503, 504) or (e.code == 403 and "ateLimit" in text):
                time.sleep(min(30, 1.5 * 2 ** attempt))
                continue
            if e.code == 403 and "insufficient" in text.lower():
                sys.exit("\nDrive said the sign-in has no Drive access. Re-run the setup and approve Google Drive access.")
            raise DriveError(f"Google Drive refused the request ({e.code}): {api_message(text)}")
        except (urllib.error.URLError, OSError, http.client.HTTPException):  # network blip, reset, timeout
            time.sleep(min(30, 1.5 * 2 ** attempt))
    raise DriveError(f"Drive API kept failing on {method} {url.split('?')[0]}")


def q_escape(s):
    return s.replace("\\", "\\\\").replace("'", "\\'")


def children(parent):
    out, params = [], {"q": f"'{parent}' in parents and trashed = false", "pageSize": 1000,
                       "fields": "nextPageToken, files(id,name,mimeType)"}
    while True:
        res = call("GET", f"{API}/files", params)
        out += res.get("files", [])
        if not res.get("nextPageToken"):
            return out
        params["pageToken"] = res["nextPageToken"]


def make_folder(parent, name):
    return call("POST", f"{API}/files", {"fields": "id"}, json.dumps(
        {"name": name, "mimeType": FOLDER, "parents": [parent]}).encode(), {"Content-Type": "application/json"})["id"]


def root_folder(name):
    q = (f"'root' in parents and name = '{q_escape(name)}' and mimeType = '{FOLDER}' "
         f"and trashed = false and 'me' in owners")
    found = call("GET", f"{API}/files", {"q": q, "fields": "files(id,createdTime)", "orderBy": "createdTime"})
    if found.get("files"):
        return found["files"][0]["id"], False
    return make_folder("root", name), True


def folder_by_id(fid):
    try:
        meta = call("GET", f"{API}/files/{urllib.parse.quote(fid)}", {"fields": "id,name,mimeType,trashed"})
    except DriveError as e:
        sys.exit(f"\nCan't open the Drive folder {fid}: {e}")
    if meta.get("mimeType") != FOLDER or meta.get("trashed"):
        sys.exit(f"\n{fid} is not a Drive folder (or it is in the trash).")
    return meta["id"], meta.get("name", fid)


def content_type(path):
    ext = os.path.splitext(path)[1].lower()
    return SOURCE.get(ext) or mimetypes.guess_type(path)[0] or "application/octet-stream"


def upload(parent, path, name, convert):
    meta = {"name": name, "parents": [parent]}
    if convert:
        meta["mimeType"] = convert
    ctype = content_type(path)
    with open(path, "rb") as fh:
        data = fh.read()
    if len(data) > RESUMABLE_OVER:
        where = call("POST", f"{UPLOAD}/files", {"uploadType": "resumable", "fields": "id"}, json.dumps(meta).encode(),
                     {"Content-Type": "application/json; charset=UTF-8", "X-Upload-Content-Type": ctype,
                      "X-Upload-Content-Length": str(len(data))}, want_headers=True)
        session = where.get("Location") or where.get("location")
        if not session:
            raise DriveError("Drive did not start the upload (no upload address)")
        call("PUT", session, None, data, {"Content-Type": ctype})
        return
    b = "gw" + uuid.uuid4().hex
    body = (f"--{b}\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n{json.dumps(meta)}\r\n"
            f"--{b}\r\nContent-Type: {ctype}\r\n\r\n").encode() + data + f"\r\n--{b}--".encode()
    call("POST", f"{UPLOAD}/files", {"uploadType": "multipart", "fields": "id"}, body,
         {"Content-Type": f"multipart/related; boundary={b}"})


def upload_one(fid, full, name, convert):
    """Upload one file; if Drive can't convert it, upload it unconverted. Returns what it became."""
    try:
        upload(fid, full, name, convert)
        return convert
    except DriveError as e:
        if not convert:
            raise
        log(f"warn  {os.path.basename(full)}: conversion refused ({e}); uploading it as it is")
        upload(fid, full, os.path.basename(full), None)
        return None


def plan(local_root, root_id, root_existed, pool):
    """Walk the tree level by level: list existing folders, create missing ones (in parallel within a level).
    Returns the files still to upload, how many are already in Drive, and the files too big to upload."""
    tasks, skipped, too_big = [], 0, []
    level = [(local_root, root_id, root_existed)]
    while level:
        listings = list(pool.map(lambda x: children(x[1]) if x[2] else [], level))
        creates, next_level = [], []
        for (path, fid, _), kids in zip(level, listings):
            folders = {k["name"]: k["id"] for k in kids if k["mimeType"] == FOLDER}
            files = {k["name"] for k in kids if k["mimeType"] != FOLDER}
            for entry in sorted(os.listdir(path)):
                full = os.path.join(path, entry)
                if entry.startswith("."):
                    continue
                if os.path.isdir(full):
                    if entry in folders:
                        next_level.append((full, folders[entry], True))
                    else:
                        creates.append((full, fid, entry))
                    continue
                if not os.path.isfile(full):
                    continue
                stem, ext = os.path.splitext(entry)
                convert = CONVERT.get(ext.lower())
                name = stem if convert else entry
                rel = os.path.relpath(full, local_root)
                if name in files or entry in files:  # entry: an earlier run uploaded it unconverted
                    skipped += 1
                    log(f"skip  {rel} (already in Drive)")
                elif os.path.getsize(full) > MAX_BYTES:
                    too_big.append(rel)
                    log(f"big   {rel} ({os.path.getsize(full) // 2 ** 20} MB, over {MAX_BYTES // 2 ** 20} MB): not uploaded")
                else:
                    tasks.append((fid, full, name, convert, rel))
        made = list(pool.map(lambda c: make_folder(c[1], c[2]), creates))
        next_level += [(c[0], new_id, False) for c, new_id in zip(creates, made)]
        level = next_level
    return tasks, skipped, too_big


def log(msg):
    path = os.environ.get("UPLOAD_LOG")
    if path:
        with open(path, "a", encoding="utf-8") as fh:
            fh.write(f"{datetime.now():%H:%M:%S}  DRIVE {msg}\n")


def bar(done, total, rel):
    total = total or 1
    width = 24
    fill = width * done // total
    where = os.path.dirname(rel).split(os.sep)[0] or os.path.basename(rel)
    where = (where[:30] + "…") if len(where) > 31 else where
    sys.stdout.write(f"\r\033[K        [{'█' * fill}{'░' * (width - fill)}] {done:3}/{total} files "
                     f"{100 * done // total:3}%  \033[2m{where}\033[0m")
    sys.stdout.flush()


def main(argv=None):
    ap = argparse.ArgumentParser(description="Upload a local folder into My Drive.")
    ap.add_argument("folder", help="local folder to upload, or - to only find or create the Drive folder")
    ap.add_argument("id_file", nargs="?", help="write the Drive folder id here (else print ROOT_FOLDER_ID=...)")
    ap.add_argument("--into", metavar="NAME", help="top-level My Drive folder to upload into (created if missing)")
    ap.add_argument("--into-id", metavar="FOLDER_ID", help="existing Drive folder to upload into")
    args = ap.parse_args(argv)
    local = None if args.folder == "-" else os.path.abspath(args.folder)
    if local is None and not (args.into or args.into_id):
        ap.error("folder '-' needs --into or --into-id")
    if local is not None and not os.path.isdir(local):
        ap.error(f"{args.folder} is not a folder")
    t0 = time.time()
    if args.into_id:
        root_id, name = folder_by_id(args.into_id)
        created = False
    else:
        name = args.into or os.path.basename(local.rstrip("/"))
        try:
            root_id, created = root_folder(name)
        except DriveError as e:
            sys.exit(f"\nCould not open or create '{name}' in My Drive: {e}")
    print(f"        {'Created' if created else 'Found'} the folder '{name}' in "
          f"{'your Drive' if args.into_id else 'My Drive'}", flush=True)
    log(f"root folder {root_id} '{name}' ({'created' if created else 'reused'})")
    failed, too_big = [], []
    if local is not None:
        pool = ThreadPoolExecutor(max_workers=WORKERS)
        try:
            try:
                tasks, skipped, too_big = plan(local, root_id, not created, pool)
            except DriveError as e:
                sys.exit(f"\nCould not set up the folders in Drive: {e}")
            total = skipped + len(tasks)
            done = skipped
            bar(done, total, "")
            futures = {pool.submit(upload_one, fid, full, nm, conv): (rel, conv) for fid, full, nm, conv, rel in tasks}
            for f in as_completed(futures):
                rel, conv = futures[f]
                try:
                    became = f.result()  # SystemExit (no Drive access) still stops everything
                    log(f"put   {rel}" + (" -> Google " + became.split(".")[-1].title() if became else ""))
                except DriveError as e:
                    failed.append((rel, str(e)))
                    log(f"FAIL  {rel}: {e}")
                done += 1
                bar(done, total, rel)
        except BaseException:
            pool.shutdown(wait=False, cancel_futures=True)
            raise
        pool.shutdown()
        sys.stdout.write("\n")
        n = len(tasks) - len(failed)
        print(f"        Uploaded {n} new file{'' if n == 1 else 's'}"
              + (f", {skipped} {'was' if skipped == 1 else 'were'} already there" if skipped else "") + f" ({time.time() - t0:.0f}s)", flush=True)
        for rel in too_big:
            print(f"        Skipped {rel}: bigger than {MAX_BYTES // 2 ** 20} MB", flush=True)
        for rel, why in failed:
            print(f"        Could not upload {rel}: {why}", flush=True)
        log(f"done: uploaded {n}, skipped {skipped}, too big {len(too_big)}, failed {len(failed)}, "
            f"{time.time() - t0:.0f}s with {WORKERS} at a time")
    if args.id_file:
        with open(args.id_file, "w") as fh:
            fh.write(root_id)
    else:
        print(f"ROOT_FOLDER_ID={root_id}")
    if failed:
        sys.exit(2)


if __name__ == "__main__":
    main()
PY_EOF
rm -f my_uploads_id.txt
UPLOAD_LOG="$LOG" QUOTA_PROJECT="$PROJECT" python3 drive_upload_lab.py "$LOCAL" my_uploads_id.txt "${INTO[@]}"
RC=$?
FOLDER_ID="$(cat my_uploads_id.txt 2>/dev/null)"
[ -n "$FOLDER_ID" ] || die "The upload stopped before it reached Google Drive (see above and $LOG)."
FOLDER_URL="https://drive.google.com/drive/folders/$FOLDER_ID"
{ grep -v '^MY_UPLOADS_FOLDER=' links.txt 2>/dev/null; printf 'MY_UPLOADS_FOLDER=%s\n' "$FOLDER_URL"; } > links.txt.new \
  && mv links.txt.new links.txt
if [ "$RC" = 0 ]; then
  ok "The $LABEL is ready in your Google Drive"
else
  warn "Some files could not be uploaded (listed above). Run $ME again to retry just those."
fi

# ---- 5. the My uploads data store (what your agent searches) -----------------------------------------------
# The Drive copy is for you to open; agents in the lab read the Google-hosted "My uploads" data store that the lab
# setup made. Supported there: PDF, Word, PowerPoint, Excel, HTML and text files.
step "Adding your files to the My uploads data store"
STORE="${UPLOADS_STORE:-graywing-uploads}"
DS_URL="https://discoveryengine.googleapis.com/v1alpha/projects/$PROJECT/locations/global/collections/default_collection/dataStores/$STORE"
TOK="$(gcloud auth print-access-token 2>/dev/null)"
GCODE=""; GBODY=""
gapi() {  # gapi METHOD URL [JSON] -> $GCODE = HTTP status, $GBODY = body (call it directly, not inside $( ))
  local out; out="$(mktemp)"
  GCODE="$(curl -s -o "$out" -w '%{http_code}' -X "$1" -H "Authorization: Bearer $TOK" -H "X-Goog-User-Project: $PROJECT" \
    -H "Content-Type: application/json" --max-time 120 ${3:+--data "$3"} "$2")"
  GBODY="$(cat "$out")"; log "API   $1 ${2#https://} -> $GCODE"; rm -f "$out"
}
if [ "$LOCAL" = "-" ]; then
  info "Nothing to add yet."
elif gapi GET "$DS_URL"; [ "$GCODE" != 200 ]; then
  warn "No \"My uploads\" data store in this project (the lab setup makes it). Your files are in Drive only."
else
  BUCKET="gs://$PROJECT-graywing-data"
  gcloud storage buckets describe "$BUCKET" >/dev/null 2>&1 \
    || gcloud storage buckets create "$BUCKET" --location=us --uniform-bucket-level-access >>"$LOG" 2>&1 \
    || die "Could not create the bucket $BUCKET (see $LOG)."
  STAGE="$(mktemp -d)"
  find "$LOCAL" -mindepth 1 -name '.*' -prune -o -type f \( -iname '*.pdf' -o -iname '*.docx' -o -iname '*.pptx' \
    -o -iname '*.xlsx' -o -iname '*.html' -o -iname '*.htm' -o -iname '*.txt' \) -print | while IFS= read -r f; do
    r="${f#"$LOCAL"/}"; cp "$f" "$STAGE/${r//\// - }"
  done
  N="$(find "$STAGE" -type f | wc -l | tr -d ' ')"
  SKIPPED=$(( COUNT - N ))
  if [ "$N" = 0 ]; then
    warn "None of your files are a type the data store can read (PDF, Word, PowerPoint, Excel, HTML, text)."
  else
    gcloud storage cp "$STAGE"/* "$BUCKET/uploads/" --quiet >>"$LOG" 2>&1 || die "Could not copy your files to $BUCKET (see $LOG)."
    gapi POST "$DS_URL/branches/default_branch/documents:import" \
      "{\"gcsSource\":{\"inputUris\":[\"$BUCKET/uploads/*\"],\"dataSchema\":\"content\"},\"reconciliationMode\":\"INCREMENTAL\"}"
    BODY="$GBODY"
    [ "$GCODE" = 200 ] || die "Could not start adding your files to the data store ($GCODE): $(printf '%s' "$BODY" | python3 -c 'import json,sys; print(json.load(sys.stdin)["error"]["message"])' 2>/dev/null)"
    OP="$(printf '%s' "$BODY" | python3 -c 'import json,sys; print(json.load(sys.stdin)["name"])')"
    DONE=""
    for _ in $(seq 60); do
      gapi GET "https://discoveryengine.googleapis.com/v1alpha/$OP"; BODY="$GBODY"
      DONE="$(printf '%s' "$BODY" | python3 -c 'import json,sys; d=json.load(sys.stdin); print("1" if d.get("done") else "")' 2>/dev/null)"
      [ -n "$DONE" ] && break; sleep 5
    done
    if [ -n "$DONE" ]; then
      ok "Added to the My uploads data store: $(printf '%s' "$BODY" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("metadata",{}).get("successCount","?"))') of $N file(s). Give it a few minutes to be searchable."
    else
      warn "Your files are still being added to the data store; they become searchable within a few minutes."
    fi
  fi
  [ "$SKIPPED" -gt 0 ] && info "$SKIPPED file(s) skipped for the data store (not PDF, Word, PowerPoint, Excel, HTML or text); they are in Drive."
  rm -rf "$STAGE"
fi

# ---- done ------------------------------------------------------------------------------------------------
log "######## upload-my-files finished in $(elapsed) (rc=$RC): $FOLDER_URL"
line="  ════════════════════════════════════════════════════════════════════════"
printf '\n\033[32m%s\033[0m\n' "$line"
printf '   \033[1mYOUR UPLOADS FOLDER IN GOOGLE DRIVE\033[0m  (a copy to open; your agent reads the My uploads data store)\n'
printf '   \033[4;36m%s\033[0m\n' "$FOLDER_URL"
printf '\033[32m%s\033[0m\n\n' "$line"
if [ "$LOCAL" = "-" ]; then
  printf '   \033[1mTo upload from Cloud Shell:\033[0m\n'
  printf '   1. Click the \033[1m⋮\033[0m menu at the top right of this terminal, then \033[1mUpload\033[0m, and pick your files.\n'
  printf '   2. Set the destination to \033[1m%s\033[0m (if they landed in your home folder: mv ~/FILENAME %s/).\n' "$SRC" "$SRC"
  printf '   3. Run \033[1m%s\033[0m again.\n\n' "$ME"
  printf '   \033[2mFor a one-off question you can also attach a file straight in the chat.\033[0m\n\n'
else
  printf '   Next: in your Chief of Staff agent, add the \033[1mMy uploads\033[0m data store as a data source,\n'
  printf '   then tell it: Also use the files in My uploads.\n\n'
fi
printf '   \033[2mLinks saved in %s · full log in %s\033[0m\n\n' "$WORK/links.txt" "$LOG"
exit "$RC"
