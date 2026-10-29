#!/usr/bin/env bash
# Tests for setup.sh, in plain bash. Each case runs setup.sh in a fresh copy of this checkout
# (tracked and untracked, non-ignored files, committed to a new git repository), with stdin
# from /dev/null so no case can prompt, and an isolated git config.
#
# Usage: bash tests/setup/run.sh
#   SETUP_BASH=/bin/bash bash tests/setup/run.sh   runs setup.sh with another bash (macOS 3.2)
# shellcheck disable=SC2016 # single-quoted $ in jget arguments is Perl, not shell
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

# Records a failure and returns 0, so one failing case never stops the run under set -e.
fail() {
    printf '  FAIL %s: %s\n' "$CASE" "$*"
    if [ -s "$ERR" ]; then sed 's/^/    stderr: /' "$ERR" | tail -15; fi
    FAILED=$((FAILED + 1))
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

# jget <perl expression over $j>: a value from the single JSON object on stdout (array items
# one per line, booleans as true/false, a missing value as nothing). Fails unless stdout is
# exactly one line holding one JSON object.
jget() {
    perl -MJSON::PP -e '
        local $/; my @lines = grep { length } split /\n/, <STDIN>;
        die "stdout has " . scalar(@lines) . " lines, expected exactly one JSON object\n" if @lines != 1;
        my $j = decode_json($lines[0]);
        my $v = eval $ARGV[0];
        die $@ if $@;
        if (ref $v eq "ARRAY") { print join("\n", @$v) }
        elsif (JSON::PP::is_bool($v)) { print $v ? "true" : "false" }
        elsif (defined $v) { print $v }
    ' "$1" <"$OUT"
}

# json <key>: a top-level field.
json() { jget "\$j->{$1}"; }

# next_runs: the "run" (or "read") value of every "next" step, one per line.
next_runs() { jget 'join("\n", map { $_->{run} // $_->{read} } @{$j->{next}})'; }

category_of() {
    case $1 in 2) echo usage ;; 3) echo validation ;; 4) echo precondition ;; *) echo internal ;; esac
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
    [ "$(json category)" = "$(category_of "$code")" ] || { fail "JSON category $(json category)"; return 0; }
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
        .github/workflows/template-cleanup.yml .github/workflows/dependabot-automerge.yml \
        .github/workflows/release.yml scripts/release.sh; do
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

echo "setup.sh tests (bash: $("$SETUP_BASH" -c 'echo $BASH_VERSION'))"

# --- usage errors: exit 2 ----------------------------------------------------------------------
expect_error 2 "unknown option" --name App --package com.acme.app --frobnicate --yes --json
expect_error 2 "option without its value" --package com.acme.app --yes --json --name
expect_error 2 "option followed by another option" --name --package com.acme.app --yes --json
expect_error 2 "value given to a flag" --name App --package com.acme.app --yes=1 --json
expect_error 2 "missing --package and no terminal" --name App --yes --json
expect_error 2 "no --yes and no terminal" --name App --package com.acme.app --json
if ! grep -q -- "add --yes" "$ERR" || grep -q "^usage:" "$ERR"; then fail "no --yes: expected a one-line hint"; fi

begin "usage errors print the message before the usage"
setup --name App --package com.acme.app --frobnicate --yes --json
if [ "$RC" = 2 ] && head -1 "$ERR" | grep -q "^setup.sh: unknown option: --frobnicate" && grep -q "^usage:" "$ERR"; then
    pass
else
    fail "stderr: $(head -2 "$ERR")"
fi

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
expect_error 3 "empty --author" --name App --package com.acme.app --author "" --yes --json
expect_error 3 "whitespace-only --author" --name App --package com.acme.app --author "   " --yes --json
expect_error 3 "display name that is not UTF-8" --name App --package com.acme.app --display-name $'My\xffApp' --yes --json
expect_error 3 "author that is not UTF-8" --name App --package com.acme.app --author $'\xfe\xff' --yes --json
long=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa # 64 characters
expect_error 3 "package segment over 63 characters" --name App --package "com.$long.app" --yes --json
expect_error 3 "name over 50 characters" --name "App$long" --package com.acme.app --yes --json
expect_error 3 "package segment over 63 characters, dry run" --name App --package "com.$long.app" --dry-run --json

begin "source paths too long for the checkout's location (dry run)"
deep=$TMP/deep
while [ "${#deep}" -lt 840 ]; do deep=$deep/dddddddddddddddddddddddddddddddddddddddddddddddddd; done
mkdir -p "$deep"
cp -R "$FIXTURE" "$deep/repo"
DIR=$deep/repo
setup --name WeatherApp --package com.acme.weather --dry-run --json
if [ "$RC" = 3 ] && grep -q "longest source path" "$ERR" && clean_tree; then pass; else fail "exit $RC, expected 3"; fi
rm -rf "$TMP/deep"

# --- preconditions: exit 4 ---------------------------------------------------------------------
begin "dirty tree"
touch "$DIR/untracked.txt"
setup --name App --package com.acme.app --yes --json
if [ "$RC" = 4 ] && [ "$(json code)" = 4 ] && [ -d "$DIR/.template" ]; then pass; else fail "exit $RC, expected 4"; fi

begin "already initialized (no .template/)"
(cd "$DIR" && git rm -rq .template && git commit -qm "drop .template")
setup --name App --package com.acme.app --yes --json
if [ "$RC" = 4 ] && [ "$(json reason)" = already-initialized ] && [ "$(json category)" = precondition ] &&
    grep -q "already initialized" "$ERR"; then pass; else fail "exit $RC, expected 4 already-initialized"; fi

# --- successful runs ---------------------------------------------------------------------------
begin "--help"
setup --help
if [ "$RC" = 0 ] && grep -q -- "--derive-from-github" "$OUT" && grep -q "Exit codes" "$OUT"; then pass; else fail "exit $RC"; fi

begin "--help --json: help on stderr, one JSON object on stdout"
setup --help --json
if [ "$RC" = 0 ] && [ "$(json help)" = true ] && [ "$(json status)" = ok ] && grep -q "Exit codes" "$ERR"; then
    pass
else
    fail "exit $RC: $(cat "$OUT")"
fi

begin "dry run changes nothing and reports the plan"
setup --name WeatherApp --package com.acme.weather --dry-run --json
if [ "$RC" != 0 ] || [ "$(json dryRun)" != true ] || ! clean_tree || [ ! -f "$DIR/setup.sh" ]; then
    fail "exit $RC or the tree changed"
elif ! jget '$j->{plan}{delete}' | grep -qx setup.sh ||
    ! jget '$j->{plan}{write}' | grep -qx AGENTS.md ||
    ! jget '$j->{plan}{edit}' | grep -qx settings.gradle.kts ||
    [ "$(jget '(grep { $_->{to} eq "androidApp/src/main/kotlin/com/acme/weather/MainActivity.kt" } @{$j->{plan}{move}})[0]{from}')" != \
        androidApp/src/main/kotlin/com/template/android/MainActivity.kt ]; then
    fail "plan is incomplete: $(cat "$OUT")"
elif [ -n "$(jget 'exists $j->{removed} ? "yes" : ""')" ]; then
    fail "a dry run reported removed files"
elif [ "$(next_runs)" != "./setup.sh --name WeatherApp --package com.acme.weather --json --yes" ]; then
    fail "next is not the command without --dry-run: $(next_runs)"
else
    pass
fi

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
    elif [ "$(json verified)/$(json committed)" != false/true ] ||
        [ "$(jget '$j->{next}[0]{run}')" != "./gradlew check" ] || next_runs | grep -q commit; then
        fail "JSON verified/committed/next: $(cat "$OUT")"
    elif grep -rl 'region desktop' "$DIR" --include='*.md' --exclude-dir=.git >"$TMP/hits"; then
        fail "Markdown region markers survived: $(cat "$TMP/hits")"
    elif ! grep -q '^// region desktop$' "$DIR/settings.gradle.kts"; then
        fail "the Gradle region markers should stay"
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
    elif grep -rnE 'JvmApplication|kotlin-jvm|kotlin\.jvm\) apply|jvm(Main|Test)' "$DIR" --exclude-dir=.git \
        --exclude='*.txt' >"$TMP/hits"; then
        fail "desktop build logic survived: $(head -3 "$TMP/hits")"
    elif ! (cd "$DIR" && git ls-files -z -co --exclude-standard | perl -0ne '
        chomp; next unless -f && /\.(?:kts?|properties|ya?ml|md)$/;
        open my $f, "<", $_ or die; local $/; my $t = <$f>;
        if ($t =~ /\n\n[ \t]*[)\]}]/ || $t =~ /\n\n\z/) { print "$_\n"; $bad = 1 }
        END { exit($bad ? 1 : 0) }' >"$TMP/hits"); then
        fail "a removed block left a blank line before a bracket or at the end of: $(cat "$TMP/hits")"
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
    elif ! next_runs | grep -q "git add -A && git commit"; then
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
    elif [ "$(json committed)" != false ] || ! next_runs | grep -q "^git commit"; then
        fail "JSON does not say to commit: $(cat "$OUT")"
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

begin "unbalanced region markers stop the run before any change"
printf '// region desktop\n' >>"$DIR/settings.gradle.kts"
(cd "$DIR" && git commit -qam "stray marker")
setup --name WeatherApp --package com.acme.weather --yes --json
if [ "$RC" = 5 ] && [ "$(json category)" = internal ] && clean_tree && [ -f "$DIR/setup.sh" ]; then
    pass
else
    fail "exit $RC, expected 5 with nothing changed"
fi

begin "a path with newlines cannot point a deletion outside the repository"
victim=$TMP/victim-$CASES
mkdir -p "$victim" && touch "$victim/keep"
# find prints this one build directory as "./cache", "<victim>" and "cache/build" if split on newlines.
evil="$DIR/cache"$'\n'"$victim"$'\n'"cache/build"
mkdir -p "$evil" && touch "$evil/output.bin"
setup --name WeatherApp --package com.acme.weather --yes --json
if generated_ok; then
    if [ ! -f "$victim/keep" ]; then
        fail "a directory outside the repository was deleted"
    elif [ -e "$evil" ]; then
        fail "the build directory with newlines in its path survived"
    else
        pass
    fi
fi

begin "a source package named build is renamed, not skipped"
mkdir -p "$DIR/androidApp/src/main/kotlin/com/template/android/build"
printf 'package com.template.android.build\n\nimport com.template.shared.AppLogger\n\ninternal fun tag() = AppLogger.tag\n' \
    >"$DIR/androidApp/src/main/kotlin/com/template/android/build/Extra.kt"
(cd "$DIR" && git add -A && git commit -qm "build package")
setup --name WeatherApp --package com.acme.weather --yes --json
extra=$DIR/androidApp/src/main/kotlin/com/acme/weather/build/Extra.kt
if generated_ok; then
    if [ -f "$extra" ] && grep -q '^package com.acme.weather.build$' "$extra" &&
        grep -q '^import com.acme.weather.shared.AppLogger$' "$extra"; then
        pass
    else
        fail "build/Extra.kt was not moved and renamed"
    fi
fi

begin "dry run with --yes: the apply command keeps one --yes"
setup --name WeatherApp --yes --package com.acme.weather --dry-run --json
if [ "$RC" = 0 ] && [ "$(next_runs)" = "./setup.sh --name WeatherApp --yes --package com.acme.weather --json" ]; then
    pass
else
    fail "next: $(next_runs)"
fi

# A bad entry in template-only.txt is a template bug: exit 5 before anything changes.
bad_listed_entry() { # <case name> <entry; VICTIM is replaced with a directory outside the repo>
    local victim
    begin "template-only.txt entry: $1"
    victim=$TMP/victim-$CASES
    mkdir -p "$victim" && touch "$victim/keep"
    printf '%s\n' "${2//VICTIM/$victim}" >>"$DIR/.template/template-only.txt"
    (cd "$DIR" && git commit -qam "bad entry")
    setup --name WeatherApp --package com.acme.weather --yes --json
    if [ "$RC" = 5 ] && [ "$(json category)" = internal ] && clean_tree && [ -f "$DIR/setup.sh" ] &&
        [ -f "$victim/keep" ]; then
        pass
    else
        fail "exit $RC, expected 5 with nothing changed and the victim intact"
    fi
}
bad_listed_entry "absolute path" VICTIM
# One component under /: its parent is "", which once resolved to the repository. The path does
# not exist, so even a regression cannot delete anything; it must still be rejected.
bad_listed_entry "absolute path of one component" /kmp-template-setup-test-missing
bad_listed_entry "parent directory" "../victim-$((CASES + 1))"
bad_listed_entry "the repository itself" .
bad_listed_entry "empty line" ""

begin "path length is measured in bytes, not characters (dry run)"
deep=$TMP/multibyte
# Each segment is 25 two-byte characters: half as many characters as bytes.
while [ "$(printf '%s' "$deep" | wc -c)" -lt 840 ]; do deep=$deep/ééééééééééééééééééééééééé; done
mkdir -p "$deep"
cp -R "$FIXTURE" "$deep/repo"
DIR=$deep/repo
setup --name WeatherApp --package com.acme.weather --dry-run --json
if [ "$RC" = 3 ] && grep -q "longest source path" "$ERR" && clean_tree; then pass; else fail "exit $RC, expected 3"; fi
rm -rf "$TMP/multibyte"

begin "a file name with a newline is planned once and rewritten"
odd=$'AGENTS.md\nCLAUDE.md'
printf 'KmpTemplate\n' >"$DIR/$odd"
(cd "$DIR" && git add -A && git commit -qm "odd name")
setup --name WeatherApp --package com.acme.weather --dry-run --json
count=$(jget 'scalar grep { $_ eq "AGENTS.md\nCLAUDE.md" } @{$j->{plan}{edit}}')
setup --name WeatherApp --package com.acme.weather --yes --json
if [ "$count" != 1 ]; then
    fail "plan.edit lists it $count times"
elif generated_ok && [ "$(cat "$DIR/$odd")" = WeatherApp ]; then
    pass
elif [ "$RC" = 0 ]; then
    fail "it was not rewritten: $(cat "$DIR/$odd")"
fi

begin "TMPDIR containing a colon"
mkdir -p "$TMP/with:colon"
TMPDIR=$TMP/with:colon setup --name WeatherApp --package com.acme.weather --yes --json
if generated_ok; then pass; fi

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

# --- template-cleanup.yml, against a local remote whose hook plays GitHub -----------------------
# workflow_step <file> <step name>: the step's `run: |` script, unindented.
workflow_step() {
    perl -e '
        my ($file, $name) = @ARGV;
        open my $fh, "<", $file or die "cannot read $file\n";
        my @lines = <$fh>;
        my $i = 0;
        $i++ while $i <= $#lines && $lines[$i] !~ /^\s*- name: \Q$name\E\s*$/;
        $i++ while $i <= $#lines && $lines[$i] !~ /^\s*run: \|\s*$/;
        die "no run: | in step $name\n" if $i > $#lines;
        my ($indent) = $lines[$i++] =~ /^(\s*)/;
        my @body;
        while ($i <= $#lines) {
            my $line = $lines[$i];
            last if $line =~ /\S/ && $line !~ /^\Q$indent\E\s/;
            push @body, $line;
            $i++;
        }
        my ($min) = sort { $a <=> $b } map { /^( *)\S/ ? length $1 : () } @body;
        s/^ {0,$min}// for @body;
        print @body;
    ' "$1" "$2"
}
WORKFLOW=$FIXTURE/.github/workflows/template-cleanup.yml
workflow_step "$WORKFLOW" "Check that the project is uninitialized" >"$TMP/state-step.sh"
workflow_step "$WORKFLOW" "Commit and push" >"$TMP/push-step.sh"
mkdir -p "$TMP/bin"
# The gh stub records its arguments, and fails when GH_FAIL is set (issues disabled, say).
printf '#!/bin/sh\nprintf "%%s\\n" "$@" >"$GH_LOG"\n[ -z "$GH_FAIL" ]\n' >"$TMP/bin/gh"
chmod +x "$TMP/bin/gh"

# cleanup_case <name> <hook: none|workflow|workflow-race|other> <race before the first push: 0|1>
# Leaves SIM (the simulation directory) and RC (the push step's exit code).
cleanup_case() {
    local hook=$2
    begin "cleanup workflow: $1"
    SIM=$TMP/sim-$CASES
    mkdir -p "$SIM/tmp"
    git clone -q --bare "$FIXTURE" "$SIM/origin.git"
    # A commit in which someone else already initialized main, for the races.
    git clone -q "$SIM/origin.git" "$SIM/other"
    (cd "$SIM/other" && git rm -rq .template setup.sh && git commit -qm "initialized elsewhere" &&
        git push -q origin HEAD:refs/heads/initialized)
    case $hook in
        workflow | workflow-race)
            {
                printf '#!/bin/sh\nwhile read old new ref; do\n'
                printf '  if git diff --name-only "$old" "$new" -- .github/workflows | grep -q .; then\n'
                printf '    echo "refusing to allow a GitHub App to create or update workflow \\`.github/workflows/template.yml\\` without \\`workflows\\` permission" >&2\n'
                if [ "$hook" = workflow-race ]; then
                    printf '    env -u GIT_QUARANTINE_PATH git update-ref refs/heads/main refs/heads/initialized\n'
                fi
                printf '    exit 1\n  fi\ndone\n'
            } >"$SIM/origin.git/hooks/pre-receive"
            ;;
        other)
            printf '#!/bin/sh\necho "protected branch hook declined for https://github.com/acme/workflow-tools" >&2\nexit 1\n' \
                >"$SIM/origin.git/hooks/pre-receive"
            ;;
    esac
    if [ -f "$SIM/origin.git/hooks/pre-receive" ]; then chmod +x "$SIM/origin.git/hooks/pre-receive"; fi
    git clone -q "$SIM/origin.git" "$SIM/work"
    if [ "$3" = 1 ]; then git -C "$SIM/origin.git" update-ref refs/heads/main refs/heads/initialized; fi
    (cd "$SIM/work" && "$SETUP_BASH" ./setup.sh --derive-from-github acme/workflow-tools --keep-git --yes --json \
        >/dev/null 2>&1)
    RC=0
    : >"$SIM/push-out"
    (cd "$SIM/work" && TEMPLATE_SLUG=kmp-template RUNNER_TEMP=$SIM/tmp GH_LOG=$SIM/gh.log PATH="$TMP/bin:$PATH" \
        GITHUB_OUTPUT=$SIM/push-out \
        bash -eo pipefail "$TMP/push-step.sh" >"$SIM/push.log" 2>&1) || RC=$?
}
origin_head() { git -C "$SIM/origin.git" log -1 --format=%s main; }
origin_has() { git -C "$SIM/origin.git" cat-file -e "main:$1" 2>/dev/null; }

cleanup_case "push allowed" none 0
if [ "$RC" = 0 ] && [ "$(origin_head)" = "Initialize project from kmp-template" ] &&
    ! origin_has .github/workflows/template.yml && [ ! -e "$SIM/gh.log" ]; then
    pass
else
    fail "exit $RC, origin: $(origin_head)"
fi

# True when the git rm line names every template-only workflow.
lists_all_template_workflows() {
    local wf
    for wf in template.yml template-cleanup.yml dependabot-automerge.yml release.yml; do
        case "$1" in *".github/workflows/$wf"*) ;; *) return 1 ;; esac
    done
}

cleanup_case "workflow files refused" workflow 0
if [ "$RC" = 0 ] && [ "$(origin_head)" = "Initialize project from kmp-template" ] &&
    origin_has .github/workflows/template.yml && ! origin_has setup.sh &&
    grep -q "^Delete the leftover template workflows$" "$SIM/gh.log" 2>/dev/null &&
    lists_all_template_workflows "$(grep "git rm -q " "$SIM/gh.log" 2>/dev/null)"; then
    pass
else
    fail "exit $RC, origin: $(origin_head), issue: $(cat "$SIM/gh.log" 2>/dev/null)"
fi

GH_FAIL=1 cleanup_case "workflow files refused, then the issue cannot be opened" workflow 0
if [ "$RC" = 0 ] && origin_has .github/workflows/template.yml && grep -qx "initialized=true" "$SIM/push-out" &&
    grep -q "::warning::Could not open an issue.*git rm -q .github/workflows/template-cleanup.yml" "$SIM/push.log"; then
    pass
else
    fail "exit $RC, outputs: $(cat "$SIM/push-out"), log: $(tail -2 "$SIM/push.log")"
fi

cleanup_case "main initialized before the push" none 1
GITHUB_OUTPUT=$SIM/out
: >"$GITHUB_OUTPUT"
(cd "$SIM/work" && GITHUB_OUTPUT=$GITHUB_OUTPUT GITHUB_ENV=$SIM/env bash -eo pipefail "$TMP/state-step.sh" >/dev/null)
if [ "$RC" = 0 ] && [ "$(origin_head)" = "initialized elsewhere" ] && [ ! -e "$SIM/gh.log" ] &&
    grep -qx "initialized=true" "$GITHUB_OUTPUT"; then
    pass
else
    fail "exit $RC, origin: $(origin_head), state: $(cat "$GITHUB_OUTPUT")"
fi

cleanup_case "workflow files refused, then main initialized before the retry" workflow-race 0
if [ "$RC" = 0 ] && [ "$(origin_head)" = "initialized elsewhere" ] && [ ! -e "$SIM/gh.log" ]; then
    pass
else
    fail "exit $RC, origin: $(origin_head), issue: $(cat "$SIM/gh.log" 2>/dev/null)"
fi

cleanup_case "refused for another reason (repo named like workflow)" other 0
if [ "$RC" = 1 ] && origin_has .template/manifest.env && [ ! -e "$SIM/gh.log" ] &&
    grep -q "::error::The push was refused" "$SIM/push.log"; then
    pass
else
    fail "exit $RC: $(tail -3 "$SIM/push.log")"
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
