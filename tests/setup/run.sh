#!/usr/bin/env bash
# Tests for setup.sh, in plain bash. Each case runs setup.sh in a fresh copy of this checkout
# (tracked and untracked, non-ignored files, committed to a new git repository), with stdin
# from /dev/null so no case can prompt, and an isolated git config.
#
# Usage: bash tests/setup/run.sh
#   SETUP_BASH=/bin/bash bash tests/setup/run.sh   runs setup.sh with another bash (macOS 3.2)
set -euo pipefail

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)
SETUP_BASH=${SETUP_BASH:-$BASH}
TMP=$(mktemp -d "${TMPDIR:-/tmp}/setup-tests.XXXXXX")
trap 'rm -rf "$TMP"' EXIT
YEAR=$(date +%Y)

# Git config for every case: an identity, nothing from the developer's own config.
export GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL=$TMP/gitconfig
printf '[user]\n\tname = Harness Author\n\temail = harness@example.com\n[init]\n\tdefaultBranch = main\n' >"$GIT_CONFIG_GLOBAL"
: >"$TMP/empty-gitconfig"

FIXTURE=$TMP/fixture
mkdir "$FIXTURE"
(cd "$REPO" && git ls-files -z -co --exclude-standard | perl -0ne 'print if -e substr($_, 0, -1)' |
    tar --null -T - -cf -) | tar -xf - -C "$FIXTURE"
(cd "$FIXTURE" && git init -q && git add -A && git commit -qm fixture)

CASES=0
FAILED=0
CASE=''      # name of the running case
DIR=''       # its working copy
RC=0         # setup.sh exit code
OUT=$TMP/out # setup.sh stdout
ERR=$TMP/err # setup.sh stderr

fail() {
    printf '  FAIL %s: %s\n' "$CASE" "$*"
    if [ -s "$ERR" ]; then sed 's/^/    stderr: /' "$ERR" | tail -15; fi
    FAILED=$((FAILED + 1))
    return 1
}

begin() {
    CASE=$1
    CASES=$((CASES + 1))
    DIR=$TMP/case-$CASES
    cp -R "$FIXTURE" "$DIR"
}

pass() { printf '  ok   %s\n' "$CASE"; }

# setup <args...>: runs setup.sh in $DIR without a terminal; sets RC.
setup() {
    RC=0
    (cd "$DIR" && "$SETUP_BASH" ./setup.sh "$@" </dev/null >"$OUT" 2>"$ERR") || RC=$?
}

# json <key>: one field of the single JSON object on stdout (array items one per line).
json() {
    perl -MJSON::PP -e '
        local $/; my @lines = grep { length } split /\n/, <STDIN>;
        die "stdout has " . scalar(@lines) . " lines, expected exactly one JSON object\n" if @lines != 1;
        my $v = decode_json($lines[0])->{$ARGV[0]};
        if (ref $v eq "ARRAY") { print join("\n", @$v) }
        elsif (ref $v) { print $v ? "true" : "false" }
        elsif (defined $v) { print $v }
    ' "$1" <"$OUT"
}

clean_tree() { [ -z "$(git -C "$DIR" status --porcelain)" ]; }

# expect_error <exit code> <case name> <setup args...>
expect_error() {
    local code=$1 name=$2
    shift 2
    begin "$name"
    setup "$@"
    [ "$RC" = "$code" ] || { fail "exit $RC, expected $code"; return 0; }
    [ "$(json status)" = error ] || { fail "JSON status is not error"; return 0; }
    [ "$(json code)" = "$code" ] || { fail "JSON code $(json code), expected $code"; return 0; }
    clean_tree || { fail "the tree changed"; return 0; }
    pass
}

# expect_derived <owner/repo> <name> <package> <bundle id>
expect_derived() {
    begin "derive $1"
    setup --derive-from-github "$1" --dry-run --json
    [ "$RC" = 0 ] || { fail "exit $RC"; return 0; }
    [ "$(json name)" = "$2" ] || { fail "name $(json name), expected $2"; return 0; }
    [ "$(json package)" = "$3" ] || { fail "package $(json package), expected $3"; return 0; }
    [ "$(json bundleId)" = "$4" ] || { fail "bundleId $(json bundleId), expected $4"; return 0; }
    [ "$(json displayName)" = "$2" ] || { fail "displayName $(json displayName), expected $2"; return 0; }
    pass
}

# The checks every successful generation must pass.
generated_ok() {
    local f
    [ "$RC" = 0 ] || { fail "exit $RC"; return 1; }
    [ "$(json status)" = ok ] || { fail "JSON status is not ok"; return 1; }
    for f in .template setup.sh docs tests scripts .claude CHANGELOG.md CONTRIBUTING.md \
        CODE_OF_CONDUCT.md SECURITY.md .github/CODEOWNERS .github/workflows/template.yml \
        .github/workflows/template-cleanup.yml; do
        [ ! -e "$DIR/$f" ] || { fail "$f survived"; return 1; }
    done
    for f in AGENTS.md README.md LICENSE local.properties.template .github/workflows/ci.yml \
        .github/dependabot.yml .github/PULL_REQUEST_TEMPLATE.md; do
        [ -f "$DIR/$f" ] || { fail "$f is missing"; return 1; }
    done
    [ "$(cat "$DIR/CLAUDE.md")" = "@AGENTS.md" ] || { fail "CLAUDE.md does not import AGENTS.md"; return 1; }
    [ -z "$(find "$DIR" -path "$DIR/.git" -prune -o -path '*/kotlin/com/template*' -print)" ] ||
        { fail "a com/template source directory survived"; return 1; }
}

# shellcheck disable=SC2016 # $BASH_VERSION must expand in the child bash
echo "setup.sh tests (bash: $("$SETUP_BASH" -c 'echo $BASH_VERSION'))"

# --- usage errors: exit 2 ----------------------------------------------------------------------
expect_error 2 "unknown option" --name App --package com.acme.app --frobnicate --yes --json
expect_error 2 "option without its value" --package com.acme.app --yes --json --name
expect_error 2 "option followed by another option" --name --package com.acme.app --yes --json
expect_error 2 "value given to a flag" --name App --package com.acme.app --yes=1 --json
expect_error 2 "missing --package and no terminal" --name App --yes --json
expect_error 2 "no --yes and no terminal" --name App --package com.acme.app --json

# --- invalid values: exit 3 --------------------------------------------------------------------
expect_error 3 "empty name" --name "" --package com.acme.app --yes --json
expect_error 3 "name starting with a digit" --name 1App --package com.acme.app --yes --json
expect_error 3 "name with a hyphen" --name My-App --package com.acme.app --yes --json
expect_error 3 "package with a keyword segment" --name App --package com.class.app --yes --json
expect_error 3 "package in java." --name App --package java.acme.app --yes --json
expect_error 3 "package with one segment" --name App --package weather --yes --json
expect_error 3 "package with uppercase" --name App --package com.Acme.app --yes --json
expect_error 3 "package inside the template's package" --name App --package com.template.app --yes --json
expect_error 3 "bundle ID with an underscore" --name App --package com.acme.app --bundle-id com.acme_x.app --yes --json
expect_error 3 "empty display name" --name App --package com.acme.app --display-name "" --yes --json
expect_error 3 "display name with an apostrophe" --name App --package com.acme.app --display-name "Bob's App" --yes --json
expect_error 3 "derive without a slash" --derive-from-github noslash --yes --json
expect_error 3 "derive with two slashes" --derive-from-github a/b/c --yes --json
expect_error 3 "derive with a space" --derive-from-github "own er/repo" --yes --json
GIT_CONFIG_GLOBAL=$TMP/empty-gitconfig \
    expect_error 3 "no author and no git user.name" --name App --package com.acme.app --yes --json

# --- preconditions: exit 4 ---------------------------------------------------------------------
begin "dirty tree"
touch "$DIR/untracked.txt"
setup --name App --package com.acme.app --yes --json
if [ "$RC" = 4 ] && [ "$(json code)" = 4 ] && [ -d "$DIR/.template" ]; then pass; else fail "exit $RC, expected 4"; fi

begin "already initialized (no .template/)"
(cd "$DIR" && git rm -rq .template && git commit -qm "drop .template")
setup --name App --package com.acme.app --yes --json
if [ "$RC" = 4 ] && [ "$(json code)" = 4 ] && grep -q "already initialized" "$ERR"; then pass; else fail "exit $RC, expected 4"; fi

# --- successful runs ---------------------------------------------------------------------------
begin "--help"
setup --help
if [ "$RC" = 0 ] && grep -q -- "--derive-from-github" "$OUT" && grep -q "Exit codes" "$OUT"; then pass; else fail "exit $RC"; fi

begin "dry run changes nothing"
setup --name WeatherApp --package com.acme.weather --dry-run --json
if [ "$RC" = 0 ] && [ "$(json dryRun)" = true ] && clean_tree && [ -f "$DIR/setup.sh" ] &&
    grep -q "com/acme/weather/MainActivity.kt" "$ERR"; then pass; else fail "exit $RC or the tree changed"; fi

begin "default generation"
setup --name WeatherApp --package com.acme.weather --yes --json
if generated_ok; then
    if ! "$BASH" "$FIXTURE/.template/check-leftovers.sh" "$DIR" >"$TMP/leftovers"; then
        fail "leftovers: $(head -5 "$TMP/leftovers")"
    elif [ "$(json name)/$(json package)/$(json bundleId)/$(json displayName)/$(json desktop)" != \
        "WeatherApp/com.acme.weather/com.acme.weather/WeatherApp/true" ]; then
        fail "JSON values: $(cat "$OUT")"
    elif ! grep -qxF "Copyright (c) $YEAR Harness Author" "$DIR/LICENSE"; then
        fail "LICENSE holder: $(grep Copyright "$DIR/LICENSE")"
    elif [ "$(git -C "$DIR" rev-list --count HEAD)" != 1 ] ||
        [ "$(git -C "$DIR" symbolic-ref --short HEAD)" != main ] || ! clean_tree; then
        fail "expected one commit on main and a clean tree"
    elif [ ! -f "$DIR/androidApp/src/main/kotlin/com/acme/weather/MainActivity.kt" ] ||
        [ ! -f "$DIR/shared/src/commonMain/kotlin/com/acme/weather/shared/App.kt" ] ||
        [ ! -f "$DIR/desktopApp/src/main/kotlin/com/acme/weather/desktop/main.kt" ]; then
        fail "sources were not moved to com/acme/weather"
    elif ! grep -q 'rootProject.name = "WeatherApp"' "$DIR/settings.gradle.kts" ||
        ! grep -q 'PRODUCT_BUNDLE_IDENTIFIER = com.acme.weather$' "$DIR/iosApp/Configuration/Config.xcconfig"; then
        fail "settings.gradle.kts or Config.xcconfig not renamed"
    else
        pass
    fi
fi

begin "second run on a generated project"
setup --name WeatherApp --package com.acme.weather --yes --json
cp "$FIXTURE/setup.sh" "$DIR/setup.sh"
setup --name Other --package com.acme.other --yes --json
if [ "$RC" = 4 ] && [ "$(json code)" = 4 ] && grep -q "already initialized" "$ERR"; then pass; else fail "exit $RC, expected 4"; fi

begin "--no-desktop"
setup --name WeatherApp --package com.acme.weather --no-desktop --yes --json
if generated_ok; then
    if [ "$(json desktop)" != false ]; then
        fail "JSON desktop is not false"
    elif [ -e "$DIR/desktopApp" ] || [ -e "$DIR/shared/src/jvmMain" ] || [ -e "$DIR/shared/src/jvmTest" ]; then
        fail "a desktop directory survived"
    elif grep -rnE 'desktopApp|jvm[[:space:]]*[({]|region desktop' "$DIR" --exclude-dir=.git >"$TMP/hits"; then
        fail "desktop text survived: $(head -3 "$TMP/hits")"
    elif ! grep -q '^    name: Android$' "$DIR/.github/workflows/ci.yml"; then
        fail "ci.yml job is not renamed to Android"
    elif grep -q 'app.packageName' "$DIR/gradle.properties"; then
        fail "app.packageName survived"
    else
        pass
    fi
fi

begin "underscore package, hyphenated bundle ID, display name with a space"
setup --name MyApp2 --package io.my_company.app_core --bundle-id io.my-company.app-core \
    --display-name "My App" --yes --json
if generated_ok; then
    if ! grep -q '>My App<' "$DIR/androidApp/src/main/res/values/strings.xml" ||
        ! grep -q '^APP_DISPLAY_NAME = My App$' "$DIR/iosApp/Configuration/Config.xcconfig" ||
        ! grep -q '^PRODUCT_BUNDLE_IDENTIFIER = io.my-company.app-core$' "$DIR/iosApp/Configuration/Config.xcconfig" ||
        ! grep -q 'title = "My App"' "$DIR/desktopApp/src/main/kotlin/io/my_company/app_core/desktop/main.kt" ||
        ! grep -q '^package io.my_company.app_core.shared$' "$DIR/shared/src/commonMain/kotlin/io/my_company/app_core/shared/App.kt"; then
        fail "values not written where expected"
    else
        pass
    fi
fi

begin "display name containing a template token is written once"
setup --name WeatherApp --package com.acme.weather --display-name "KMP Template Pro" --yes --json
if generated_ok; then
    if grep -q '>KMP Template Pro<' "$DIR/androidApp/src/main/res/values/strings.xml"; then pass; else fail "strings.xml: $(grep app_name "$DIR/androidApp/src/main/res/values/strings.xml")"; fi
fi

begin "--keep-git keeps history and commits nothing"
head_before=$(git -C "$DIR" rev-parse HEAD)
setup --name WeatherApp --package com.acme.weather --keep-git --yes --json
if generated_ok; then
    if [ "$(git -C "$DIR" rev-parse HEAD)" != "$head_before" ] || clean_tree; then
        fail "expected the fixture commit with uncommitted changes"
    elif ! json next | grep -q "git add -A && git commit"; then
        fail "next steps do not say to commit"
    else
        pass
    fi
fi

begin "--no-commit stages without committing"
setup --name WeatherApp --package com.acme.weather --no-commit --yes --json
if generated_ok; then
    if git -C "$DIR" rev-parse -q --verify HEAD >/dev/null; then
        fail "a commit exists"
    elif [ -z "$(git -C "$DIR" diff --cached --name-only)" ]; then
        fail "nothing is staged"
    else
        pass
    fi
fi

begin "no git identity: generated, not committed"
GIT_CONFIG_GLOBAL=$TMP/empty-gitconfig setup --name WeatherApp --package com.acme.weather \
    --author "Someone" --yes --json
if generated_ok; then
    if git -C "$DIR" rev-parse -q --verify HEAD >/dev/null; then fail "a commit exists"; else pass; fi
fi

begin "no .git: backup, then a new history"
rm -rf "$DIR/.git"
setup --name WeatherApp --package com.acme.weather --yes --json
if generated_ok; then
    if [ "$(git -C "$DIR" rev-list --count HEAD)" = 1 ]; then pass; else fail "expected one commit"; fi
fi

begin "derived from a repository that collides with template tokens"
setup --derive-from-github nkrebs13/kmp-template --yes --json
if generated_ok; then
    if [ "$(json name)/$(json author)" = "KmpTemplate/Harness Author" ]; then pass; else fail "JSON: $(cat "$OUT")"; fi
fi

# --- derivation (dry runs) ---------------------------------------------------------------------
expect_derived weird-Owner/123-my.app App123MyApp io.github.weird_owner.app_123_my_app io.github.weird-owner.app-123-my-app
expect_derived Acme/class Class io.github.acme.class_ io.github.acme.class
expect_derived UPPER/My_Repo MyRepo io.github.upper.my_repo io.github.upper.my-repo
expect_derived a/_ App io.github.a.app io.github.a.app
expect_derived x-y/repo. Repo io.github.x_y.repo io.github.x-y.repo
expect_derived octo/kotlin-app KotlinApp io.github.octo.kotlin_app io.github.octo.kotlin-app

begin "derive: explicit options win, author falls back to the owner"
GIT_CONFIG_GLOBAL=$TMP/empty-gitconfig setup --derive-from-github acme/thing --name Custom --dry-run --json
if [ "$RC" = 0 ] && [ "$(json name)/$(json package)/$(json author)" = "Custom/io.github.acme.thing/acme" ]; then
    pass
else
    fail "exit $RC: $(cat "$OUT")"
fi

# --- the template-only workflows are guarded to the template repository ------------------------
begin "workflow guards name the template repository"
# shellcheck disable=SC1091
repo=$(. "$FIXTURE/.template/manifest.env" && echo "$TEMPLATE_REPO")
if grep -q "github.repository == '$repo'" "$FIXTURE/.github/workflows/template.yml" &&
    grep -q "github.repository != '$repo'" "$FIXTURE/.github/workflows/template-cleanup.yml"; then
    pass
else
    fail "template.yml or template-cleanup.yml does not guard on $repo"
fi

echo
echo "$CASES cases, $FAILED failed"
[ "$FAILED" = 0 ]
