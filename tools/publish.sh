#!/usr/bin/env bash
# Phát hành bản đã dựng: ký APK bằng khóa Android cũ (giữ nguyên tên gói vn.hiepsinetchi.game để cài đè),
# ký manifest cập nhật, tạo GitHub Release và tải file lên, ghi release-files/update/*.json, commit + push.
# Khóa KHÔNG nằm trong kho mã:
#   KEYSTORE   (mặc định ~/pwab/signing.keystore)  KS_ALIAS  KS_PASS  KS_KEY_PASS
#   UPDATE_KEY (mặc định ~/hsnc-keys/update_priv.pem)
#   GH_TOKEN   (quyền ghi kho phamlongnb2004/hiep-si-net-chi)
# Dùng: tools/publish.sh <phiên-bản-app> <số-bản-dữ-liệu> [phiên-bản-app-tối-thiểu] [changelog.txt]
set -euo pipefail
VER=${1:?}; AV=${2:?}; MIN=${3:-$VER}; LOG=${4:-}
ROOT=$(cd "$(dirname "$0")/.." && pwd); B="$ROOT/build"; REPO=phamlongnb2004/hiep-si-net-chi; TAG="v$VER"
KEYSTORE=${KEYSTORE:-$HOME/pwab/signing.keystore}; UPDATE_KEY=${UPDATE_KEY:-$HOME/hsnc-keys/update_priv.pem}
UBER=${UBER:-$HOME/tools/uber-apk-signer.jar}
: "${KS_ALIAS:?đặt KS_ALIAS}"; : "${KS_PASS:?đặt KS_PASS}"; : "${GH_TOKEN:?đặt GH_TOKEN}"
# 1. ký APK (zipalign + v2/v3) bằng khóa cũ
java -jar "$UBER" -a "$B/android/HiepSiNetChi-unsigned.apk" --ks "$KEYSTORE" --ksAlias "$KS_ALIAS" --ksPass "$KS_PASS" --ksKeyPass "${KS_KEY_PASS:-$KS_PASS}" -o "$B/android/signed" --overwrite
cp "$B/android/signed/"*-aligned-signed.apk "$B/HiepSiNetChi.apk"
# 2. GitHub Release (tạo nếu chưa có) + tải file lên
API=https://api.github.com/repos/$REPO; UP=https://uploads.github.com/repos/$REPO; H=(-H "Authorization: Bearer $GH_TOKEN" -H "Accept: application/vnd.github+json")
RID=$(curl -s "${H[@]}" "$API/releases/tags/$TAG" | python3 -c "import sys,json;print(json.load(sys.stdin).get('id',''))")
if [ -z "$RID" ]; then RID=$(curl -s "${H[@]}" -X POST "$API/releases" -d "{\"tag_name\":\"$TAG\",\"name\":\"Hiệp Sĩ Nét Chì $VER\",\"make_latest\":\"true\"}" | python3 -c "import sys,json;print(json.load(sys.stdin)['id'])"); fi
up() { local f=$1 n=$2; local old; old=$(curl -s "${H[@]}" "$API/releases/$RID/assets" | python3 -c "import sys,json;print(next((str(a['id']) for a in json.load(sys.stdin) if a['name']=='$n'),''))")
  [ -n "$old" ] && curl -s "${H[@]}" -X DELETE "$API/releases/assets/$old" >/dev/null
  curl -s "${H[@]}" -H "Content-Type: application/octet-stream" --data-binary @"$f" "$UP/releases/$RID/assets?name=$n" | python3 -c "import sys,json;print(json.load(sys.stdin)['browser_download_url'])"; }
WURL=$(up "$B/HiepSiNetChi-Setup.exe" HiepSiNetChi-Setup.exe)
AURL=$(up "$B/HiepSiNetChi.apk" HiepSiNetChi.apk)
PURL=$(up "$B/assets-$AV.pck" "assets-$AV.pck")
# 3. manifest đã ký
python3 - "$VER" "$MIN" "$AV" "$WURL" "$AURL" "$PURL" "$LOG" > "$B/release.json" <<'PY'
import json,sys
v,mn,av,w,a,p,log=sys.argv[1:8]
cl=[l.strip() for l in open(log,encoding='utf-8') if l.strip()] if log else []
print(json.dumps({"app":{"version":v,"min":mn,"windows":{"url":w,"file":"HiepSiNetChi-Setup.exe"},"android":{"url":a,"file":"HiepSiNetChi.apk"}},
 "assets":{"version":int(av),"min_app":mn,"url":p,"file":"assets-%s.pck"%av},"changelog":cl},ensure_ascii=False))
PY
node "$ROOT/tools/sign-manifest.js" --key "$UPDATE_KEY" --in "$B/release.json" --out "$ROOT/release-files/update/manifest.json"
# 4. đẩy lên: Cloudflare tự dựng lại, /tai-game và ứng dụng thấy bản mới
cd "$ROOT" && git add release-files/update && git -c user.name="Claude" -c user.email="noreply@anthropic.com" commit -q -m "Phát hành $VER (dữ liệu $AV)" && echo "Đã commit. Hãy push để Cloudflare cập nhật."
