#!/usr/bin/env bash
# Livraison de La Cambuse de Git (phase 8).
#
# Produit dans dist/ :
#   - la-cambuse-<v>-arm64-v8a-DEBUG-non-distribuable.apk  (APK de TEST, clé debug)
#   - la-cambuse_<v>_amd64.deb                             (application + compagnon)
#   - la-cambuse-<v>-sources.zip                            (git archive du commit)
#   - sbom.cdx.json                                         (dépendances Dart, CycloneDX)
#   - SHA256SUMS et BUILD_REPORT.md
#
# Aucune installation système, aucune publication. Usage :
#   tool/package_release.sh [--skip-build] [--with-tests]
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$PWD"
SKIP_BUILD=0
WITH_TESTS=0
for a in "$@"; do
  case "$a" in
    --skip-build) SKIP_BUILD=1 ;;
    --with-tests) WITH_TESTS=1 ;;
    *) echo "Option inconnue : $a" >&2; exit 64 ;;
  esac
done

VERSION="$(sed -n 's/^version: *\([0-9.]*\).*/\1/p' pubspec.yaml)"
COMMIT="$(git rev-parse --short HEAD)"
DIRTY="$(git status --porcelain | wc -l | tr -d ' ')"
DIST="$ROOT/dist"
rm -rf "$DIST"
mkdir -p "$DIST"
log() { printf '▶ %s\n' "$*"; }
# Exécute une étape dont la sortie va dans un journal ; en cas d'échec, affiche
# la fin du journal (sinon la cause reste invisible, en CI notamment).
step() {
  local logfile="$1"; shift
  if ! "$@" > "$logfile" 2>&1; then
    echo "ÉCHEC : $* — fin de $logfile :" >&2
    tail -40 "$logfile" >&2
    exit 1
  fi
}

if [ "$WITH_TESTS" = 1 ]; then
  log "Tests (application, compagnon, protocole)"
  step "$DIST/.analyze.log" flutter analyze --fatal-infos
  step "$DIST/.test-app.log" flutter test
  (cd companion && step "$DIST/.test-companion.log" dart test)
  (cd packages/cambuse_protocol && step "$DIST/.test-protocol.log" dart test)
fi

if [ "$SKIP_BUILD" = 0 ]; then
  log "Build Linux (release)"
  step "$DIST/.build-linux.log" flutter build linux --release
  log "Build APK de test (debug, arm64-v8a)"
  step "$DIST/.build-apk.log" flutter build apk --debug --target-platform android-arm64
  log "Build du compagnon (exécutable natif)"
  rm -f build/companion/cambuse-companion
  mkdir -p build/companion
  step "$DIST/.build-companion.log" dart compile exe companion/bin/cambuse_companion.dart -o build/companion/cambuse-companion
fi

BUNDLE="$ROOT/build/linux/x64/release/bundle"
APK_SRC="$ROOT/build/app/outputs/flutter-apk/app-debug.apk"
COMPANION="$ROOT/build/companion/cambuse-companion"
for f in "$BUNDLE/la_cambuse" "$APK_SRC" "$COMPANION"; do
  [ -e "$f" ] || { echo "Artefact manquant : $f (relancez sans --skip-build)" >&2; exit 66; }
done

# --- APK : nom explicite, jamais présenté comme une release -----------------
APK="$DIST/la-cambuse-$VERSION-arm64-v8a-DEBUG-non-distribuable.apk"
cp "$APK_SRC" "$APK"

# --- Paquet .deb ------------------------------------------------------------
log "Paquet .deb"
PKG="$DIST/.deb-root"
mkdir -p "$PKG/DEBIAN" "$PKG/opt/la-cambuse" "$PKG/usr/bin" \
  "$PKG/usr/share/applications" "$PKG/usr/share/icons/hicolor/192x192/apps" "$PKG/usr/share/doc/la-cambuse"
cp -a "$BUNDLE/." "$PKG/opt/la-cambuse/"
install -m 0755 "$COMPANION" "$PKG/opt/la-cambuse/cambuse-companion"
ln -s /opt/la-cambuse/la_cambuse "$PKG/usr/bin/la-cambuse"
ln -s /opt/la-cambuse/cambuse-companion "$PKG/usr/bin/cambuse-companion"
install -m 0644 android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png "$PKG/usr/share/icons/hicolor/192x192/apps/la-cambuse.png"
install -m 0644 companion/systemd/cambuse-companion.service "$PKG/usr/share/doc/la-cambuse/cambuse-companion.service.exemple"
install -m 0644 companion/README.md "$PKG/usr/share/doc/la-cambuse/COMPAGNON.md"
cat > "$PKG/usr/share/applications/la-cambuse.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=La Cambuse de Git
Comment=Académie et atelier Git, GitHub, GitLab, Docker et DevOps
Exec=/opt/la-cambuse/la_cambuse
Icon=la-cambuse
Categories=Development;Education;
Terminal=false
EOF

# Dépendances calculées à partir des binaires (dpkg-shlibdeps), pas à la main.
SHLIB_TMP="$(mktemp -d)"
mkdir -p "$SHLIB_TMP/debian"
printf 'Source: la-cambuse\n\nPackage: la-cambuse\nArchitecture: any\n' > "$SHLIB_TMP/debian/control"
DEPENDS="$(cd "$SHLIB_TMP" && dpkg-shlibdeps -O -l"$BUNDLE/lib" "$BUNDLE/la_cambuse" "$BUNDLE"/lib/*.so "$COMPANION" 2>/dev/null \
  | sed -n 's/^shlibs:Depends=//p')"
rm -rf "$SHLIB_TMP"
[ -n "$DEPENDS" ] || DEPENDS="libc6 (>= 2.35), libgtk-3-0, libsecret-1-0"
# Git est requis par le compagnon (exécuté via PATH, non détectable par shlibdeps).
DEPENDS="$DEPENDS, git"

INSTALLED_KB="$(du -sk "$PKG" | cut -f1)"
cat > "$PKG/DEBIAN/control" <<EOF
Package: la-cambuse
Version: $VERSION
Architecture: amd64
Maintainer: Projet La Cambuse de Git <noreply@lacambuse.invalid>
Installed-Size: $INSTALLED_KB
Depends: $DEPENDS
Section: devel
Priority: optional
Description: Académie et atelier Git, GitHub, GitLab, Docker et DevOps
 Application Flutter : cours hors ligne, labos, professeur IA facultatif,
 et compagnon Linux sécurisé (cambuse-companion) pour opérer sur vos dépôts
 avec approbation explicite de chaque modification.
EOF

find "$PKG" -type d -exec chmod 0755 {} +
find "$PKG" -type f -exec chmod 0644 {} +
chmod 0755 "$PKG/opt/la-cambuse/la_cambuse" "$PKG/opt/la-cambuse/cambuse-companion"
DEB="$DIST/la-cambuse_${VERSION}_amd64.deb"
dpkg-deb --root-owner-group -Zxz --build "$PKG" "$DEB" > /dev/null
rm -rf "$PKG"

# --- Vérification du paquet sans l'installer --------------------------------
log "Vérification du .deb (sans installation)"
CHECK="$(mktemp -d)"
dpkg-deb -x "$DEB" "$CHECK"
MISSING="$(ldd "$CHECK/opt/la-cambuse/la_cambuse" | grep -c 'not found' || true)"
COMPANION_HELP="$("$CHECK/opt/la-cambuse/cambuse-companion" --help 2>&1 | head -1)"
rm -rf "$CHECK"
[ "$MISSING" = 0 ] || { echo "Bibliothèques manquantes dans le paquet extrait : $MISSING" >&2; exit 70; }

# --- Sources et SBOM --------------------------------------------------------
log "Archive des sources et SBOM"
git archive --format=zip --prefix="la-cambuse-$VERSION/" -o "$DIST/la-cambuse-$VERSION-sources.zip" HEAD
python3 - "$DIST/sbom.cdx.json" "$VERSION" <<'PY'
import json, sys, yaml
out, version = sys.argv[1], sys.argv[2]
components = []
for lock, scope in (("pubspec.lock", "application"), ("companion/pubspec.lock", "compagnon")):
    data = yaml.safe_load(open(lock, encoding="utf-8")) or {}
    for name, pkg in sorted((data.get("packages") or {}).items()):
        components.append({
            "type": "library", "name": name, "version": str(pkg.get("version", "")),
            "purl": f"pkg:pub/{name}@{pkg.get('version', '')}",
            "properties": [{"name": "cambuse:scope", "value": scope}, {"name": "pub:dependency", "value": pkg.get("dependency", "")},
                           {"name": "pub:source", "value": pkg.get("source", "")}],
        })
json.dump({"bomFormat": "CycloneDX", "specVersion": "1.5", "version": 1,
           "metadata": {"component": {"type": "application", "name": "la-cambuse", "version": version}},
           "components": components}, open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print(f"{len(components)} composants")
PY

# --- Sommes de contrôle -----------------------------------------------------
(cd "$DIST" && sha256sum ./*.apk ./*.deb ./*.zip sbom.cdx.json | sed 's# \./# #' > SHA256SUMS)

# --- Rapport ----------------------------------------------------------------
log "Rapport de build"
JAVA="/opt/android-studio/jbr/bin"
SIGNER="$(ls -d "${ANDROID_HOME:-$HOME/Android/Sdk}"/build-tools/*/apksigner 2>/dev/null | sort -V | tail -1)"
CERT="inconnu (apksigner introuvable)"
if [ -n "$SIGNER" ]; then
  CERT="$(PATH="$JAVA:$PATH" "$SIGNER" verify --print-certs "$APK" 2>/dev/null | sed -n 's/.*certificate DN: //p' | head -1)"
fi
ABIS="$(unzip -Z1 "$APK" | sed -n 's#^lib/\([^/]*\)/libflutter\.so$#\1#p' | sort -u | tr '\n' ' ')"
OTHER_ABIS="$(unzip -Z1 "$APK" | sed -n 's#^lib/\([^/]*\)/.*\.so$#\1#p' | sort -u | grep -vxF -f <(printf '%s\n' $ABIS) | tr '\n' ' ' || true)"
{
  echo "# Rapport de build — La Cambuse de Git $VERSION"
  echo
  echo "- Date : $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "- Commit : $COMMIT$([ "$DIRTY" != 0 ] && echo " (+ $DIRTY fichier(s) non commités)")"
  echo "- Flutter : $(flutter --version --machine 2>/dev/null | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d["frameworkVersion"], "/ Dart", d["dartSdkVersion"])')"
  echo "- Système : $(. /etc/os-release && echo "$PRETTY_NAME") $(uname -m)"
  echo
  echo "## Artefacts"
  echo
  echo "| Fichier | Taille | SHA-256 |"
  echo "|---|---|---|"
  while read -r sum name; do
    echo "| \`$name\` | $(du -h "$DIST/$name" | cut -f1) | \`$sum\` |"
  done < "$DIST/SHA256SUMS"
  echo
  echo "## APK"
  echo
  echo "- Certificat de signature : **$CERT**"
  case "$CERT" in
    *"CN=Android Debug"*) echo "- ⚠️ APK **DEBUG** : réservé aux tests, **non distribuable**. Une release exige android/key.properties (sinon refusée par Gradle)." ;;
  esac
  echo "- ABI exécutables (moteur Flutter présent) : $ABIS"
  if [ -n "$OTHER_ABIS" ]; then echo "- Autres dossiers d'ABI (greffons seuls, l'application n'y démarre pas) : $OTHER_ABIS"; fi
  echo
  echo "## Paquet .deb"
  echo
  echo '```'
  dpkg-deb --info "$DEB" | sed -n '/Package:/,$p'
  echo '```'
  echo
  echo "- Bibliothèques non résolues après extraction : $MISSING"
  echo "- Compagnon embarqué : \`$COMPANION_HELP\`"
  echo "- Installation non effectuée par ce script (nécessite sudo) : \`sudo apt install ./$(basename "$DEB")\`"
  if [ "$WITH_TESTS" = 1 ]; then
    echo
    echo "## Tests"
    echo
    echo "- Analyse : $(tail -1 "$DIST/.analyze.log")"
    echo "- Application : $(tail -1 "$DIST/.test-app.log")"
    echo "- Compagnon : $(tail -1 "$DIST/.test-companion.log")"
    echo "- Protocole : $(tail -1 "$DIST/.test-protocol.log")"
  fi
} > "$DIST/BUILD_REPORT.md"

log "Terminé : $DIST"
ls -l "$DIST"
