#!/usr/bin/env bash
# Phát hành bản đã dựng: ký APK bằng khóa Android cũ (giữ nguyên tên gói vn.hiepsinetchi.game để cài đè),
# ký manifest cập nhật, đưa file lên nhánh downloads của GitHub, ghi release-files/update/*.json, commit + push.
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
rm -rf "$B/android/signed"; java -jar "$UBER" -a "$B/android/HiepSiNetChi-unsigned.apk" --ks "$KEYSTORE" --ksAlias "$KS_ALIAS" --ksPass "$KS_PASS" --ksKeyPass "${KS_KEY_PASS:-$KS_PASS}" -o "$B/android/signed"
cp "$B/android/signed/"*-aligned-signed.apk "$B/HiepSiNetChi.apk"
# 2. đưa file lên nhánh "downloads" của kho GitHub (một commit duy nhất, ghi đè mỗi lần phát hành để kho không phình)
#    tải về qua raw.githubusercontent.com (hỗ trợ tải tiếp bằng Range); trang /tai-game và ứng dụng dùng link trong manifest
DL="$B/dl"; rm -rf "$DL"; mkdir -p "$DL"; AUTH="http.extraHeader=Authorization: Basic $(printf 'x-access-token:%s' "$GH_TOKEN"|base64 -w0)"
( cd "$DL" && git init -q && git checkout -q -b downloads
  # mỗi file một commit, đẩy từng lần (gói lớn đẩy một lần hay bị proxy cắt); lần đầu ghi đè nhánh cũ
  first=1
  for f in "assets-$AV.pck" HiepSiNetChi-Setup.exe HiepSiNetChi.apk; do
    cp "$B/$f" . && git add "$f" && git -c user.name="Claude" -c user.email="noreply@anthropic.com" commit -q -m "Bản tải $VER: $f"
    for try in 1 2 3; do git -c credential.helper= -c "$AUTH" push -q $([ $first = 1 ] && echo -f) "https://github.com/$REPO.git" downloads && break; sleep 5; done
    first=0
  done )
RAW="https://raw.githubusercontent.com/$REPO/downloads"
WURL="$RAW/HiepSiNetChi-Setup.exe"; AURL="$RAW/HiepSiNetChi.apk"; PURL="$RAW/assets-$AV.pck"
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
