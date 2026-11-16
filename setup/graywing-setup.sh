#!/usr/bin/env bash
# Graywing Ag Systems - Gemini Enterprise lab setup. Run in Cloud Shell of a fresh Qwiklabs project.
# Steps: project -> APIs -> find the lab's Gemini Enterprise app -> connect Google Drive (search; WITH_ACTIONS=1 adds
# Gmail, Calendar and actions) -> turn on app features, the models the lab can use and Google Search -> Drive check ->
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

# ---- 4. data stores (default) or connectors (WITH_ACTIONS=1) ----------------------------------------------
# Default: no connectors. In the Qwiklabs lab people can't authorize connectors ("Data connector is not ready
# yet"), and a no-code agent can't read Drive without that. So the demo data goes into a Google-hosted data store
# in this project (step 8), which every user of the app can search with no sign-in step, plus an empty
# "My uploads" store for people's own files (upload-my-files). The lab's ready-made app must keep at least two
# data stores linked, which these two are. WITH_ACTIONS=1 instead connects Google Drive, Gmail and Google
# Calendar with actions (each person must then click Authorize in the app).
MODES='["FEDERATED","ACTIONS"]'
DATA_STORE="$CONNECTOR_PREFIX-data"; UPLOADS_STORE="$CONNECTOR_PREFIX-uploads"
if [ "${WITH_ACTIONS:-0}" = 1 ]; then
  step "Connecting Google Drive, Gmail and Google Calendar"
  CONNECTORS=("google_drive|$CONNECTOR_PREFIX-drive|Google Drive" "google_mail|$CONNECTOR_PREFIX-gmail|Gmail"
              "google_calendar|$CONNECTOR_PREFIX-calendar|Google Calendar")
  CONNECTED="Google Drive, Gmail, Google Calendar (search + actions)"; CONNECTED_NAMES="Google Drive, Gmail and Google Calendar"
else
  step "Creating the Graywing data stores"
  CONNECTORS=()
  CONNECTED="data stores Graywing demo data and My uploads (no sign-in needed)"; CONNECTED_NAMES=""
fi
body() {  # body MODES_JSON -> setUpDataConnector request for $SRC_NAME / $CID / $CNAME
  printf '{"collectionId":"%s","collectionDisplayName":"%s","dataConnector":{"dataSource":"%s","refreshInterval":"0s","connectorModes":%s,"entities":[{"entityName":"%s"}],"params":{}}}' \
    "$CID" "$CNAME" "$SRC_NAME" "$1" "$SRC_NAME"
}
CIDS=(); DS_IDS=(); NO_ACTIONS=(); CHOSEN=()
for c in "${CONNECTORS[@]}"; do
  IFS='|' read -r SRC_NAME BASE_CID CNAME <<<"$c"
  # A connector that failed to start can't be fixed, and a deleted one's id stays locked for hours: use the
  # first of these ids that is healthy, or else the first that is free.
  CANDS=("$BASE_CID"); [ "$SRC_NAME" = google_drive ] && CANDS+=("$CONNECTOR_PREFIX-gdrive")
  CANDS+=("$BASE_CID-2" "$BASE_CID-3")
  CID=""
  for cand in "${CANDS[@]}"; do
    api GET "$NBASE/collections/$cand/dataConnector"
    if [ "$CODE" = 200 ]; then
      case "$(jv 'd.get("state","")')" in
        FAILED|INITIALIZATION_FAILED) log "connector $cand failed to start; trying the next id"; continue ;;
        *) CID="$cand"; break ;;
      esac
    elif [ "$CODE" = 404 ]; then CID="$cand"; break
    else die "Could not read the $CNAME connector ($CODE): $(err)"; fi
  done
  [ -n "$CID" ] || die "Every $CNAME connector id tried has failed. Set CONNECTOR_PREFIX=graywing2 and paste the script again."
  CIDS+=("$CID"); CHOSEN+=("$SRC_NAME|$CID|$CNAME")
  url="$NBASE/collections/$CID/dataConnector"
  if [ "$CODE" = 404 ]; then
    api POST "$BASE:setUpDataConnector" "$(body "$MODES")"
    if [ "$CODE" != 200 ]; then
      log "connector with actions refused; trying search only"
      api POST "$BASE:setUpDataConnector" "$(body '["FEDERATED"]')"
      [ "$CODE" = 200 ] || die "Could not create the $CNAME connector ($CODE): $(err)"
      NO_ACTIONS+=("$CNAME")
    fi
    for _ in $(seq 20); do api GET "$url"; [ -n "$(jv 'd["entities"][0]["dataStore"]')" ] && break; sleep 3; done
    ok "$CNAME connector created ($(jv 'd.get("state","starting")' | tr 'A-Z' 'a-z'); it finishes starting in the background)"
  else
    if [ "$(jv '"ACTIONS" in d.get("connectorModes",[])')" != "True" ]; then
      api PATCH "$url?updateMask=connectorModes" "{\"connectorModes\":$MODES}"
      if [ "$CODE" = 200 ]; then api GET "$url"; else NO_ACTIONS+=("$CNAME"); api GET "$url"; fi
    fi
    ok "$CNAME connector: $(jv 'd.get("state","")' | tr 'A-Z' 'a-z')"
  fi
  DS="$(jv 'd["entities"][0]["dataStore"].split("/")[-1]')"
  [ -n "$DS" ] || die "The $CNAME connector has no data store yet. Paste the script again in a minute."
  DS_IDS+=("$DS")
done
CONNECTORS=("${CHOSEN[@]}")
make_store() {  # make_store ID "Display name" -> adds ID to DS_IDS (an unstructured, Google-hosted data store)
  api GET "$BASE/collections/default_collection/dataStores/$1"
  if [ "$CODE" = 404 ]; then
    api POST "$BASE/collections/default_collection/dataStores?dataStoreId=$1" \
      "{\"displayName\":\"$2\",\"industryVertical\":\"GENERIC\",\"solutionTypes\":[\"SOLUTION_TYPE_SEARCH\"],\"contentConfig\":\"CONTENT_REQUIRED\"}"
    [ "$CODE" = 200 ] || die "Could not create the $2 data store ($CODE): $(err)"
    ok "Data store created: $2"
  elif [ "$CODE" = 200 ]; then
    ok "Data store: $2"
  else
    die "Could not read the $2 data store ($CODE): $(err)"
  fi
  DS_IDS+=("$1")
}
if [ "${WITH_ACTIONS:-0}" != 1 ]; then
  make_store "$DATA_STORE" "Graywing demo data"
  make_store "$UPLOADS_STORE" "My uploads"
fi
DS_JSON="$(printf '%s\n' "${DS_IDS[@]}" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().split()))')"
for n in "${NO_ACTIONS[@]}"; do
  [ "${WITH_ACTIONS:-0}" = 1 ] || break
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
  if [ "$ids" != "$have" ]; then
    api PATCH "$ENGINE?updateMask=dataStoreIds" "{\"dataStoreIds\":$ids}"
    [ "$CODE" = 200 ] || return 1
    ATTACH_MSG="Connectors added to"; have="$ids"
  fi
  ATTACHED=1
  # Data-store mode: take off connectors / helper stores an earlier run of this setup linked (ids starting with
  # the prefix that aren't today's two stores). The app keeps at least two data stores, which today's two are.
  if [ "${WITH_ACTIONS:-0}" != 1 ]; then
    local keep
    keep="$(P="$CONNECTOR_PREFIX-" jv "json.dumps([x for x in json.loads('$have') if not x.startswith(__import__('os').environ['P']) or x in $DS_JSON])" '{}')"
    if [ -n "$keep" ] && [ "$keep" != "$have" ]; then
      api PATCH "$ENGINE?updateMask=dataStoreIds" "{\"dataStoreIds\":$keep}"
      if [ "$CODE" = 200 ]; then info "Took this setup's older connectors off the app; the data stores replace them."
      else info "Could not take the older connectors off the app ($(err)); you can ignore them."; fi
    fi
  fi
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
  ok "App created: $APP_NAME ($CONNECTED)"
  ATTACHED=1
else
  attach
  if [ -n "$ATTACHED" ]; then
    ok "$ATTACH_MSG ${APP_TITLE:-$APP_ID}"
  else
    info "The app doesn't take the new data sources yet ($(err)); trying again at the end."
  fi
fi
if [ "${WITH_ACTIONS:-0}" = 1 ] && [ "${#NO_ACTIONS[@]}" = 0 ]; then
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
set_models() {  # set_models "id id ..." [MODEL_ENABLED|MODEL_DISABLED] -> merges that state for them into modelConfigs
  api GET "$ENGINE"
  local cfg; cfg="$(WANT="$1" STATE="${2:-MODEL_ENABLED}" jv 'json.dumps({"modelConfigs": dict(d.get("modelConfigs") or {}, **{m: __import__("os").environ["STATE"] for m in __import__("os").environ["WANT"].split()})})')"
  [ "$(jv 'json.dumps(d.get("modelConfigs") or {}, sort_keys=True)')" = "$(jv 'json.dumps(d["modelConfigs"], sort_keys=True)' "$cfg")" ] && return 0
  api PATCH "$ENGINE?updateMask=modelConfigs" "$cfg"
  [ "$CODE" = 200 ]
}
model_answers() {  # model_answers MODEL_ID -> 0 if a one-word test question gets an answer; else $why says why
  api POST "$ENGINE/assistants/default_assistant:streamAssist" \
    "{\"query\":{\"text\":\"Reply with the single word OK.\"},\"generationSpec\":{\"modelId\":\"$1\"}}"
  # errors can come back as the HTTP status or inside a 200 stream (a JSON list of chunks)
  why="$(jv 'next((str(e["error"].get("message") or e["error"].get("status") or "error") for e in (d if isinstance(d, list) else [d]) if isinstance(e, dict) and e.get("error")), "")')"
  [ "$CODE" = 200 ] && [ -z "$why" ] && return 0
  [ -n "$why" ] || why="HTTP $CODE"
  return 1
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
  [ -n "$OFF" ] && warn "Models the app would not switch on: $OFF"
  # 5b-2. Some listed models can't answer in this project: the free trial blocks some Gemini models
  #       ("not available during the free trial") and Claude needs pay-as-you-go (CLAUDE_OVERAGE_REQUIRED).
  #       Left on, they show in the model picker and "Auto" can route to them, so answers fail. Ask each model
  #       a one-word question and switch off the ones that say they are not available here.
  info "Asking each of the $(wc -w <<<"$ON" | tr -d ' ') models a one-word test question to see which ones this lab can use..."
  WORKS=(); BROKEN=(); NOTES=(); UNSURE=(); NEED_PAYG=0; NEED_PAID=0
  judge() {  # judge MODEL -> verdict = works | broken (with $short) | disabled | "" (unsure)
    local m="$1" try
    verdict=""
    for try in 1 2 3; do
      if model_answers "$m"; then verdict=works; return; fi
      # "Model X is disabled." = just switched on and the change hasn't reached the chat yet: recheck later
      case "$why" in *"is disabled"*) verdict=disabled; return ;; esac
      case "$why $BODY" in
        *"free trial"*) verdict=broken; short="not in the free trial"; NEED_PAID=1; return ;;
        *OVERAGE*|*overage*|*"pay-as-you-go"*) verdict=broken; short="needs pay-as-you-go"; NEED_PAYG=1; return ;;
        *FAILED_PRECONDITION*|*"not available"*|*"not supported"*|*PERMISSION_DENIED*) verdict=broken ;;
      esac
      case "$CODE" in 400|403|404) verdict=broken ;; esac
      if [ "$verdict" = broken ]; then
        if [[ "$m" == claude* ]]; then short="needs pay-as-you-go"; NEED_PAYG=1; else short="${why:0:90}"; fi
        return
      fi
      [ "$try" -lt 3 ] && sleep 5   # 429, 5xx or a time-out: maybe a blip, so ask again before judging
    done
  }
  place() {  # place MODEL -> files the model under WORKS / BROKEN / UNSURE from $verdict
    local m="$1"
    if [ "$verdict" = works ]; then WORKS+=("$m")
    elif [ "$verdict" = broken ] && [ "${KEEP_CLAUDE:-0}" = 1 ] && [[ "$m" == claude* ]]; then
      WORKS+=("$m"); warn "$m can't answer yet ($short); leaving it on (KEEP_CLAUDE=1)."
    elif [ "$verdict" = broken ]; then BROKEN+=("$m"); NOTES+=("$m: $short")
    else UNSURE+=("$m"); WORKS+=("$m")
    fi
  }
  PENDING=()
  for m in $ON; do
    judge "$m"
    if [ "$verdict" = disabled ]; then PENDING+=("$m"); else place "$m"; fi
  done
  # Models that said "is disabled": wait for the switch-on to arrive and ask again (up to about 1.5 minutes).
  for round in 1 2 3; do
    [ "${#PENDING[@]}" = 0 ] && break
    info "Waiting for ${#PENDING[@]} just-switched-on model(s) to be ready, then asking again..."
    sleep 30
    NEXT=()
    for m in "${PENDING[@]}"; do
      judge "$m"
      if [ "$verdict" = disabled ]; then NEXT+=("$m"); else place "$m"; fi
    done
    PENDING=("${NEXT[@]}")
  done
  for m in "${PENDING[@]}"; do   # still "disabled": Claude is off for good; a Gemini model is left on (unsure)
    if [[ "$m" == claude* ]]; then verdict=broken; short="needs pay-as-you-go"; NEED_PAYG=1; else verdict=""; fi
    place "$m"
  done
  if [ "${#BROKEN[@]}" -gt 0 ] && [ "${#WORKS[@]}" = 0 ]; then
    warn "No model answered the test question (last error: ${why:0:120}); leaving the models as they are."
    WORKS=($ON); BROKEN=()
  elif [ "${#BROKEN[@]}" -gt 0 ]; then
    if set_models "${BROKEN[*]}" MODEL_DISABLED; then
      warn "Switched off ${#BROKEN[@]} model(s) this lab can't use:"
      for n in "${NOTES[@]}"; do info "  - $n"; done
    else
      warn "These models can't answer here and could not be switched off ($CODE). Don't pick them, and avoid Auto:"
      for n in "${NOTES[@]}"; do info "  - $n"; done
    fi
  fi
  [ "${#UNSURE[@]}" -gt 0 ] && warn "No clear answer from ${UNSURE[*]} (just switched on, or busy); left on. Run the setup again in a few minutes to recheck them."
  ok "Models on (${#WORKS[@]}): ${WORKS[*]}"
  TURNED_ON+=("${#WORKS[@]} models")
  [ "$NEED_PAID" = 1 ] && info "Models marked 'not in the free trial' need a paid Gemini Enterprise subscription; run this setup again after upgrading."
  if [ "$NEED_PAYG" = 1 ]; then
    info "To use Claude, with billing: console > Gemini Enterprise > Apps > ${APP_TITLE:-$APP_ID} > Configurations >"
    info "Feature Management > Enable third-party models > switch Claude on > Go to Usage & spend (turn on pay-as-you-go)"
    info "> Agree to the terms > Save, then run this setup again."
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
UPLOAD_MY_FILES_EOF
chmod +x "$HOME/bin/upload-my-files"
grep -qs 'graywing lab: upload-my-files' "$HOME/.bashrc" \
  || printf '\n# graywing lab: upload-my-files\nexport PATH="$HOME/bin:$PATH"\n' >> "$HOME/.bashrc"
ok "Installed: upload-my-files (adds ~/my-files to the My uploads data store and \"$MY_UPLOADS\" in your Drive)"

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

# 8a. The demo data store: documents go to a Cloud Storage bucket in this project, then into the data store.
#     Titles are the folder path joined with " - ", e.g. "Churn Radar - Customer Success - Documents - ...".
#     Photos can't be searched this way and are skipped. Re-runs skip this when the store already has documents.
if [ "${WITH_ACTIONS:-0}" != 1 ]; then
  DOCS_URL="$BASE/collections/default_collection/dataStores/$DATA_STORE/branches/default_branch/documents"
  api GET "$DOCS_URL?pageSize=1"
  if [ "$CODE" = 200 ] && [ -n "$(jv 'd.get("documents",[{}])[0].get("name","")')" ]; then
    ok "The Graywing demo data store already has the documents"
  else
    BUCKET="gs://$PROJECT-graywing-data"
    gcloud storage buckets describe "$BUCKET" >/dev/null 2>&1 \
      || gcloud storage buckets create "$BUCKET" --location=us --uniform-bucket-level-access >>"$LOG" 2>&1 \
      || die "Could not create the bucket $BUCKET (see $LOG)."
    rm -rf flat && mkdir flat
    find "$DATA_DIR" -type f \( -iname '*.pdf' -o -iname '*.docx' -o -iname '*.pptx' -o -iname '*.xlsx' \) | while IFS= read -r f; do
      r="${f#"$DATA_DIR"/}"; cp "$f" "flat/${r//\// - }"
    done
    NDOCS="$(find flat -type f | wc -l | tr -d ' ')"
    spin "Copying $NDOCS documents to $BUCKET" gcloud storage cp flat/* "$BUCKET/docs/" --quiet \
      || die "Could not copy the documents to $BUCKET (see $LOG)."
    api POST "$DOCS_URL:import" "{\"gcsSource\":{\"inputUris\":[\"$BUCKET/docs/*\"],\"dataSchema\":\"content\"},\"reconciliationMode\":\"INCREMENTAL\"}"
    [ "$CODE" = 200 ] || die "Could not start loading the documents into the data store ($CODE): $(err)"
    OP="$(jv 'd["name"]')"
    if spin "Loading $NDOCS documents into the Graywing demo data store (about 2 minutes)" wait_op "$OP"; then
      api GET "$HOST/v1alpha/$OP"
      ok "Graywing demo data store: $(jv 'd.get("metadata",{}).get("successCount","?")') of $NDOCS documents loaded"
      [ "$(jv 'd.get("metadata",{}).get("failureCount","0")')" = 0 ] || warn "Some documents could not be loaded (see $LOG)."
    else
      warn "The documents are still loading; they show up in the app within a few minutes."
    fi
    rm -rf flat
  fi
fi
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
    if [ "${WITH_ACTIONS:-0}" = 1 ]; then
      case "$(jv 'd.get("actionState","")')" in CREATING|UPDATING|RUNNING) rc=1 ;; esac
    fi
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
    ok "$CNAME connector: active$([ "${WITH_ACTIONS:-0}" = 1 ] && [ "$AST" = ACTIVE ] && echo ', actions active')"
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
printf '   \033[1mGRAYWING DEMO DATA IN YOUR GOOGLE DRIVE\033[0m  (to open the files yourself)\n'
printf '   \033[4;36m%s\033[0m\n\n' "$DRIVE_URL"
if [ -n "$UPLOADS_URL" ]; then
  printf '   \033[1mMY UPLOADS\033[0m  (your own files: run upload-my-files; it fills this folder and the My uploads data store)\n'
  printf '   \033[4;36m%s\033[0m\n\n' "$UPLOADS_URL"
fi
if [ "${#TURNED_ON[@]}" -gt 0 ]; then
  printf '   \033[1mTurned on:\033[0m %s\n' "$(printf '%s, ' "${TURNED_ON[@]}" | sed 's/, $//')"
  printf '   \033[1mConnected:\033[0m %s\n\n' "$CONNECTED"
fi
printf '   \033[2mAdmin console: %s\033[0m\n' "$CONSOLE_URL"
printf '   \033[2mLinks saved in %s · full log in %s\033[0m\n' "$WORK/links.txt" "$LOG"
printf '\033[32m%s\033[0m\n\n' "$line"
printf '   \033[1mNext (once):\033[0m\n'
printf '   1. Open the app link above (signed in as %s).\n' "$ACCOUNT"
if [ "${WITH_ACTIONS:-0}" = 1 ]; then
  printf '   2. Click \033[1mConnectors\033[0m and \033[1mAuthorize\033[0m %s.\n' "$CONNECTED_NAMES"
  printf '      If it says "Data connector is not ready yet", wait a few minutes and try again.\n'
  printf '   3. Ask: "What does Graywing Ag Systems sell, and who are its biggest customers?"\n\n'
else
  printf '   2. Ask: "What does Graywing Ag Systems sell, and who are its biggest customers?" (no sign-in step needed)\n'
  printf '   3. Build your agent: Agents > + Create agent; for its data, pick the \033[1mGraywing demo data\033[0m data store.\n\n'
fi
printf '   Your own files: put them in ~/my-files, then run \033[1mupload-my-files\033[0m (new terminal tabs find it;\n'
printf '   in this one, run  export PATH="$HOME/bin:$PATH"  first).\n'
printf '   Show the links again any time with:  cat %s\n\n' "$WORK/links.txt"
