#!/usr/bin/env bash
# Cuts a release: moves the CHANGELOG's [Unreleased] section under a new version heading,
# updates the compare links, commits, creates an annotated tag and pushes both. The tag push
# triggers .github/workflows/release.yml, which creates the GitHub Release. Template-only.
#
# Usage: scripts/release.sh [--dry-run] X.Y.Z
#   --dry-run   print the CHANGELOG diff and the commands; change nothing
#
# The release commit goes straight to main: it only edits CHANGELOG.md, and the repository's
# branch protection lets administrators bypass the required checks (docs/MAINTAINING.md).
set -euo pipefail

CHANGELOG=CHANGELOG.md

die() {
    printf 'release.sh: %s\n' "$*" >&2
    exit 1
}

usage() {
    printf 'usage: scripts/release.sh [--dry-run] X.Y.Z\n' >&2
    exit 2
}

DRY_RUN=0
VERSION=''
for arg in "$@"; do
    case $arg in
        --dry-run) DRY_RUN=1 ;;
        -*) usage ;;
        *) [ -z "$VERSION" ] || usage; VERSION=$arg ;;
    esac
done
[ -n "$VERSION" ] || usage
TAG=v$VERSION

# version_gt A B: true when A > B (numeric X.Y.Z comparison; bash 3.2 has no sort -V guarantee).
version_gt() {
    local a1 a2 a3 b1 b2 b3
    IFS=. read -r a1 a2 a3 <<<"$1"
    IFS=. read -r b1 b2 b3 <<<"$2"
    [ "$a1" -gt "$b1" ] && return 0
    [ "$a1" -lt "$b1" ] && return 1
    [ "$a2" -gt "$b2" ] && return 0
    [ "$a2" -lt "$b2" ] && return 1
    [ "$a3" -gt "$b3" ]
}

SEMVER_RE='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'
[[ $VERSION =~ $SEMVER_RE ]] || die "'$VERSION' is not a plain X.Y.Z version"

cd "$(git rev-parse --show-toplevel)"
[ -f "$CHANGELOG" ] || die "$CHANGELOG not found"

# --- preconditions -------------------------------------------------------------------------------
[ "$(git rev-parse --abbrev-ref HEAD)" = main ] || die "not on main"
[ -z "$(git status --porcelain)" ] || die "the working tree is not clean"
git fetch --quiet origin main --tags
[ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] || die "main is not up to date with origin/main"

PREV=''
for t in $(git tag --list 'v[0-9]*.[0-9]*.[0-9]*'); do
    v=${t#v}
    [[ $v =~ $SEMVER_RE ]] || continue
    if [ -z "$PREV" ] || version_gt "$v" "$PREV"; then PREV=$v; fi
done
[ -n "$PREV" ] || die "no existing vX.Y.Z tag to compare against"
version_gt "$VERSION" "$PREV" || die "$VERSION is not greater than the latest tag v$PREV"

grep -q '^## \[Unreleased\]' "$CHANGELOG" || die "$CHANGELOG has no '## [Unreleased]' heading"
LINK_LINE=$(grep -m1 '^\[Unreleased\]: ' "$CHANGELOG" || true)
[ -n "$LINK_LINE" ] || die "$CHANGELOG has no '[Unreleased]: ' compare link"
BASE_URL=${LINK_LINE#\[Unreleased\]: }
BASE_URL=${BASE_URL%/compare/*}

# Content of [Unreleased]: up to the next '## [' heading or the first link definition.
UNRELEASED=$(awk '
    /^## \[Unreleased\]/ { on = 1; next }
    on && (/^## \[/ || /^\[[^]]+\]: /) { exit }
    on { print }
' "$CHANGELOG")
printf '%s' "$UNRELEASED" | grep -q '[^[:space:]]' || die "[Unreleased] in $CHANGELOG is empty"

# --- rewrite the CHANGELOG -----------------------------------------------------------------------
NEW=$(mktemp "${TMPDIR:-/tmp}/changelog.XXXXXX")
trap 'rm -f "$NEW"' EXIT
DATE=$(date +%F)
awk -v ver="$VERSION" -v prev="$PREV" -v date="$DATE" -v base="$BASE_URL" '
    /^## \[Unreleased\]/ { print; print ""; print "## [" ver "] - " date; print ""; skipblank = 1; next }
    skipblank && /^$/ { next }
    { skipblank = 0 }
    /^\[Unreleased\]: / {
        print "[Unreleased]: " base "/compare/v" ver "...HEAD"
        print "[" ver "]: " base "/compare/v" prev "...v" ver
        next
    }
    { print }
' "$CHANGELOG" >"$NEW"

if [ "$DRY_RUN" = 1 ]; then
    echo "Dry run: nothing is changed. CHANGELOG.md diff:"
    diff -u "$CHANGELOG" "$NEW" || true
    echo
    echo "Would run:"
    printf '  git commit -am %q\n' "chore(release): $TAG"
    printf '  git tag -a %s -m %q\n' "$TAG" "Release $TAG"
    printf '  git %s --atomic origin main %s\n' push "$TAG"
    exit 0
fi

cat "$NEW" >"$CHANGELOG"
git add "$CHANGELOG"
git commit --quiet -m "chore(release): $TAG"
git tag -a "$TAG" -m "Release $TAG"
git push --atomic origin main "$TAG"
echo "Released $TAG. The Release workflow publishes the GitHub Release from the CHANGELOG section."
