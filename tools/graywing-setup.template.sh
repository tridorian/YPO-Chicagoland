#!/usr/bin/env bash
# Graywing Ag Systems - Gemini Enterprise lab setup. Run in Cloud Shell of a fresh Qwiklabs project.
# Steps: project -> APIs -> find the lab's Gemini Enterprise app -> connect Google Drive, Gmail and Google Calendar
# (search + actions) -> turn on app features, all models and Google Search -> Drive access check ->
# install the upload-my-files command -> copy the demo data into your My Drive (emails and calendars are simulated
# as files there) and make an empty "My Uploads" folder -> wait for the connectors, print your links.
# Safe to re-run: every step reuses earlier work and only changes what is missing.
# Everything is logged with timestamps to ~/graywing-lab/setup.log.
set -uo pipefail

# ---- settings -------------------------------------------------------------------------------------------
DATA_URL="${DATA_URL:-https://raw.githubusercontent.com/tridorian/graywing-ge-lab/main/graywing-demo-data.zip}"          # gs://... or https://... zip of "Graywing Ag Systems (Demo Data)"
LOCATION="${GE_LOCATION:-global}"            # Gemini Enterprise location: global | us | eu
APP_ID="${APP_ID:-}"                         # app to use; empty = the lab's existing app (first one found)
NEW_APP_ID="${NEW_APP_ID:-graywing-ag-systems}"   # only used when the project has no app yet
APP_NAME="${APP_NAME:-Graywing Ag Systems}"       # display name for a new app only; an existing app keeps its name
COMPANY="${COMPANY:-Graywing Ag Systems}"
CONNECTOR_PREFIX="${CONNECTOR_PREFIX:-graywing}"  # connector ids: graywing-drive, graywing-gmail, graywing-calendar
MY_UPLOADS="${MY_UPLOADS_FOLDER:-My Uploads}"     # empty My Drive folder for your own files (see upload-my-files)
WORK="${WORK:-$HOME/graywing-lab}"
# Feature Management switches (key:ON|OFF). Merged into the app's existing settings; unknown keys are skipped.
FEATURES_WANT="no-code-agent-builder:ON agent-gallery:ON prompt-gallery:ON notebook-lm:ON model-selector:ON
  workflow-agents:ON multi-agent-orchestration:ON personalization-memory:ON disable-canvas:OFF canvas-app-builder:ON
  disable-image-generation:OFF disable-video-generation:OFF disable-google-drive-upload:OFF disable-talk-to-content:OFF"
# ---------------------------------------------------------------------------------------------------------

mkdir -p "$WORK" || { echo "Can't create $WORK"; exit 1; }
LOG="$WORK/setup.log"
STEPS=9
STEP=0
T0=$SECONDS

ts() { date '+%H:%M:%S'; }
elapsed() { local s=$(( SECONDS - T0 )); printf '%d:%02d' $(( s / 60 )) $(( s % 60 )); }
log() { printf '%s  %s\n' "$(ts)" "$*" >> "$LOG"; }
step() {
  STEP=$(( STEP + 1 ))
  printf '\n\033[1;36m[%d/%d]\033[0m \033[1m%s\033[0m  \033[2m(%s elapsed)\033[0m\n' "$STEP" "$STEPS" "$*" "$(elapsed)"
  log "== STEP $STEP/$STEPS: $*"
}
ok() { printf '      \033[32m✔\033[0m %s\n' "$*"; log "OK    $*"; }
info() { printf '        %s\n' "$*"; log "      $*"; }
warn() { printf '      \033[33m!\033[0m %s\n' "$*"; log "WARN  $*"; }
die() {
  printf '\r\033[K\n      \033[31m✘ %s\033[0m\n\n' "$*"
  printf '      Stopped at step %d of %d after %s. Full log: %s\n' "$STEP" "$STEPS" "$(elapsed)" "$LOG"
  printf '      Fix the problem above (or just wait a minute), then paste the script again; it picks up where it left off.\n\n'
  log "FAIL  $*"
  exit 1
}
# spin "message" command...  -> runs the command with a live spinner + seconds counter; output goes to the log
spin() {
  local msg="$1"; shift
  log "RUN   $*"
  "$@" >> "$LOG" 2>&1 &
  local pid=$! i=0 start=$SECONDS frames=('|' '/' '-' '\')
  while kill -0 "$pid" 2>/dev/null; do
    printf '\r      \033[36m%s\033[0m %s \033[2m%ss\033[0m ' "${frames[i++ % 4]}" "$msg" $(( SECONDS - start ))
    sleep 0.2
  done
  wait "$pid"; local rc=$?
  printf '\r\033[K'
  return $rc
}

case "$LOCATION" in
  global) HOST="https://discoveryengine.googleapis.com" ;;
  *) HOST="https://${LOCATION}-discoveryengine.googleapis.com" ;;
esac

printf '\n\033[1m  Graywing Ag Systems · Gemini Enterprise lab setup\033[0m\n'
printf '  \033[2mTakes 5-15 minutes (new connectors can take up to 10 to start). Full log: %s\033[0m\n' "$LOG"
log "######## setup started (DATA_URL=$DATA_URL LOCATION=$LOCATION APP_ID=${APP_ID:-auto})"

# ---- 1. project and account ------------------------------------------------------------------------------
step "Checking your lab project and sign-in"
for t in python3 curl unzip; do command -v "$t" >/dev/null || die "This needs $t, which Cloud Shell normally has. Run it in Cloud Shell."; done
PROJECT="${GOOGLE_CLOUD_PROJECT:-$(gcloud config get-value project 2>/dev/null)}"
if [ -z "$PROJECT" ] || [ "$PROJECT" = "(unset)" ]; then
  PROJECT="$(gcloud projects list --format='value(projectId)' --filter='projectId:qwiklabs-gcp-*' --limit=1 2>/dev/null)"
fi
[ -n "$PROJECT" ] || die "No project found. In the console, pick the lab project at the top, then paste the script again."
gcloud config set project "$PROJECT" >> "$LOG" 2>&1
ACCOUNT="$(gcloud config get-value account 2>/dev/null)"
PROJECT_NUMBER="$(gcloud projects describe "$PROJECT" --format='value(projectNumber)' 2>>"$LOG")"
[ -n "$PROJECT_NUMBER" ] || die "Can't read project $PROJECT as $ACCOUNT. If Cloud Shell asked to authorize, click Authorize and paste again."
ok "Project  $PROJECT"
ok "Account  $ACCOUNT"

# ---- 2. APIs ---------------------------------------------------------------------------------------------
step "Turning on the Google Cloud APIs"
spin "Enabling Gemini Enterprise (Discovery Engine), Google Drive and Cloud Storage APIs" \
  gcloud services enable discoveryengine.googleapis.com drive.googleapis.com storage.googleapis.com --project "$PROJECT" \
  || die "Could not enable the APIs (see $LOG)."
ok "APIs enabled: Discovery Engine, Google Drive, Cloud Storage"

# ---- 3. Gemini Enterprise app ----------------------------------------------------------------------------
step "Finding your Gemini Enterprise app"
BASE="$HOST/v1alpha/projects/$PROJECT/locations/$LOCATION"
BASE_V1="$HOST/v1/projects/$PROJECT/locations/$LOCATION"
# connector resources answer only to the project number (the project id gives "Invalid data connector name")
NBASE="$HOST/v1alpha/projects/$PROJECT_NUMBER/locations/$LOCATION"

api() {  # api METHOD URL [JSON]  -> $CODE (HTTP status) and $BODY; every call is logged
  local out; out="$(mktemp)"
  local args=(-s -o "$out" -w '%{http_code}' -X "$1" -H "Authorization: Bearer $(gcloud auth print-access-token 2>/dev/null)"
              -H "X-Goog-User-Project: $PROJECT" -H "Content-Type: application/json" --max-time 120)
  [ -n "${3:-}" ] && args+=(--data "$3")
  CODE="$(curl "${args[@]}" "$2")"; BODY="$(cat "$out")"; rm -f "$out"
  log "API   $1 ${2#https://} -> $CODE"
  case "$CODE" in 2*) ;; *) log "      ${BODY:0:600}" ;; esac
}
jv() {  # jv 'python expression on d' [JSON] -> prints it from JSON (default $BODY; '' when missing)
  printf '%s' "${2-$BODY}" | python3 -c 'import json,sys
try: d=json.loads(sys.stdin.read() or "{}")
except Exception: d={}
try: v=eval(sys.argv[1])
except Exception: v=""
print("" if v is None else v)' "$1"
}
err() { jv 'd["error"]["message"]'; }
wait_op() {  # wait_op OPERATION_NAME  (up to 5 minutes)
  for _ in $(seq 100); do
    api GET "$HOST/v1alpha/$1"
    [ "$(jv 'd.get("done", False)')" = "True" ] && { [ -z "$(jv 'd.get("error","")')" ] && return 0 || return 1; }
    sleep 3
  done
  return 1
}

# 3a. Google identity for this location (the console's "Use Google Identity"); the lab usually has it already
api GET "$BASE/aclConfig"
if [ "$(jv 'd["idpConfig"]["idpType"]')" != "GSUITE" ]; then
  api PATCH "$BASE/aclConfig" "{\"name\":\"projects/$PROJECT/locations/$LOCATION/aclConfig\",\"idpConfig\":{\"idpType\":\"GSUITE\"}}"
  [ "$CODE" = 200 ] || die "Could not set Google identity ($CODE): $(err)"
fi
ok "Sign-in method: Google Identity"

# 3b. Seats: the lab's trial must be active; new users get a seat automatically
api GET "$BASE_V1/licenseConfigs"
LICENSE="$(jv '[c["name"] for c in d.get("licenseConfigs",[]) if c.get("state")=="ACTIVE"][0]')"
if [ -z "$LICENSE" ]; then
  warn "No active Gemini Enterprise subscription in $LOCATION yet."
  info "Open https://console.cloud.google.com/gemini-enterprise/overview?project=$PROJECT"
  info "click 'Start 30-day free trial' (and 'Continue and activate the API' if shown), then come back."
  read -r -p "        Press Enter when that's done... " _ </dev/tty
  api GET "$BASE_V1/licenseConfigs"
  LICENSE="$(jv '[c["name"] for c in d.get("licenseConfigs",[]) if c.get("state")=="ACTIVE"][0]')"
  [ -n "$LICENSE" ] || die "Still no active subscription in $LOCATION."
fi
api GET "$BASE_V1/userStores/default_user_store"
if [ "$(jv 'd.get("enableLicenseAutoRegister", False)')" != "True" ]; then
  api PATCH "$BASE_V1/userStores/default_user_store?updateMask=enableLicenseAutoRegister,defaultLicenseConfig" \
    "{\"enableLicenseAutoRegister\":true,\"defaultLicenseConfig\":\"$LICENSE\"}"
  [ "$CODE" = 200 ] || warn "Could not turn on automatic seats ($CODE); assign one under Gemini Enterprise > Manage users."
fi
ok "License: $(basename "$LICENSE") (a seat is given automatically on first sign-in)"

# 3c. The app: $APP_ID if it exists, else the first Gemini Enterprise (intranet) app; made in step 4 if there is none
api GET "$BASE/collections/default_collection/engines?pageSize=100"
[ "$CODE" = 200 ] || die "Could not list the Gemini Enterprise apps ($CODE): $(err)"
FOUND="$(WANT="$APP_ID" jv '([e["name"].split("/")[-1] for e in d.get("engines",[]) if e["name"].split("/")[-1]==__import__("os").environ["WANT"]]
  + [e["name"].split("/")[-1] for e in d.get("engines",[]) if e.get("appType")=="APP_TYPE_INTRANET"] + [""])[0]')"
[ -n "$APP_ID" ] && [ -n "$FOUND" ] && [ "$FOUND" != "$APP_ID" ] && warn "No app called $APP_ID here; using $FOUND instead."
NEW_APP=""
if [ -n "$FOUND" ]; then
  APP_ID="$FOUND"
  ENGINE="$BASE/collections/default_collection/engines/$APP_ID"
  api GET "$ENGINE"
  [ "$CODE" = 200 ] || die "Could not read the app $APP_ID ($CODE): $(err)"
  APP_TITLE="$(jv 'd.get("displayName","")')"
  ok "App: ${APP_TITLE:-$APP_ID} (id $APP_ID)"
else
  APP_ID="${APP_ID:-$NEW_APP_ID}"; NEW_APP=1; APP_TITLE="$APP_NAME"
  ENGINE="$BASE/collections/default_collection/engines/$APP_ID"
  info "No Gemini Enterprise app in this project yet; one called \"$APP_NAME\" is made in the next step."
fi

# ---- 4. connectors ---------------------------------------------------------------------------------------
step "Connecting Google Drive, Gmail and Google Calendar"
# Federated (each person's own Drive, mail and calendar are searched live; nothing is copied) plus actions
# (create files, send or draft email, add events). Google runs the sign-in: each user clicks Authorize once in the app.
CONNECTORS=("google_drive|$CONNECTOR_PREFIX-drive|Google Drive" "google_mail|$CONNECTOR_PREFIX-gmail|Gmail"
            "google_calendar|$CONNECTOR_PREFIX-calendar|Google Calendar")
body() {  # body MODES_JSON -> setUpDataConnector request for $SRC_NAME / $CID / $CNAME
  printf '{"collectionId":"%s","collectionDisplayName":"%s","dataConnector":{"dataSource":"%s","refreshInterval":"0s","connectorModes":%s,"entities":[{"entityName":"%s"}],"params":{}}}' \
    "$CID" "$CNAME" "$SRC_NAME" "$1" "$SRC_NAME"
}
CIDS=(); DS_IDS=(); NO_ACTIONS=()
for c in "${CONNECTORS[@]}"; do
  IFS='|' read -r SRC_NAME CID CNAME <<<"$c"
  CIDS+=("$CID")
  url="$NBASE/collections/$CID/dataConnector"
  api GET "$url"
  if [ "$CODE" = 404 ]; then
    api POST "$BASE:setUpDataConnector" "$(body '["FEDERATED","ACTIONS"]')"
    if [ "$CODE" != 200 ]; then
      log "connector with actions refused; trying search only"
      api POST "$BASE:setUpDataConnector" "$(body '["FEDERATED"]')"
      [ "$CODE" = 200 ] || die "Could not create the $CNAME connector ($CODE): $(err)"
      NO_ACTIONS+=("$CNAME")
    fi
    for _ in $(seq 20); do api GET "$url"; [ -n "$(jv 'd["entities"][0]["dataStore"]')" ] && break; sleep 3; done
    ok "$CNAME connector created ($(jv 'd.get("state","starting")' | tr 'A-Z' 'a-z'); it finishes starting in the background)"
  elif [ "$CODE" = 200 ]; then
    if [ "$(jv '"ACTIONS" in d.get("connectorModes",[])')" != "True" ]; then
      api PATCH "$url?updateMask=connectorModes" '{"connectorModes":["FEDERATED","ACTIONS"]}'
      if [ "$CODE" = 200 ]; then api GET "$url"; else NO_ACTIONS+=("$CNAME"); fi
    fi
    ok "$CNAME connector: $(jv 'd.get("state","")' | tr 'A-Z' 'a-z')"
  else
    die "Could not read the $CNAME connector ($CODE): $(err)"
  fi
  DS="$(jv 'd["entities"][0]["dataStore"].split("/")[-1]')"
  [ -n "$DS" ] || die "The $CNAME connector has no data store yet. Paste the script again in a minute."
  DS_IDS+=("$DS")
done
DS_JSON="$(printf '%s\n' "${DS_IDS[@]}" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().split()))')"
for n in "${NO_ACTIONS[@]}"; do
  warn "$n: actions could not be switched on here (search works). To add them in the console: Gemini Enterprise >"
  info "Data stores > $n > Actions > Enable actions > tick the actions > Enable actions."
done

attach() {  # adds the connectors' data stores to the app, keeping anything already there
  ATTACHED=""; ATTACH_MSG="Connectors already in"   # ATTACHED=1 on success
  api GET "$ENGINE"
  [ "$CODE" = 200 ] || return 1
  local have ids
  have="$(jv 'json.dumps(d.get("dataStoreIds", []))' | sed 's/^$/[]/')"
  ids="$(jv "json.dumps(d.get('dataStoreIds', []) + [x for x in $DS_JSON if x not in d.get('dataStoreIds', [])])")"
  [ "$ids" = "$have" ] && { ATTACHED=1; return 0; }
  api PATCH "$ENGINE?updateMask=dataStoreIds" "{\"dataStoreIds\":$ids}"
  [ "$CODE" = 200 ] && { ATTACHED=1; ATTACH_MSG="Connectors added to"; }
}
if [ -n "$NEW_APP" ]; then
  api POST "$BASE/collections/default_collection/engines?engineId=$APP_ID" "{
    \"displayName\":\"$APP_NAME\",\"solutionType\":\"SOLUTION_TYPE_SEARCH\",\"industryVertical\":\"GENERIC\",
    \"appType\":\"APP_TYPE_INTRANET\",\"dataStoreIds\":$DS_JSON,\"commonConfig\":{\"companyName\":\"$COMPANY\"},
    \"searchEngineConfig\":{\"searchTier\":\"SEARCH_TIER_ENTERPRISE\",\"searchAddOns\":[\"SEARCH_ADD_ON_LLM\"],
      \"requiredSubscriptionTier\":\"SUBSCRIPTION_TIER_SEARCH_AND_ASSISTANT\"},
    \"knowledgeGraphConfig\":{\"enablePrivateKnowledgeGraph\":true},
    \"sessionConfig\":{\"sessionManagementPolicy\":\"VERTEX_AI_MANAGED\"},
    \"observabilityConfig\":{\"observabilityEnabled\":true}}"
  [ "$CODE" = 200 ] || die "Could not create the app ($CODE): $(err)"
  OP="$(jv 'd["name"]')"
  if [ "$(jv 'd.get("done", False)')" != "True" ]; then
    spin "Creating the app" wait_op "$OP" || die "App creation did not finish (see $LOG)."
  fi
  ok "App created: $APP_NAME (Google Drive, Gmail and Google Calendar connected)"
  ATTACHED=1
else
  attach
  if [ -n "$ATTACHED" ]; then
    ok "$ATTACH_MSG ${APP_TITLE:-$APP_ID}"
  else
    info "The app doesn't take the new connectors yet; trying again once they are active (last step)."
  fi
fi
if [ "${#NO_ACTIONS[@]}" = 0 ]; then
  info "Actions (create files, send or draft email, add events) are switched on. To review or pick them:"
  info "console > Gemini Enterprise > Data stores > (Google Drive / Gmail / Google Calendar) > Actions."
fi

# ---- 5. features, models, Google Search ------------------------------------------------------------------
step "Turning on the app's features, models and Google Search"
TURNED_ON=()
# 5a. Feature Management. updateMask=features replaces the whole map, so merge into what is there.
#     Keys are checked against the API's published list (unknown keys are accepted silently, so we skip them).
api GET "$ENGINE"
[ "$CODE" = 200 ] || die "Could not read the app ($CODE): $(err)"
ENGINE_JSON="$BODY"
curl -s --max-time 60 "https://discoveryengine.googleapis.com/\$discovery/rest?version=v1alpha" -o "$WORK/.discovery.json" 2>>"$LOG"
MERGE="$(printf '%s' "$ENGINE_JSON" | python3 -c 'import json,re,sys
eng = json.loads(sys.stdin.read() or "{}")
try:
    with open(sys.argv[1], encoding="utf-8") as fh:
        desc = json.load(fh)["schemas"]["GoogleCloudDiscoveryengineV1alphaEngine"]["properties"]["features"]["description"]
    known = set(re.findall(r"`([a-z0-9-]+)`", desc))
except Exception:
    known = set()
have = eng.get("features") or {}
want = dict(x.split(":") for x in sys.argv[2].split())
dropped = sorted(k for k in want if known and k not in known)
merged = dict(have)
merged.update({k: "FEATURE_STATE_" + v for k, v in want.items() if k not in dropped})
print(json.dumps({"dropped": dropped, "checked": bool(known), "changed": merged != have, "features": merged}))' \
  "$WORK/.discovery.json" "$FEATURES_WANT")"
[ -n "$MERGE" ] || die "Could not work out the feature settings (see $LOG)."
[ "$(jv 'd["checked"]' "$MERGE")" = True ] || warn "Could not load the list of feature names; setting them all as given."
for k in $(jv '" ".join(d["dropped"])' "$MERGE"); do warn "Skipped feature '$k': this API version doesn't know it."; done
if [ "$(jv 'd["changed"]' "$MERGE")" = True ]; then
  api PATCH "$ENGINE?updateMask=features" "$(jv 'json.dumps({"features": d["features"]})' "$MERGE")"
  [ "$CODE" = 200 ] || die "Could not update the app's features ($CODE): $(err)"
  api GET "$ENGINE"
fi
MISSING="$(WANT="$(jv 'json.dumps(d["features"])' "$MERGE")" jv '" ".join(k for k, v in json.loads(__import__("os").environ["WANT"]).items() if (d.get("features") or {}).get(k) != v)')"
if [ -z "$MISSING" ]; then
  ok "Features on: agent designer (no-code agents + workflows, multi-agent), agent and prompt gallery, model selector,"
  info "  Canvas and its app builder, image and video generation, NotebookLM, memory, Drive upload, talk to content"
  TURNED_ON+=("no-code agents" "Canvas" "image and video generation")
else
  warn "These features did not stick: $MISSING (set them under Configurations > Feature Management)."
fi

# 5b. Models: every model an admin may switch (read from the console's own admin view) -> enabled on the app
api GET "$ENGINE/widgetConfigs/default_search_widget_config?modelInfoView=ADMIN"
[ "$CODE" = 200 ] || die "Could not read the app's settings ($CODE): $(err)"
CONFIG_ID="$(jv 'd["configId"]')"
MODELS="$(jv '" ".join(m["modelId"] for m in d.get("uiSettings",{}).get("modelConfigInfo",{}).get("resolvedModels",[]) if m.get("modelId") and m.get("adminView",{}).get("adminOverridable"))')"
set_models() {  # set_models "id id ..." -> merges MODEL_ENABLED for them into the app's modelConfigs
  api GET "$ENGINE"
  local cfg; cfg="$(WANT="$1" jv 'json.dumps({"modelConfigs": dict(d.get("modelConfigs") or {}, **{m: "MODEL_ENABLED" for m in __import__("os").environ["WANT"].split()})})')"
  [ "$(jv 'json.dumps(d.get("modelConfigs") or {}, sort_keys=True)')" = "$(jv 'json.dumps(d["modelConfigs"], sort_keys=True)' "$cfg")" ] && return 0
  api PATCH "$ENGINE?updateMask=modelConfigs" "$cfg"
  [ "$CODE" = 200 ]
}
if [ -z "$MODELS" ]; then
  warn "Could not read the list of models; turn them on under Configurations > Feature Management."
else
  if ! set_models "$MODELS"; then
    warn "The app refused some models ($CODE: $(err)); trying again without the Claude models."
    set_models "$(printf '%s\n' $MODELS | grep -v '^claude' | tr '\n' ' ')" || warn "Could not turn on the models ($CODE): $(err)"
  fi
  api GET "$ENGINE"
  ON="$(WANT="$MODELS" jv '" ".join(m for m in __import__("os").environ["WANT"].split() if (d.get("modelConfigs") or {}).get(m) == "MODEL_ENABLED")')"
  OFF="$(WANT="$MODELS" jv '" ".join(m for m in __import__("os").environ["WANT"].split() if (d.get("modelConfigs") or {}).get(m) != "MODEL_ENABLED")')"
  ok "Models on ($(wc -w <<<"$ON" | tr -d ' ')): $ON"
  [ -n "$OFF" ] && warn "Models not switched on: $OFF"
  TURNED_ON+=("$(wc -w <<<"$ON" | tr -d ' ') models")
  CLAUDE="$(printf '%s\n' $ON | grep '^claude' | head -1)"
  if [ -n "$CLAUDE" ]; then  # one tiny test question tells whether Claude can answer yet (it needs pay-as-you-go)
    api POST "$ENGINE/assistants/default_assistant:streamAssist" \
      "{\"query\":{\"text\":\"Reply with the single word OK.\"},\"generationSpec\":{\"modelId\":\"$CLAUDE\"}}"
    if [ "$CODE" = 200 ]; then
      ok "Claude models answer (pay-as-you-go is on for this project)"
      TURNED_ON+=("Claude")
    else
      case "$BODY" in *OVERAGE*) why="it needs pay-as-you-go usage, which this lab's trial doesn't include" ;;
        *) why="$(err)" ;; esac
      warn "Claude models are switched on but can't answer yet: $why."
      TURNED_ON[${#TURNED_ON[@]}-1]+=" (Claude needs pay-as-you-go)"
      info "If your project has billing: console > Gemini Enterprise > Apps > ${APP_TITLE:-$APP_ID} > Configurations >"
      info "Feature Management > Enable third-party models > switch Claude on > Go to Usage & spend (turn on pay-as-you-go)"
      info "> Agree to the terms > Save. The Gemini models work without this."
    fi
  fi
fi

# 5c. Google Search grounding on (answers can use the web as well as your files)
api GET "$ENGINE/assistants/default_assistant"
if [ "$(jv 'd.get("webGroundingType","")')" != "WEB_GROUNDING_TYPE_GOOGLE_SEARCH" ]; then
  api PATCH "$ENGINE/assistants/default_assistant?updateMask=webGroundingType" '{"webGroundingType":"WEB_GROUNDING_TYPE_GOOGLE_SEARCH"}'
fi
if [ "$(jv 'd.get("webGroundingType","")')" = "WEB_GROUNDING_TYPE_GOOGLE_SEARCH" ]; then
  ok "Google Search: on"
  TURNED_ON=("Google Search" "${TURNED_ON[@]}")
else
  warn "Could not turn on Google Search ($CODE): $(err). Turn it on under Configurations > Assistant."
fi

[ -n "$CONFIG_ID" ] || die "Could not read the app's web address."
case "$LOCATION" in global) WEB_URL="https://vertexaisearch.cloud.google.com/home/cid/$CONFIG_ID" ;;
  *) WEB_URL="https://vertexaisearch.cloud.google.com/$LOCATION/home/cid/$CONFIG_ID" ;; esac
CONSOLE_URL="https://console.cloud.google.com/gemini-enterprise/locations/$LOCATION/engines/$APP_ID/overview?project=$PROJECT"
ok "App link: $WEB_URL"

# ---- 6. Drive access -------------------------------------------------------------------------------------
step "Checking Google Drive access"
has_drive_scope() {
  local t; t="$(gcloud auth print-access-token 2>/dev/null)" || return 1
  curl -s "https://oauth2.googleapis.com/tokeninfo?access_token=$t" | grep -q 'auth/drive'
}
if has_drive_scope; then
  ok "This sign-in can already write to your Google Drive"
else
  log "token has no Drive scope -> gcloud auth login --enable-gdrive-access"
  printf '      \033[33mAction needed (once):\033[0m Cloud Shell needs your OK to put files in your Google Drive.\n'
  info "1. If asked \"Do you wish to proceed anyway (Y/n)?\", type Y and press Enter."
  info "2. Open the long link it prints, sign in as $ACCOUNT, and click Allow."
  info "3. Copy the code Google shows, paste it here, and press Enter."
  echo
  gcloud auth login "$ACCOUNT" --enable-gdrive-access --no-launch-browser --force --brief \
    || die "Drive sign-in did not finish. Paste the script again to retry."
  has_drive_scope || die "The new sign-in still has no Drive access. Make sure you clicked Allow."
  ok "Google Drive access approved"
fi

# ---- 7. upload-my-files command --------------------------------------------------------------------------
step "Installing the upload-my-files command"
# A verbatim copy of setup/upload-my-files.sh from the lab repo; its Drive uploader is also used for the demo data below.
mkdir -p "$HOME/bin" || die "Can't create $HOME/bin"
cat > "$HOME/bin/upload-my-files" <<'UPLOAD_MY_FILES_EOF'
@@UPLOAD_MY_FILES@@
UPLOAD_MY_FILES_EOF
chmod +x "$HOME/bin/upload-my-files"
grep -qs 'graywing lab: upload-my-files' "$HOME/.bashrc" \
  || printf '\n# graywing lab: upload-my-files\nexport PATH="$HOME/bin:$PATH"\n' >> "$HOME/.bashrc"
ok "Installed: upload-my-files (copies ~/my-files into \"$MY_UPLOADS\" in your Drive)"

# ---- 8. demo data and My Uploads in My Drive -------------------------------------------------------------
step "Copying the Graywing demo data into your Google Drive"
cd "$WORK" || die "Can't open $WORK"
awk '/^PY_EOF$/{p=0} p{print} /<<.PY_EOF.$/{p=1}' "$HOME/bin/upload-my-files" > drive_upload_lab.py
[ -s drive_upload_lab.py ] || die "Could not set up the Drive uploader."
rm -f data.zip
case "$DATA_URL" in
  gs://*) spin "Downloading the demo data" gcloud storage cp "$DATA_URL" data.zip --quiet ;;
  *) spin "Downloading the demo data" curl -fsSL "$DATA_URL" -o data.zip ;;
esac
[ -s data.zip ] || die "Could not download the demo data from $DATA_URL"
rm -rf data && mkdir data && unzip -q data.zip -d data || die "The demo data zip is damaged."
DATA_DIR="$(find data -mindepth 1 -maxdepth 1 -type d | head -1)"
ok "Downloaded $(find "$DATA_DIR" -type f | wc -l | tr -d ' ') files ($(du -sh data.zip | cut -f1))"
rm -f folder_id.txt
UPLOAD_LOG="$LOG" QUOTA_PROJECT="$PROJECT" python3 drive_upload_lab.py "$DATA_DIR" folder_id.txt
RC=$?
FOLDER_ID="$(cat folder_id.txt 2>/dev/null)"
[ -n "$FOLDER_ID" ] || die "Drive upload stopped (see above and $LOG)."
[ "$RC" = 0 ] || warn "Some files could not be uploaded (listed above). Paste the script again to retry just those."
DRIVE_URL="https://drive.google.com/drive/folders/$FOLDER_ID"
ok "Demo data folder: $DRIVE_URL"

INTO=(--into "$MY_UPLOADS")
case "$MY_UPLOADS" in
  *drive.google.com/*folders/*) FID="${MY_UPLOADS##*folders/}"; INTO=(--into-id "${FID%%[?/#]*}") ;;
  id:*) INTO=(--into-id "${MY_UPLOADS#id:}") ;;
esac
rm -f my_uploads_id.txt
UPLOAD_LOG="$LOG" QUOTA_PROJECT="$PROJECT" python3 drive_upload_lab.py - my_uploads_id.txt "${INTO[@]}"
UPLOADS_ID="$(cat my_uploads_id.txt 2>/dev/null)"
if [ -n "$UPLOADS_ID" ]; then
  UPLOADS_URL="https://drive.google.com/drive/folders/$UPLOADS_ID"
  ok "My Uploads folder: $UPLOADS_URL"
else
  UPLOADS_URL=""
  warn "Could not make the \"$MY_UPLOADS\" folder (see $LOG); upload-my-files makes it later."
fi

# ---- 9. connectors active, links -------------------------------------------------------------------------
step "Finishing up"
connectors_ready() {  # 0 = all active, 1 = still starting, 3 = one failed
  local cid rc=0
  for cid in "${CIDS[@]}"; do
    api GET "$NBASE/collections/$cid/dataConnector"
    case "$(jv 'd.get("state","")')" in
      ACTIVE) ;;
      FAILED|INITIALIZATION_FAILED) return 3 ;;
      *) rc=1 ;;
    esac
    case "$(jv 'd.get("actionState","")')" in CREATING|UPDATING|RUNNING) rc=1 ;; esac
  done
  return $rc
}
wait_connectors() { for _ in $(seq 150); do connectors_ready; case $? in 0) return 0 ;; 3) return 3 ;; esac; sleep 5; done; return 1; }
if ! connectors_ready; then
  spin "Waiting for the new connectors to start (usually about 10 minutes from when they were made)" wait_connectors
fi
for c in "${CONNECTORS[@]}"; do
  IFS='|' read -r _ CID CNAME <<<"$c"
  api GET "$NBASE/collections/$CID/dataConnector"
  ST="$(jv 'd.get("state","")')"; AST="$(jv 'd.get("actionState","")')"
  if [ "$ST" = ACTIVE ]; then
    ok "$CNAME connector: active$([ "$AST" = ACTIVE ] && echo ', actions active')"
  elif [ "$ST" = FAILED ] || [ "$ST" = INITIALIZATION_FAILED ]; then
    warn "$CNAME connector failed: $(jv 'd.get("errors","")'). Delete it under Gemini Enterprise > Data stores and paste the script again."
  else
    warn "$CNAME connector is still starting (${ST:-unknown}); it finishes on its own. Authorize it in the app once it shows."
  fi
done
if [ -z "${ATTACHED:-}" ]; then
  attach
  if [ -n "$ATTACHED" ]; then ok "$ATTACH_MSG ${APP_TITLE:-$APP_ID}"
  else warn "Could not add the connectors to the app yet ($CODE): $(err). Paste the script again in a few minutes."; fi
fi
{
  printf 'GEMINI_ENTERPRISE_APP=%s\n' "$WEB_URL"
  printf 'ADMIN_CONSOLE=%s\n' "$CONSOLE_URL"
  printf 'DEMO_DATA_DRIVE_FOLDER=%s\n' "$DRIVE_URL"
  [ -n "$UPLOADS_URL" ] && printf 'MY_UPLOADS_FOLDER=%s\n' "$UPLOADS_URL"
} > "$WORK/links.txt"
rm -f "$WORK/.discovery.json"
log "######## setup finished in $(elapsed): app=$WEB_URL drive=$DRIVE_URL uploads=$UPLOADS_URL"

line="  ════════════════════════════════════════════════════════════════════════"
printf '\n\033[32m%s\033[0m\n' "$line"
printf '\033[1;32m   ✔ Setup complete in %s\033[0m\n\n' "$(elapsed)"
printf '   \033[1mYOUR GEMINI ENTERPRISE APP\033[0m  (%s · open this and bookmark it)\n' "${APP_TITLE:-$APP_ID}"
printf '   \033[4;36m%s\033[0m\n\n' "$WEB_URL"
printf '   \033[1mGRAYWING DEMO DATA IN YOUR GOOGLE DRIVE\033[0m\n'
printf '   \033[4;36m%s\033[0m\n\n' "$DRIVE_URL"
if [ -n "$UPLOADS_URL" ]; then
  printf '   \033[1mMY UPLOADS\033[0m  (your own files: drag them in, or run upload-my-files)\n'
  printf '   \033[4;36m%s\033[0m\n\n' "$UPLOADS_URL"
fi
if [ "${#TURNED_ON[@]}" -gt 0 ]; then
  printf '   \033[1mTurned on:\033[0m %s\n' "$(printf '%s, ' "${TURNED_ON[@]}" | sed 's/, $//')"
  printf '   \033[1mConnected:\033[0m Google Drive, Gmail, Google Calendar (search + actions)\n\n'
fi
printf '   \033[2mAdmin console: %s\033[0m\n' "$CONSOLE_URL"
printf '   \033[2mLinks saved in %s · full log in %s\033[0m\n' "$WORK/links.txt" "$LOG"
printf '\033[32m%s\033[0m\n\n' "$line"
printf '   \033[1mNext (once):\033[0m\n'
printf '   1. Open the app link above (signed in as %s).\n' "$ACCOUNT"
printf '   2. Click \033[1mConnectors\033[0m and \033[1mAuthorize\033[0m Google Drive, Gmail and Google Calendar.\n'
printf '   3. Ask: "What does Graywing Ag Systems sell, and who are its biggest customers?"\n\n'
printf '   Your own files: put them in ~/my-files, then run \033[1mupload-my-files\033[0m (new terminal tabs find it;\n'
printf '   in this one, run  export PATH="$HOME/bin:$PATH"  first).\n'
printf '   Show the links again any time with:  cat %s\n\n' "$WORK/links.txt"
