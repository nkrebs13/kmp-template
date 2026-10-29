#!/usr/bin/env bash
# Turns this template into your project. Run ./setup.sh --help for usage.
#
# Works with bash 3.2 (macOS /bin/bash): no associative arrays, mapfile, ${x,,} or |&.
# Everything runs from main() at the bottom, so bash has parsed the whole file before the script
# deletes itself. The tokens it renames and the files it removes are listed in .template/.

set -Eeuo pipefail

readonly EX_USAGE=2 EX_VALIDATION=3 EX_PRECONDITION=4 EX_INTERNAL=5

# Java and Kotlin keywords, literals and reserved words that cannot be a package segment.
readonly KEYWORDS='abstract assert boolean break byte case catch char class const continue default
do double else enum extends final finally float for goto if implements import instanceof int
interface long native new package private protected public return short static strictfp super
switch synchronized this throw throws transient try void volatile while true false null _ var
yield record sealed permits fun val when in is as object companion data inner typealias typeof
actual expect'

readonly USAGE_LINE='usage: setup.sh --name <Name> --package <reverse.dns> [--bundle-id <id>] [--display-name "<text>"]
                [--author "<holder>"] [--no-desktop] [--keep-git] [--no-commit]
                [--derive-from-github <owner/repo>] [--yes] [--dry-run] [--json] [--help]'

usage() {
    cat <<EOF
$USAGE_LINE

Turns this template into your project: renames the packages, app name and iOS bundle ID,
removes the template-only files, checks that nothing of the template is left, and starts a
fresh git history with one commit.

Required (prompted for only when stdin is a terminal):
  --name <Name>            Project name in PascalCase: letters and digits, starting with a
                           letter (WeatherApp). Used for the Gradle root project, the logger
                           tag and the desktop installer.
  --package <reverse.dns>  Android application ID and root Kotlin package (com.acme.weather).
                           Modules use <package>.shared, <package>.desktop and
                           <package>.baselineprofile.

Options:
  --bundle-id <id>         iOS bundle identifier. Default: the package with _ replaced by -.
  --display-name "<text>"  Name under the app icon and in the desktop window title.
                           Default: the name.
  --author "<holder>"      LICENSE copyright holder. Default: git config user.name, then the
                           owner given to --derive-from-github.
  --no-desktop             Leave out the desktop (JVM) app and the shared jvm() target.
  --derive-from-github <owner/repo>
                           Derive the name, package (io.github.<owner>.<repo>), bundle ID and
                           author from a GitHub repository. Explicit options win.
  --keep-git               Keep the existing .git: no new history and no commit.
  --no-commit              Start a new git history, but do not commit.
  --yes                    Do not ask for confirmation. Required when stdin is not a terminal.
  --dry-run                Validate, then list every file that would be deleted, written,
                           edited or moved. Changes nothing.
  --json                   Print exactly one JSON object on stdout; everything else goes to
                           stderr.
  -h, --help               Show this help.

Exit codes:
  0  success
  2  usage: unknown option, missing value, or a required option without a terminal to ask on
  3  invalid value
  4  precondition: uncommitted git changes, already initialized (no .template/), perl or git
     missing
  5  internal error; the message says how to restore the template

Example:
  ./setup.sh --name WeatherApp --package com.acme.weather --yes --json
EOF
}

# --- state -----------------------------------------------------------------------------------

NAME='' NAME_SET=0
PACKAGE='' PACKAGE_SET=0
BUNDLE_ID='' BUNDLE_SET=0
DISPLAY_NAME='' DISPLAY_SET=0
AUTHOR='' AUTHOR_SET=0
DERIVE='' DERIVE_SET=0
NO_DESKTOP=0 KEEP_GIT=0 NO_COMMIT=0 YES=0 DRY_RUN=0 JSON=0 HELP=0
DERIVED_NAME='' DERIVED_PACKAGE='' DERIVED_BUNDLE='' DERIVED_OWNER=''
PACKAGE_PATH=''
OUT=1               # file descriptor for human output: stdout, or stderr with --json
ROOT=''             # the template checkout: the directory that holds this script
TPL=''              # the .template directory in use (a temporary copy once files change)
WORK=''             # temporary directory for the .template copy and the old .git
BACKUP=''           # copy of the tree when there is no .git to restore from
HAD_GIT=0
OLD_GIT=''          # where the old .git waits until the new history exists
PHASE=prepare       # prepare -> change -> git -> finished; decides the recovery advice
COMMITTED=0
DELETIONS=''        # newline-separated paths this run deletes
# Set by .template/manifest.env.
TEMPLATE_SLUG='' TEMPLATE_NAME='' TEMPLATE_DISPLAY_NAME='' TEMPLATE_PACKAGE_ROOT=''
TEMPLATE_APP_PACKAGE='' TEMPLATE_BUNDLE_ID='' DESKTOP_PATHS=''

# --- output ----------------------------------------------------------------------------------

say() { printf '%s\n' "$*" >&"$OUT"; }

json_str() {
    if command -v perl >/dev/null 2>&1; then
        perl -e 'my $s = shift; $s =~ s/(["\\])/\\$1/g;
            $s =~ s/([\x00-\x1f])/sprintf("\\u%04x", ord $1)/ge; print qq("$s")' -- "$1"
    else
        printf '"%s"' "$1" # only reached for the fixed "perl is missing" message
    fi
}

json_array() {
    local out='' item
    for item in "$@"; do
        out="$out${out:+,}$(json_str "$item")"
    done
    printf '[%s]' "$out"
}

q() { printf '%q' "$1"; }

print_recovery() {
    {
        echo
        case $PHASE in
            git)
                echo "The project files are complete; only the git step failed. Either finish it:"
                echo "  cd $(q "$ROOT") && rm -rf .git && git init -q && git symbolic-ref HEAD refs/heads/main && git add -A && git commit -m 'Initial commit from $TEMPLATE_SLUG'"
                echo "or restore the template:"
                ;;
            *) echo "setup.sh stopped part-way. Restore the template with:" ;;
        esac
        if [ -n "$OLD_GIT" ] && [ -d "$OLD_GIT" ]; then
            echo "  cd $(q "$ROOT") && rm -rf .git && mv $(q "$OLD_GIT") .git && git reset -q --hard HEAD && git clean -qfd"
        elif [ "$HAD_GIT" = 1 ]; then
            echo "  cd $(q "$ROOT") && git reset -q --hard HEAD && git clean -qfd"
        elif [ -n "$BACKUP" ]; then
            echo "  cd $(q "$ROOT") && find . -mindepth 1 -maxdepth 1 -exec rm -rf {} + && cp -Rp $(q "$BACKUP")/. ."
        fi
    } >&2
}

# die <exit code> <message>: the only way this script fails on purpose.
die() {
    local code=$1
    shift
    trap - ERR INT TERM
    if [ "${BASH_SUBSHELL:-0}" -gt 0 ]; then exit "$code"; fi
    printf 'setup.sh: %s\n' "$*" >&2
    case $PHASE in change | git) print_recovery ;; esac
    if [ "$JSON" = 1 ]; then
        printf '{"status":"error","code":%s,"message":%s}\n' "$code" "$(json_str "$*")"
    fi
    exit "$code"
}

usage_error() {
    printf '%s\nRun ./setup.sh --help for details.\n' "$USAGE_LINE" >&2
    die "$EX_USAGE" "$*"
}

on_err() {
    local rc=$1 line=$2 cmd=$3
    if [ "${BASH_SUBSHELL:-0}" -gt 0 ]; then exit "$rc"; fi
    die "$EX_INTERNAL" "internal error: '$cmd' exited with status $rc (setup.sh line $line)"
}

# --- arguments -------------------------------------------------------------------------------

parse_args() {
    local opt val inline
    while [ $# -gt 0 ]; do
        opt=$1 val='' inline=0
        case $opt in
            --*=*) val=${opt#*=} opt=${opt%%=*} inline=1 ;;
        esac
        case $opt in
            --name | --package | --bundle-id | --display-name | --author | --derive-from-github)
                if [ "$inline" = 0 ]; then
                    if [ $# -lt 2 ]; then usage_error "$opt needs a value"; fi
                    case $2 in --*) usage_error "$opt needs a value" ;; esac
                    val=$2
                    shift
                fi
                case $opt in
                    --name) NAME=$val NAME_SET=1 ;;
                    --package) PACKAGE=$val PACKAGE_SET=1 ;;
                    --bundle-id) BUNDLE_ID=$val BUNDLE_SET=1 ;;
                    --display-name) DISPLAY_NAME=$val DISPLAY_SET=1 ;;
                    --author) AUTHOR=$val AUTHOR_SET=1 ;;
                    --derive-from-github) DERIVE=$val DERIVE_SET=1 ;;
                esac
                ;;
            --no-desktop | --keep-git | --no-commit | --yes | --dry-run | --json | --help | -h)
                if [ "$inline" = 1 ]; then usage_error "$opt takes no value"; fi
                case $opt in
                    --no-desktop) NO_DESKTOP=1 ;;
                    --keep-git) KEEP_GIT=1 ;;
                    --no-commit) NO_COMMIT=1 ;;
                    --yes) YES=1 ;;
                    --dry-run) DRY_RUN=1 ;;
                    --json) JSON=1 ;;
                    --help | -h) HELP=1 ;;
                esac
                ;;
            *) usage_error "unknown option: $opt" ;;
        esac
        shift
    done
}

# --- derivation from a GitHub owner/repo -----------------------------------------------------


is_keyword() {
    case " $(printf '%s' "$KEYWORDS" | tr '\n' ' ') " in *" $1 "*) return 0 ;; esac
    return 1
}

# PascalCase: split on anything but letters and digits, capitalize each part.
pascal_case() {
    perl -e 'my $o = join "", map { ucfirst } grep { length } split /[^A-Za-z0-9]+/, shift;
        $o = "App$o" if $o !~ /^[A-Za-z]/; print $o' -- "$1"
}

# One valid package segment: lowercase, [a-z0-9_], starting with a letter, not a keyword.
package_segment() {
    local s
    s=$(perl -e 'my $s = lc shift; $s =~ s/[^a-z0-9]+/_/g; $s =~ s/^_+|_+$//g;
        $s = "app" if $s eq ""; $s = "app_$s" if $s =~ /^[0-9]/; print $s' -- "$1")
    if is_keyword "$s"; then s="${s}_"; fi
    printf '%s' "$s"
}

# One valid bundle ID segment: lowercase, [a-z0-9-], starting with a letter (no underscores).
bundle_segment() {
    perl -e 'my $s = lc shift; $s =~ s/[^a-z0-9]+/-/g; $s =~ s/^-+|-+$//g;
        $s = "app" if $s eq ""; $s = "app-$s" if $s =~ /^[0-9]/; print $s' -- "$1"
}

derive_from_github() {
    local re='^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$' owner repo
    if ! [[ $DERIVE =~ $re ]]; then
        die "$EX_VALIDATION" "--derive-from-github expects owner/repo (letters, digits, '-', and '.' or '_' in the repo), got '$DERIVE'"
    fi
    owner=${DERIVE%%/*}
    repo=${DERIVE#*/}
    DERIVED_OWNER=$owner
    DERIVED_NAME=$(pascal_case "$repo")
    DERIVED_PACKAGE="io.github.$(package_segment "$owner").$(package_segment "$repo")"
    DERIVED_BUNDLE="io.github.$(bundle_segment "$owner").$(bundle_segment "$repo")"
}

# --- values ----------------------------------------------------------------------------------

resolve_values() {
    local missing=''
    if [ "$DERIVE_SET" = 1 ]; then derive_from_github; fi
    if [ "$NAME_SET" = 0 ]; then
        if [ -n "$DERIVED_NAME" ]; then
            NAME=$DERIVED_NAME
        elif [ -t 0 ]; then
            read -r -p "Project name, PascalCase (e.g. WeatherApp): " NAME || NAME=''
        else
            missing="$missing --name"
        fi
    fi
    if [ "$PACKAGE_SET" = 0 ]; then
        if [ -n "$DERIVED_PACKAGE" ]; then
            PACKAGE=$DERIVED_PACKAGE
        elif [ -t 0 ]; then
            read -r -p "Package, reverse DNS (e.g. com.acme.weather): " PACKAGE || PACKAGE=''
        else
            missing="$missing --package"
        fi
    fi
    if [ -n "$missing" ]; then
        usage_error "missing required option(s):$missing (stdin is not a terminal, so setup.sh cannot ask)"
    fi
    if [ "$BUNDLE_SET" = 0 ]; then
        if [ -n "$DERIVED_BUNDLE" ]; then
            BUNDLE_ID=$DERIVED_BUNDLE
        else
            BUNDLE_ID=$(printf '%s' "$PACKAGE" | tr '_' '-')
        fi
    fi
    if [ "$DISPLAY_SET" = 0 ]; then DISPLAY_NAME=$NAME; fi
    if [ "$AUTHOR_SET" = 0 ]; then
        AUTHOR=$(git config --get user.name 2>/dev/null || true)
        if [ -z "$AUTHOR" ]; then AUTHOR=$DERIVED_OWNER; fi
        if [ -z "$AUTHOR" ] && [ -t 0 ]; then
            read -r -p "Copyright holder for LICENSE: " AUTHOR || AUTHOR=''
        fi
        if [ -z "$AUTHOR" ]; then
            die "$EX_VALIDATION" "no LICENSE copyright holder: pass --author \"<name>\" (git config user.name is not set)"
        fi
    fi
    PACKAGE_PATH=$(printf '%s' "$PACKAGE" | tr '.' '/')
}

# Every input rule lives here. Exits 3 on the first violation.
validate_values() {
    local re seg
    if [ -z "$NAME" ]; then die "$EX_VALIDATION" "--name is empty"; fi
    re='^[A-Za-z][A-Za-z0-9]*$'
    if ! [[ $NAME =~ $re ]]; then
        die "$EX_VALIDATION" "--name '$NAME' must start with a letter and contain only letters and digits (e.g. WeatherApp)"
    fi

    if [ -z "$PACKAGE" ]; then die "$EX_VALIDATION" "--package is empty"; fi
    re='^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$'
    if ! [[ $PACKAGE =~ $re ]]; then
        die "$EX_VALIDATION" "--package '$PACKAGE' must be lowercase, with at least two dot-separated segments that each start with a letter and contain only a-z, 0-9 and _ (e.g. com.acme.weather)"
    fi
    case $PACKAGE in
        java.* | javax.* | android.* | kotlin.* | kotlinx.*)
            die "$EX_VALIDATION" "--package '$PACKAGE' uses a reserved namespace (java., javax., android., kotlin., kotlinx.)"
            ;;
    esac
    case $PACKAGE in
        "$TEMPLATE_PACKAGE_ROOT" | "$TEMPLATE_PACKAGE_ROOT".*)
            die "$EX_VALIDATION" "--package '$PACKAGE' is inside the template's own package $TEMPLATE_PACKAGE_ROOT; choose another"
            ;;
    esac
    for seg in $(printf '%s' "$PACKAGE" | tr '.' ' '); do
        if is_keyword "$seg"; then
            die "$EX_VALIDATION" "--package segment '$seg' is a Java or Kotlin keyword; try '${seg}s' or 'my$seg'"
        fi
    done
    if [ "${#PACKAGE}" -gt 100 ]; then
        printf 'setup.sh: warning: --package is %s characters; long packages can hit path length limits\n' "${#PACKAGE}" >&2
    fi

    re='^[A-Za-z][A-Za-z0-9-]*(\.[A-Za-z][A-Za-z0-9-]*)+$'
    if ! [[ $BUNDLE_ID =~ $re ]]; then
        die "$EX_VALIDATION" "--bundle-id '$BUNDLE_ID' must have at least two dot-separated segments that each start with a letter and contain only letters, digits and - (no _)"
    fi

    # The display name lands in strings.xml, Config.xcconfig and a Kotlin string literal.
    if [ -z "$DISPLAY_NAME" ]; then die "$EX_VALIDATION" "--display-name is empty"; fi
    case $DISPLAY_NAME in
        [[:space:]]* | *[[:space:]])
            die "$EX_VALIDATION" "--display-name '$DISPLAY_NAME' has leading or trailing whitespace"
            ;;
        *[[:cntrl:]]*)
            die "$EX_VALIDATION" "--display-name contains a control character"
            ;;
        *[\"\'\\\$\<\>\&%\`]* | *//* | @* | \?*)
            die "$EX_VALIDATION" "--display-name '$DISPLAY_NAME' cannot contain \" ' \\ \$ < > & % \` or //, or start with @ or ?"
            ;;
    esac

    case $AUTHOR in
        *[[:cntrl:]]*) die "$EX_VALIDATION" "--author contains a control character" ;;
    esac
}

# --- preconditions ---------------------------------------------------------------------------

check_initialized() {
    if [ ! -f .template/manifest.env ]; then
        die "$EX_PRECONDITION" "$ROOT has no .template/manifest.env: this project is already initialized, or it is not the template"
    fi
    # shellcheck disable=SC1091 # read at run time; the variables are declared at the top
    . .template/manifest.env
    TPL=$ROOT/.template
    if ! command -v perl >/dev/null 2>&1; then
        die "$EX_PRECONDITION" "perl is required and was not found on PATH"
    fi
}

check_git() {
    local dirty
    if [ -e .git ]; then HAD_GIT=1; fi
    if [ "$HAD_GIT" = 1 ] || [ "$KEEP_GIT" = 0 ]; then
        if ! command -v git >/dev/null 2>&1; then
            die "$EX_PRECONDITION" "git is required and was not found on PATH"
        fi
    fi
    if [ "$HAD_GIT" = 1 ]; then
        if ! dirty=$(git status --porcelain --untracked-files=normal 2>&1); then
            die "$EX_PRECONDITION" "git cannot read this repository: $dirty"
        fi
        if [ -n "$dirty" ]; then
            die "$EX_PRECONDITION" "uncommitted changes; commit or stash them first:
$dirty"
        fi
    fi
}

# --- plan ------------------------------------------------------------------------------------

is_deleted() {
    local p
    while IFS= read -r p; do
        if [ -n "$p" ]; then
            case $1 in "$p" | "$p"/*) return 0 ;; esac
        fi
    done <<EOF
$DELETIONS
EOF
    return 1
}

# Template-only paths (and desktop paths with --no-desktop) that exist, one per line.
compute_deletions() {
    local p list=''
    while IFS= read -r p; do
        case $p in '' | '#'*) continue ;; esac
        if [ -e "$p" ] || [ -L "$p" ]; then list="$list$p"$'\n'; fi
    done <"$TPL/template-only.txt"
    if [ "$NO_DESKTOP" = 1 ]; then
        for p in $DESKTOP_PATHS; do
            if [ -e "$p" ]; then list="$list$p"$'\n'; fi
        done
    fi
    DELETIONS=$list
}

# Build output and IDE state that would keep the old names alive. Never under a src/ directory.
build_dirs() {
    find . -name .git -prune -o -type d \( -name build -o -name .gradle -o -name .kotlin \) \
        -not -path '*/src/*' -prune -print | sed 's|^\./||' | sort
    if [ -d .idea ]; then echo .idea; fi
}

# "old -> new" for every file under a */kotlin/<template package path> source directory.
compute_moves() {
    local root_path app_path dir base f rel new
    root_path=$(printf '%s' "$TEMPLATE_PACKAGE_ROOT" | tr '.' '/')
    app_path=$(printf '%s' "$TEMPLATE_APP_PACKAGE" | tr '.' '/')
    find . \( -name .git -o -name build -o -name .gradle \) -prune -o \
        -type d -path "*/kotlin/$root_path" -print | sed 's|^\./||' | sort |
        while IFS= read -r dir; do
            if is_deleted "$dir"; then continue; fi
            base=${dir%"$root_path"}
            find "$dir" -type f | sort | while IFS= read -r f; do
                rel=${f#"$base"}
                case $rel in
                    "$app_path"/*) new="$base$PACKAGE_PATH/${rel#"$app_path"/}" ;;
                    *) new="$base$PACKAGE_PATH/${rel#"$root_path"/}" ;;
                esac
                printf '%s -> %s\n' "$f" "$new"
            done
        done
}

# NUL-separated candidate files for text rewrites.
text_files() {
    find . \( -name .git -o -name build -o -name .gradle -o -name .kotlin -o -name .idea \
        -o -name .template \) -prune -o -type f -print0
}

rewrite() { # tokens|regions report|apply
    text_files | SKIP=$DELETIONS \
        R_FROM_1=$TEMPLATE_BUNDLE_ID R_TO_1=$BUNDLE_ID \
        R_FROM_2=$TEMPLATE_APP_PACKAGE R_TO_2=$PACKAGE \
        R_FROM_3=$(printf '%s' "$TEMPLATE_APP_PACKAGE" | tr '.' '/') R_TO_3=$PACKAGE_PATH \
        R_FROM_4=$TEMPLATE_PACKAGE_ROOT R_TO_4=$PACKAGE \
        R_FROM_5=$(printf '%s' "$TEMPLATE_PACKAGE_ROOT" | tr '.' '/') R_TO_5=$PACKAGE_PATH \
        R_FROM_6=$TEMPLATE_DISPLAY_NAME R_TO_6=$DISPLAY_NAME \
        R_FROM_7=$TEMPLATE_NAME R_TO_7=$NAME \
        perl "$TPL/rewrite.pl" "$1" "$2"
}

list_block() { # title, lines on stdin
    local lines
    lines=$(cat)
    if [ -z "$lines" ]; then return 0; fi
    say ""
    say "$1 ($(printf '%s\n' "$lines" | wc -l | tr -d ' ')):"
    printf '%s\n' "$lines" | sed 's/^/  /' >&"$OUT"
}

print_plan() {
    local git_plan desktop=yes
    if [ "$NO_DESKTOP" = 1 ]; then desktop='no (--no-desktop)'; fi
    if [ "$KEEP_GIT" = 1 ]; then
        git_plan='keep the existing .git (--keep-git); nothing is committed'
    elif [ "$NO_COMMIT" = 1 ]; then
        git_plan='new history on main, files staged but not committed (--no-commit)'
    else
        git_plan="new history on main with one commit: Initial commit from $TEMPLATE_SLUG"
    fi
    say "kmp-template setup$([ "$DRY_RUN" = 1 ] && echo ' (dry run: nothing changes)')"
    say "  Name:          $NAME"
    if [ "$NO_DESKTOP" = 1 ]; then
        say "  Package:       $PACKAGE (modules: $PACKAGE.shared, $PACKAGE.baselineprofile)"
    else
        say "  Package:       $PACKAGE (modules: $PACKAGE.shared, $PACKAGE.desktop, $PACKAGE.baselineprofile)"
    fi
    say "  Bundle ID:     $BUNDLE_ID"
    say "  Display name:  $DISPLAY_NAME"
    say "  LICENSE:       Copyright (c) $(date +%Y) $AUTHOR (MIT)"
    say "  Desktop:       $desktop"
    say "  Git:           $git_plan"
    if [ "$DRY_RUN" = 0 ]; then return 0; fi

    printf '%s' "$DELETIONS" | list_block "Delete"
    build_dirs | list_block "Delete build output"
    (cd "$TPL/project" && find . -type f | sed 's|^\./||' | sort) | list_block "Write (from .template/project/)"
    # Files .template/project/ overwrites are listed under Write, not here.
    {
        if [ "$NO_DESKTOP" = 1 ]; then
            rewrite regions report
            echo .github/workflows/ci.yml
        fi
        rewrite tokens report
        echo LICENSE
    } | sort -u | { grep -vxF -f <(cd "$TPL/project" && find . -type f | sed 's|^\./||') || true; } |
        list_block "Edit"
    compute_moves | list_block "Move"
}

confirm() {
    local answer
    if [ "$DRY_RUN" = 1 ] || [ "$YES" = 1 ]; then return 0; fi
    if [ ! -t 0 ]; then
        usage_error "pass --yes to run without a terminal (or --dry-run to preview)"
    fi
    read -r -p "Proceed? [y/N] " answer || answer=''
    case $answer in
        y | Y | yes | YES) ;;
        *) die "$EX_USAGE" "cancelled; nothing changed" ;;
    esac
}

# --- the run ---------------------------------------------------------------------------------

apply_changes() {
    local tmp p moves old new year line dirs
    tmp=${TMPDIR:-/tmp}
    WORK=$(mktemp -d "${tmp%/}/kmp-template-setup.XXXXXX")
    cp -R "$ROOT/.template" "$WORK/template"
    TPL=$WORK/template
    if [ "$HAD_GIT" = 0 ]; then
        BACKUP=$WORK/backup
        mkdir "$BACKUP"
        cp -Rp "$ROOT/." "$BACKUP/"
    fi
    moves=$(compute_moves)

    PHASE=change
    say "Writing AGENTS.md, CLAUDE.md and README.md for the project..."
    cp -R "$TPL/project/." .

    say "Deleting template-only files and build output..."
    while IFS= read -r p; do
        if [ -n "$p" ]; then rm -rf "$p"; fi
    done <<EOF
$DELETIONS
$(build_dirs)
EOF

    if [ "$NO_DESKTOP" = 1 ]; then
        say "Removing desktop-only code..."
        rewrite regions apply >/dev/null
        FROM='name: Android & Desktop' TO='name: Android' \
            perl -pi -e 's/^(\s*)\Q$ENV{FROM}\E$/$1$ENV{TO}/' .github/workflows/ci.yml
    fi

    say "Renaming packages, names and the bundle ID..."
    rewrite tokens apply >/dev/null

    say "Moving Kotlin sources to $PACKAGE_PATH..."
    while IFS= read -r line; do
        if [ -z "$line" ]; then continue; fi
        old=${line%% -> *}
        new=${line#* -> }
        if [ "$old" != "$new" ]; then
            mkdir -p "$(dirname "$new")"
            mv "$old" "$new"
        fi
    done <<EOF
$moves
EOF
    # Remove the emptied template package directories (and kotlin/com if nothing else uses it).
    p=$(printf '%s' "$TEMPLATE_PACKAGE_ROOT" | tr '.' '/')
    dirs=$(find . \( -name .git -o -name build \) -prune -o -type d -path "*/kotlin/$p" -print -prune)
    while IFS= read -r p; do
        if [ -z "$p" ]; then continue; fi
        # One rmdir per directory: with -depth a parent is tested only after its children are gone.
        find "$p" -depth -type d -empty -exec rmdir {} \;
        rmdir "$(dirname "$p")" 2>/dev/null || true
    done <<EOF
$dirs
EOF

    say "Updating LICENSE..."
    year=$(date +%Y)
    YEAR=$year AUTHOR=$AUTHOR perl -pi -e 's/^Copyright \(c\) \d{4} .*$/Copyright (c) $ENV{YEAR} $ENV{AUTHOR}/' LICENSE
    if ! grep -qF "Copyright (c) $year $AUTHOR" LICENSE; then
        die "$EX_INTERNAL" "LICENSE has no 'Copyright (c) <year> <holder>' line to update"
    fi
}

verify_result() {
    local leftovers desktop_flag='' dir_args=() dir=$PACKAGE_PATH
    say "Checking for template leftovers..."
    if [ "$NO_DESKTOP" = 1 ]; then desktop_flag=--no-desktop; fi
    # The parent directories of the package path (io/github/<owner>) are the user's too.
    while :; do
        dir_args+=(--allow "$dir")
        case $dir in */*) dir=${dir%/*} ;; *) break ;; esac
    done
    if ! leftovers=$("$BASH" "$TPL/check-leftovers.sh" ${desktop_flag:+"$desktop_flag"} \
        --allow "$NAME" --allow "$DISPLAY_NAME" --allow "$PACKAGE" "${dir_args[@]}" \
        --allow "$BUNDLE_ID" --allow "$AUTHOR" . 2>&1); then
        printf '%s\n' "$leftovers" >&2
        die "$EX_INTERNAL" "template leftovers remain (listed above); this is a setup.sh bug"
    fi
    if [ -e .claude ]; then die "$EX_INTERNAL" ".claude/ survived; generated projects must not have one"; fi
    if [ ! -f AGENTS.md ] || [ "$(cat CLAUDE.md 2>/dev/null)" != "@AGENTS.md" ]; then
        die "$EX_INTERNAL" "AGENTS.md or the CLAUDE.md that imports it is missing"
    fi
    if [ -e setup.sh ] || [ -e .template ]; then
        die "$EX_INTERNAL" "setup.sh or .template/ survived"
    fi
}

has_git_identity() {
    git -c user.useConfigOnly=true var GIT_AUTHOR_IDENT >/dev/null 2>&1 &&
        git -c user.useConfigOnly=true var GIT_COMMITTER_IDENT >/dev/null 2>&1
}

start_history() {
    PHASE=git
    if [ "$KEEP_GIT" = 1 ]; then return 0; fi
    say "Starting a new git history..."
    if [ -e .git ]; then
        OLD_GIT=$WORK/old-git
        mv .git "$OLD_GIT"
    fi
    git init -q
    git symbolic-ref HEAD refs/heads/main
    git add -A
    if [ "$NO_COMMIT" = 0 ] && has_git_identity; then
        git commit -q -m "Initial commit from $TEMPLATE_SLUG"
        COMMITTED=1
    elif [ "$NO_COMMIT" = 0 ]; then
        printf 'setup.sh: no git identity, so nothing was committed. Set one, then commit:\n  git config user.name "Your Name" && git config user.email you@example.com\n' >&2
    fi
}

finish() {
    local removed=() next=() p desktop=true
    while IFS= read -r p; do
        if [ -n "$p" ]; then removed+=("$p"); fi
    done <<EOF
$DELETIONS
EOF
    if [ "$DRY_RUN" = 1 ]; then next+=("Run the same command without --dry-run to apply this plan"); fi
    next+=("Read AGENTS.md: commands, where settings live, and the definition of done")
    if [ "$KEEP_GIT" = 1 ]; then
        next+=("git add -A && git commit -m 'Initialize project from $TEMPLATE_SLUG'")
    elif [ "$DRY_RUN" = 0 ] && [ "$COMMITTED" = 0 ]; then
        next+=("git commit -m 'Initial commit from $TEMPLATE_SLUG'")
    fi
    next+=("./gradlew check")
    next+=("./gradlew :androidApp:installDebug")
    next+=("open iosApp/iosApp.xcodeproj")
    if [ "$NO_DESKTOP" = 1 ]; then
        desktop=false
    else
        next+=("./gradlew :desktopApp:run")
    fi

    if [ "$DRY_RUN" = 0 ]; then
        PHASE=finished
        rm -rf "$WORK"
        say ""
        say "Done: $NAME is ready."
    fi
    say "Next:"
    for p in "${next[@]}"; do say "  $p"; done
    if [ "$JSON" = 1 ]; then
        printf '{"status":"ok","name":%s,"package":%s,"bundleId":%s,"displayName":%s,"author":%s,"desktop":%s,"dryRun":%s,"removed":%s,"next":%s}\n' \
            "$(json_str "$NAME")" "$(json_str "$PACKAGE")" "$(json_str "$BUNDLE_ID")" \
            "$(json_str "$DISPLAY_NAME")" "$(json_str "$AUTHOR")" "$desktop" \
            "$([ "$DRY_RUN" = 1 ] && echo true || echo false)" \
            "$(json_array ${removed[@]+"${removed[@]}"})" "$(json_array "${next[@]}")"
    fi
}

main() {
    local arg
    for arg in "$@"; do
        if [ "$arg" = --json ]; then JSON=1 OUT=2; fi
    done
    trap 'on_err $? "$LINENO" "$BASH_COMMAND"' ERR
    trap 'die "$EX_INTERNAL" "interrupted"' INT TERM

    ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
    cd "$ROOT"
    parse_args "$@"
    if [ "$HELP" = 1 ]; then
        usage
        exit 0
    fi
    check_initialized
    resolve_values
    validate_values
    check_git
    compute_deletions
    print_plan
    if [ "$DRY_RUN" = 1 ]; then
        finish
        exit 0
    fi
    confirm
    apply_changes
    verify_result
    start_history
    finish
}

main "$@"
