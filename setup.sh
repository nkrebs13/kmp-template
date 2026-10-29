#!/usr/bin/env bash
# Turns this template into your project. Run ./setup.sh --help for usage; AGENTS.md describes
# the --json contract.
#
# Works with bash 3.2 (macOS /bin/bash): no associative arrays, mapfile, ${x,,} or |&.
# Everything runs from main() at the bottom, so bash has parsed the whole file before the script
# deletes itself. The tokens it renames and the files it removes are listed in .template/.
#
# Order of work: parse and validate every input, compute the full plan and check it (paths,
# lengths, markers, LICENSE), copy .template/ aside and test the copy, and only then change
# files. After the first change, only I/O errors or a setup.sh bug can stop it, and the error
# says how to restore the template.

set -Eeuo pipefail

readonly EX_USAGE=2 EX_VALIDATION=3 EX_PRECONDITION=4 EX_INTERNAL=5

# Length limits, checked before anything changes. A package or bundle ID segment is at most 63
# characters (a DNS label), well under the 255-byte file name limit; the longest moved source
# path, as an absolute path, is at most 900 bytes, which leaves room for the deeper Gradle build
# outputs under macOS's 1024-byte PATH_MAX.
readonly MAX_NAME=50 MAX_SEGMENT=63 MAX_PACKAGE=150 MAX_DISPLAY=100 MAX_AUTHOR=200 MAX_PATH=900

# Java and Kotlin keywords, literals and reserved words that cannot be a package segment.
KEYWORDS='abstract assert boolean break byte case catch char class const continue default
do double else enum extends final finally float for goto if implements import instanceof int
interface long native new package private protected public return short static strictfp super
switch synchronized this throw throws transient try void volatile while true false null _ var
yield record sealed permits fun val when in is as object companion data inner typealias typeof
actual expect'
KEYWORDS=" ${KEYWORDS//$'\n'/ } "
readonly KEYWORDS

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
                           letter, at most $MAX_NAME characters (WeatherApp). Used for the Gradle
                           root project, the logger tag and the desktop installer.
  --package <reverse.dns>  Android application ID and root Kotlin package (com.acme.weather).
                           Modules use <package>.shared, <package>.desktop and
                           <package>.baselineprofile.

Options:
  --bundle-id <id>         iOS bundle identifier. Default: the package with _ replaced by -.
  --display-name "<text>"  Name under the app icon and in the desktop window title.
                           Default: the name.
  --author "<holder>"      LICENSE copyright holder. Default: git config user.name, then the
                           owner given to --derive-from-github.
  --no-desktop             Leave out the desktop (JVM) app, the shared jvm() target and the
                           desktop build logic.
  --derive-from-github <owner/repo>
                           Derive the name, package (io.github.<owner>.<repo>), bundle ID and
                           author from a GitHub repository. Explicit options win.
  --keep-git               Keep the existing .git: no new history and no commit.
  --no-commit              Start a new git history, but do not commit.
  --yes                    Do not ask for confirmation. Required when stdin is not a terminal.
  --dry-run                Validate, then list every file that would be deleted, written,
                           edited or moved. Changes nothing.
  --json                   Print exactly one JSON object on stdout; everything else goes to
                           stderr. AGENTS.md describes its fields.
  -h, --help               Show this help.

Exit codes:
  0  success
  2  usage: unknown option, missing value, or a required option without a terminal to ask on
  3  invalid value (checked before anything changes, also with --dry-run)
  4  precondition: uncommitted git changes, already initialized (no .template/), perl or git
     missing
  5  internal error; the message says how to restore the template

Example:
  ./setup.sh --name WeatherApp --package com.acme.weather --yes --json
EOF
}

# --- state -----------------------------------------------------------------------------------

# Unset means "not given": ${NAME+x} tells an empty --name "" apart from no --name at all.
unset NAME PACKAGE BUNDLE_ID DISPLAY_NAME AUTHOR DERIVE
NO_DESKTOP=0 KEEP_GIT=0 NO_COMMIT=0 YES=0 DRY_RUN=0 JSON=0 HELP=0
DERIVED_NAME='' DERIVED_PACKAGE='' DERIVED_BUNDLE='' DERIVED_OWNER=''
PACKAGE_PATH=''
APPLY_COMMAND=''    # this invocation without --dry-run, for the dry run's next step
OUT=1               # file descriptor for human output: stdout, or stderr with --json
ROOT=''             # the template checkout: the directory that holds this script
TPL=''              # the .template directory in use (a tested temporary copy once files change)
WORK=''             # temporary directory for the .template copy, the backup and the old .git
BACKUP=''           # copy of the tree when there is no .git to restore from
HAD_GIT=0
OLD_GIT=''          # where the old .git waits until the new history exists
PHASE=prepare       # prepare -> change -> git -> finished; decides the recovery advice
COMMITTED=0
ERR_REASON=''       # machine-readable reason for some errors (JSON "reason")
ERR_RECOVERY=''     # command that fixes a precondition (JSON "recovery")
ERR_HINT=''         # extra stderr text printed after an error message

# The plan: filled by compute_plan, used for both --dry-run and the real run.
DELETE=() BUILD_OUTPUT=() WRITE=() EDIT=() MOVE_FROM=() MOVE_TO=()

# Set by .template/manifest.env.
TEMPLATE_SLUG='' TEMPLATE_NAME='' TEMPLATE_DISPLAY_NAME='' TEMPLATE_PACKAGE_ROOT=''
TEMPLATE_APP_PACKAGE='' TEMPLATE_BUNDLE_ID='' DESKTOP_PATHS='' SKIP_DIR_NAMES=''
TPL_ROOT_PATH='' TPL_APP_PATH=''    # the package tokens as paths (com/template, ...)
PRUNE=()                            # find arguments that skip build output and VCS state

# --- output ----------------------------------------------------------------------------------

say() { printf '%s\n' "$*" >&"$OUT"; }

dots_to_slashes() { printf '%s' "${1//.//}"; }

# json_array <string>...: a JSON array of strings (one perl process for the whole array).
json_array() {
    if command -v perl >/dev/null 2>&1; then
        perl -e 'print "[" . join(",", map { my $s = $_; $s =~ s/(["\\])/\\$1/g;
            $s =~ s/([\x00-\x1f])/sprintf("\\u%04x", ord $1)/ge; qq("$s") } @ARGV) . "]"' -- "$@"
    else
        printf '["%s"]' "$1" # only reached for the fixed "perl is missing" message
    fi
}

json_str() {
    local a
    a=$(json_array "$1")
    a=${a#[}
    printf '%s' "${a%]}"
}

category_of() {
    case $1 in
        "$EX_USAGE") echo usage ;;
        "$EX_VALIDATION") echo validation ;;
        "$EX_PRECONDITION") echo precondition ;;
        *) echo internal ;;
    esac
}

# The one command that puts the template back, given how far the run got.
recovery_command() {
    if [ -n "$OLD_GIT" ] && [ -d "$OLD_GIT" ]; then
        printf 'cd %q && rm -rf .git && mv %q .git && git reset -q --hard HEAD && git clean -qfd' "$ROOT" "$OLD_GIT"
    elif [ "$HAD_GIT" = 1 ]; then
        printf 'cd %q && git reset -q --hard HEAD && git clean -qfd' "$ROOT"
    elif [ -n "$BACKUP" ]; then
        printf 'cd %q && find . -mindepth 1 -maxdepth 1 -exec rm -rf {} + && cp -Rp %q/. .' "$ROOT" "$BACKUP"
    fi
}

# die <exit code> <message>: the only way this script fails on purpose.
die() {
    local code=$1 message recovery='' reason=''
    shift
    message=$*
    trap - ERR INT TERM
    # In a subshell ($(...) or a pipeline) anything printed would be captured or printed twice:
    # just exit with the code, and the parent shell's ERR trap reports the failure once.
    if [ "${BASH_SUBSHELL:-0}" -gt 0 ]; then exit "$code"; fi
    printf 'setup.sh: %s\n' "$message" >&2
    if [ -n "$ERR_HINT" ]; then printf '%s\n' "$ERR_HINT" >&2; fi
    case $PHASE in
        change | git)
            recovery=$(recovery_command)
            if [ "$PHASE" = git ]; then
                printf '\nThe project files are complete; only the git step failed. Finish it with:\n  cd %q && rm -rf .git && git init -q && git symbolic-ref HEAD refs/heads/main && git add -A && git commit -m %q\nor restore the template:\n' \
                    "$ROOT" "Initial commit from $TEMPLATE_SLUG" >&2
            else
                printf '\nsetup.sh stopped part-way. Restore the template with:\n' >&2
            fi
            printf '  %s\n' "$recovery" >&2
            ;;
        *) recovery=$ERR_RECOVERY ;;
    esac
    if [ "$JSON" = 1 ]; then
        if [ -n "$ERR_REASON" ]; then reason=",\"reason\":$(json_str "$ERR_REASON")"; fi
        if [ -n "$recovery" ]; then recovery=",\"recovery\":$(json_str "$recovery")"; fi
        printf '{"status":"error","code":%s,"category":"%s"%s,"message":%s%s}\n' \
            "$code" "$(category_of "$code")" "$reason" "$(json_str "$message")" "$recovery" >&3
    fi
    exit "$code"
}

usage_error() {
    ERR_HINT="$USAGE_LINE
Run ./setup.sh --help for details."
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
                    --name) NAME=$val ;;
                    --package) PACKAGE=$val ;;
                    --bundle-id) BUNDLE_ID=$val ;;
                    --display-name) DISPLAY_NAME=$val ;;
                    --author) AUTHOR=$val ;;
                    --derive-from-github) DERIVE=$val ;;
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
    case $KEYWORDS in *" $1 "*) return 0 ;; esac
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
    if [ -n "${DERIVE+x}" ]; then derive_from_github; fi
    if [ -z "${NAME+x}" ]; then
        if [ -n "$DERIVED_NAME" ]; then
            NAME=$DERIVED_NAME
        elif [ -t 0 ]; then
            read -r -p "Project name, PascalCase (e.g. WeatherApp): " NAME || NAME=''
        else
            missing="$missing --name"
        fi
    fi
    if [ -z "${PACKAGE+x}" ]; then
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
    if [ -z "${BUNDLE_ID+x}" ]; then
        if [ -n "$DERIVED_BUNDLE" ]; then BUNDLE_ID=$DERIVED_BUNDLE; else BUNDLE_ID=${PACKAGE//_/-}; fi
    fi
    if [ -z "${DISPLAY_NAME+x}" ]; then DISPLAY_NAME=$NAME; fi
    if [ -z "${AUTHOR+x}" ]; then
        AUTHOR=$(git config --get user.name 2>/dev/null || true)
        if [ -z "$AUTHOR" ]; then AUTHOR=$DERIVED_OWNER; fi
        if [ -z "$AUTHOR" ] && [ -t 0 ]; then
            read -r -p "Copyright holder for LICENSE: " AUTHOR || AUTHOR=''
        fi
        if [ -z "$AUTHOR" ]; then
            die "$EX_VALIDATION" "no LICENSE copyright holder: pass --author \"<name>\" (git config user.name is not set)"
        fi
    fi
    PACKAGE_PATH=$(dots_to_slashes "$PACKAGE")
}

check_segments() { # <option> <value>: every dot-separated segment is at most MAX_SEGMENT long
    local seg
    for seg in $(printf '%s' "$2" | tr '.' ' '); do
        if [ "${#seg}" -gt "$MAX_SEGMENT" ]; then
            die "$EX_VALIDATION" "$1 segment '$seg' is ${#seg} characters; the limit is $MAX_SEGMENT"
        fi
    done
}

# Every input rule lives here. Exits 3 on the first violation, before anything changes.
validate_values() {
    local re seg bad
    # One perl process checks every value; it prints the 0-based index of the first bad one.
    bad=$(perl -MEncode -e 'for my $i (0 .. $#ARGV) {
        eval { decode("UTF-8", $ARGV[$i], Encode::FB_CROAK); 1 } or do { print $i; exit } }' \
        -- "$NAME" "$PACKAGE" "$BUNDLE_ID" "$DISPLAY_NAME" "$AUTHOR")
    if [ -n "$bad" ]; then
        set -- --name --package --bundle-id --display-name --author
        shift "$bad"
        die "$EX_VALIDATION" "$1 is not valid UTF-8"
    fi

    if [ -z "$NAME" ]; then die "$EX_VALIDATION" "--name is empty"; fi
    re='^[A-Za-z][A-Za-z0-9]*$'
    if ! [[ $NAME =~ $re ]]; then
        die "$EX_VALIDATION" "--name '$NAME' must start with a letter and contain only letters and digits (e.g. WeatherApp)"
    fi
    if [ "${#NAME}" -gt "$MAX_NAME" ]; then
        die "$EX_VALIDATION" "--name is ${#NAME} characters; the limit is $MAX_NAME"
    fi

    if [ -z "$PACKAGE" ]; then die "$EX_VALIDATION" "--package is empty"; fi
    re='^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$'
    if ! [[ $PACKAGE =~ $re ]]; then
        die "$EX_VALIDATION" "--package '$PACKAGE' must be lowercase, with at least two dot-separated segments that each start with a letter and contain only a-z, 0-9 and _ (e.g. com.acme.weather)"
    fi
    if [ "${#PACKAGE}" -gt "$MAX_PACKAGE" ]; then
        die "$EX_VALIDATION" "--package is ${#PACKAGE} characters; the limit is $MAX_PACKAGE"
    fi
    check_segments --package "$PACKAGE"
    case $PACKAGE in
        java.* | javax.* | android.* | kotlin.* | kotlinx.*)
            die "$EX_VALIDATION" "--package '$PACKAGE' uses a reserved namespace (java., javax., android., kotlin., kotlinx.)"
            ;;
        "$TEMPLATE_PACKAGE_ROOT" | "$TEMPLATE_PACKAGE_ROOT".*)
            die "$EX_VALIDATION" "--package '$PACKAGE' is inside the template's own package $TEMPLATE_PACKAGE_ROOT; choose another"
            ;;
    esac
    for seg in $(printf '%s' "$PACKAGE" | tr '.' ' '); do
        if is_keyword "$seg"; then
            die "$EX_VALIDATION" "--package segment '$seg' is a Java or Kotlin keyword; try '${seg}s' or 'my$seg'"
        fi
    done

    re='^[A-Za-z][A-Za-z0-9-]*(\.[A-Za-z][A-Za-z0-9-]*)+$'
    if ! [[ $BUNDLE_ID =~ $re ]]; then
        die "$EX_VALIDATION" "--bundle-id '$BUNDLE_ID' must have at least two dot-separated segments that each start with a letter and contain only letters, digits and - (no _), e.g. com.acme.weather-app. Without --bundle-id it is the package with _ replaced by -"
    fi
    check_segments --bundle-id "$BUNDLE_ID"

    # The display name lands in strings.xml, Config.xcconfig and a Kotlin string literal.
    if [ -z "$DISPLAY_NAME" ]; then die "$EX_VALIDATION" "--display-name is empty"; fi
    if [ "${#DISPLAY_NAME}" -gt "$MAX_DISPLAY" ]; then
        die "$EX_VALIDATION" "--display-name is ${#DISPLAY_NAME} characters; the limit is $MAX_DISPLAY"
    fi
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
        *[![:space:]]*) ;;
        *) die "$EX_VALIDATION" "--author is empty" ;;
    esac
    case $AUTHOR in
        *[[:cntrl:]]*) die "$EX_VALIDATION" "--author contains a control character" ;;
    esac
    if [ "${#AUTHOR}" -gt "$MAX_AUTHOR" ]; then
        die "$EX_VALIDATION" "--author is ${#AUTHOR} characters; the limit is $MAX_AUTHOR"
    fi
}

# --- preconditions ---------------------------------------------------------------------------

check_initialized() {
    local name
    if [ ! -f .template/manifest.env ]; then
        ERR_REASON=already-initialized
        die "$EX_PRECONDITION" "$ROOT has no .template/manifest.env: this project is already initialized, or it is not the template"
    fi
    # shellcheck disable=SC1091 # read at run time; the variables are declared at the top
    . .template/manifest.env
    TPL=$ROOT/.template
    TPL_ROOT_PATH=$(dots_to_slashes "$TEMPLATE_PACKAGE_ROOT")
    TPL_APP_PATH=$(dots_to_slashes "$TEMPLATE_APP_PACKAGE")
    # find arguments: prune SKIP_DIR_NAMES directories (and a .git file) outside src/.
    PRUNE=(\( \( -type d \()
    for name in $SKIP_DIR_NAMES; do PRUNE+=(-name "$name" -o); done
    PRUNE[${#PRUNE[@]} - 1]=\)
    PRUNE+=(\) -o -name .git \) -not -path '*/src/*' -prune -o)
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
            ERR_RECOVERY='git stash push --include-untracked'
            die "$EX_PRECONDITION" "uncommitted changes; commit or stash them first:
$dirty"
        fi
    fi
}

has_git_identity() {
    git -c user.useConfigOnly=true var GIT_AUTHOR_IDENT >/dev/null 2>&1 &&
        git -c user.useConfigOnly=true var GIT_COMMITTER_IDENT >/dev/null 2>&1
}

# --- plan ------------------------------------------------------------------------------------

is_deleted() {
    local p
    for p in ${DELETE[@]+"${DELETE[@]}"}; do
        case $1 in "$p" | "$p"/*) return 0 ;; esac
    done
    return 1
}

# NUL-separated files for text rewrites: everything but build output, VCS state and .template/.
text_files() {
    find . "${PRUNE[@]}" -name .template -prune -o -type f -print0
}

rewrite() { # tokens|regions report|apply; prints the changed files, NUL-separated
    local desktop=keep skip
    if [ "$NO_DESKTOP" = 1 ]; then desktop=drop; fi
    skip=$(printf '%s\n' ${DELETE[@]+"${DELETE[@]}"})
    text_files | SKIP=$skip DESKTOP=$desktop \
        R_FROM_1=$TEMPLATE_BUNDLE_ID R_TO_1=$BUNDLE_ID \
        R_FROM_2=$TEMPLATE_APP_PACKAGE R_TO_2=$PACKAGE \
        R_FROM_3=$TPL_APP_PATH R_TO_3=$PACKAGE_PATH \
        R_FROM_4=$TEMPLATE_PACKAGE_ROOT R_TO_4=$PACKAGE \
        R_FROM_5=$TPL_ROOT_PATH R_TO_5=$PACKAGE_PATH \
        R_FROM_6=$TEMPLATE_DISPLAY_NAME R_TO_6=$DISPLAY_NAME \
        R_FROM_7=$TEMPLATE_NAME R_TO_7=$NAME \
        perl "$TPL/rewrite.pl" "$1" "$2"
}

# Fills DELETE, BUILD_OUTPUT, WRITE, EDIT, MOVE_FROM and MOVE_TO. Every path is read
# NUL-separated, so no file name can split into two paths.
# check_listed_path <source> <path>: a path listed in .template/ is relative, non-empty and has
# no empty, "." or ".." segment. Anything else is a template bug, caught before any change.
check_listed_path() {
    case /$2/ in
        *//* | */./* | */../*)
            die "$EX_INTERNAL" "$1 lists '$2': listed paths must be relative, non-empty and without . or .. segments"
            ;;
    esac
}

compute_plan() {
    local p dir f rel names=() reports longest
    DELETE=() BUILD_OUTPUT=() WRITE=() EDIT=() MOVE_FROM=() MOVE_TO=()
    while IFS= read -r p; do
        case $p in '#'*) continue ;; esac
        check_listed_path .template/template-only.txt "$p"
        if [ -e "$p" ] || [ -L "$p" ]; then DELETE+=("$p"); fi
    done <"$TPL/template-only.txt"
    if [ "$NO_DESKTOP" = 1 ]; then
        for p in $DESKTOP_PATHS; do
            check_listed_path "DESKTOP_PATHS in .template/manifest.env" "$p"
            if [ -e "$p" ]; then DELETE+=("$p"); fi
        done
    fi

    # Build output and IDE state: SKIP_DIR_NAMES directories outside src/, except .git.
    for p in $SKIP_DIR_NAMES; do
        if [ "$p" != .git ]; then names+=(-name "$p" -o); fi
    done
    while IFS= read -r -d '' p; do
        BUILD_OUTPUT+=("${p#./}")
    done < <(find . -name .git -prune -o -type d -not -path '*/src/*' \( "${names[@]}" -false \) \
        -prune -print0)

    while IFS= read -r -d '' p; do
        WRITE+=("${p#./}")
    done < <(cd "$TPL/project" && find . -type f -print0 | sort -z)

    # Moves: every file under a */kotlin/<template package path> source directory.
    while IFS= read -r -d '' dir; do
        dir=${dir#./}
        if is_deleted "$dir"; then continue; fi
        while IFS= read -r -d '' f; do
            rel=${f#"${dir%"$TPL_ROOT_PATH"}"}
            case $rel in
                "$TPL_APP_PATH"/*) rel="$PACKAGE_PATH/${rel#"$TPL_APP_PATH"/}" ;;
                *) rel="$PACKAGE_PATH/${rel#"$TPL_ROOT_PATH"/}" ;;
            esac
            MOVE_FROM+=("$f")
            MOVE_TO+=("${dir%"$TPL_ROOT_PATH"}$rel")
        done < <(find "$dir" -type f -print0 | sort -z)
    done < <(find . "${PRUNE[@]}" -type d -path "*/kotlin/$TPL_ROOT_PATH" -print0 -prune | sort -z)

    # Edits: what the rewrites would change, plus LICENSE (and ci.yml with --no-desktop).
    # Collected through a file, not a process substitution, so a rewrite.pl failure (such as
    # unbalanced region markers) stops the run here, before anything changes.
    reports=$(mktemp "${TMPDIR:-/tmp}/kmp-template-plan.XXXXXX")
    rewrite regions report >"$reports"
    rewrite tokens report >>"$reports"
    printf '%s\0' LICENSE >>"$reports"
    if [ "$NO_DESKTOP" = 1 ]; then printf '%s\0' .github/workflows/ci.yml >>"$reports"; fi
    # Compared element by element: a file name may contain any character, newlines included.
    while IFS= read -r -d '' p; do
        if in_list "$p" "${WRITE[@]}" || in_list "$p" ${EDIT[@]+"${EDIT[@]}"}; then continue; fi
        EDIT+=("$p")
    done <"$reports"
    rm -f "$reports"

    # Checks that would otherwise fail half-way through.
    for p in ${DELETE[@]+"${DELETE[@]}"} ${BUILD_OUTPUT[@]+"${BUILD_OUTPUT[@]}"}; do
        if ! inside_root "$p"; then
            die "$EX_INTERNAL" "refusing to delete '$p': it is not inside $ROOT"
        fi
    done
    for p in ${MOVE_TO[@]+"${MOVE_TO[@]}"}; do
        if [ -e "$p" ]; then die "$EX_VALIDATION" "$p already exists; setup.sh would overwrite it"; fi
    done
    longest=$(longest_path_bytes ${MOVE_TO[@]+"${MOVE_TO[@]}"})
    if [ "$longest" -gt "$MAX_PATH" ]; then
        die "$EX_VALIDATION" "the longest source path would be $longest bytes (limit $MAX_PATH, so Gradle build outputs stay under PATH_MAX); use a shorter --package or a shallower directory than $ROOT"
    fi
    if ! grep -q '^Copyright (c) [0-9]\{4\} ' LICENSE; then
        die "$EX_INTERNAL" "LICENSE has no 'Copyright (c) <year> <holder>' line to update"
    fi
}

# inside_root <relative path>: true only if the path is strictly below ROOT once resolved. It must
# be relative with no empty, "." or ".." segment; its nearest existing ancestor is resolved
# through symlinks and the rest appended, so the last component (which rm -rf removes, without
# following it) is never resolved. Takes the path through the environment, so any character is safe.
inside_root() {
    P=$1 R=$ROOT perl -MCwd=realpath -e '
        my ($p, $root) = ($ENV{P}, $ENV{R});
        my @parts = split m{/}, $p, -1;
        exit 1 if $p eq "" || grep { $_ eq "" || $_ eq "." || $_ eq ".." } @parts;
        my $leaf = pop @parts;
        my @rest;
        unshift @rest, pop @parts while @parts && !-e join("/", @parts);
        my $base = realpath(@parts ? join("/", @parts) : ".");
        exit 1 unless defined $base;
        exit(index(join("/", $base, @rest, $leaf), "$root/") == 0 ? 0 : 1)'
}

# in_list <value> <item>...: true if value equals one of the items.
in_list() {
    local value=$1 item
    shift
    for item in "$@"; do
        if [ "$item" = "$value" ]; then return 0; fi
    done
    return 1
}

# longest_path_bytes <relative path>...: the byte length of the longest ROOT/<path>. Bytes, not
# characters: PATH_MAX counts bytes, and a UTF-8 directory name has more bytes than characters.
longest_path_bytes() {
    perl -e 'use bytes; my $root = shift; my $max = 0;
        for (@ARGV) { my $n = length("$root/$_"); $max = $n if $n > $max } print $max' -- "$ROOT" "$@"
}

list_block() { # <title> <item>...
    local title=$1 item
    shift
    if [ $# = 0 ]; then return 0; fi
    say ""
    say "$title ($#):"
    for item in "$@"; do say "  $item"; done
}

print_plan() {
    local git_plan desktop=yes i moves=()
    if [ "$NO_DESKTOP" = 1 ]; then desktop='no (--no-desktop)'; fi
    if [ "$KEEP_GIT" = 1 ]; then
        git_plan='keep the existing .git (--keep-git); nothing is committed'
    elif [ "$NO_COMMIT" = 1 ]; then
        git_plan='new history on main, files staged but not committed (--no-commit)'
    else
        git_plan="new history on main with one commit: Initial commit from $TEMPLATE_SLUG"
    fi
    if [ "$DRY_RUN" = 1 ]; then
        say "$TEMPLATE_SLUG setup (dry run: nothing changes)"
    else
        say "$TEMPLATE_SLUG setup"
    fi
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
    for i in ${MOVE_FROM[@]+"${!MOVE_FROM[@]}"}; do moves+=("${MOVE_FROM[$i]} -> ${MOVE_TO[$i]}"); done
    list_block "Delete" ${DELETE[@]+"${DELETE[@]}"}
    list_block "Delete build output" ${BUILD_OUTPUT[@]+"${BUILD_OUTPUT[@]}"}
    list_block "Write (from .template/project/)" "${WRITE[@]}"
    list_block "Edit" ${EDIT[@]+"${EDIT[@]}"}
    list_block "Move" ${moves[@]+"${moves[@]}"}
}

confirm() {
    local answer
    if [ "$DRY_RUN" = 1 ] || [ "$YES" = 1 ]; then return 0; fi
    if [ ! -t 0 ]; then
        die "$EX_USAGE" "stdin is not a terminal: add --yes to apply the plan, or --dry-run to preview it"
    fi
    read -r -p "Proceed? [y/N] " answer || answer=''
    case $answer in
        y | Y | yes | YES) ;;
        *) die "$EX_USAGE" "cancelled; nothing changed" ;;
    esac
}

# --- the run ---------------------------------------------------------------------------------

# Copies .template/ (which the run deletes) to a temporary directory and checks that the copy
# works before anything changes.
prepare_work() {
    local tmp
    tmp=${TMPDIR:-/tmp}
    WORK=$(mktemp -d "${tmp%/}/kmp-template-setup.XXXXXX")
    cp -R "$ROOT/.template" "$WORK/template"
    TPL=$WORK/template
    mkdir "$WORK/empty"
    if ! perl -c "$TPL/rewrite.pl" >/dev/null 2>&1 ||
        ! "$BASH" "$TPL/check-leftovers.sh" "$WORK/empty" >/dev/null; then
        die "$EX_INTERNAL" "the copy of .template/ in $WORK does not work; nothing changed"
    fi
    if [ "$HAD_GIT" = 0 ]; then
        BACKUP=$WORK/backup
        mkdir "$BACKUP"
        cp -Rp "$ROOT/." "$BACKUP/"
    fi
}

apply_changes() {
    local p i dirs year
    PHASE=change
    say "Writing AGENTS.md, CLAUDE.md and README.md for the project..."
    cp -R "$TPL/project/." .

    say "Deleting template-only files and build output..."
    for p in ${DELETE[@]+"${DELETE[@]}"} ${BUILD_OUTPUT[@]+"${BUILD_OUTPUT[@]}"}; do
        rm -rf -- "$p"
    done

    if [ "$NO_DESKTOP" = 1 ]; then say "Removing desktop-only code..."; fi
    rewrite regions apply >/dev/null
    if [ "$NO_DESKTOP" = 1 ]; then
        # A region can only delete lines, so the job name is renamed here.
        FROM='name: Android & Desktop' TO='name: Android' \
            perl -pi -e 's/^(\s*)\Q$ENV{FROM}\E$/$1$ENV{TO}/' .github/workflows/ci.yml
    fi

    say "Renaming packages, names and the bundle ID..."
    rewrite tokens apply >/dev/null

    say "Moving Kotlin sources to $PACKAGE_PATH..."
    for i in ${MOVE_FROM[@]+"${!MOVE_FROM[@]}"}; do
        mkdir -p "$(dirname -- "${MOVE_TO[$i]}")"
        mv -- "${MOVE_FROM[$i]}" "${MOVE_TO[$i]}"
    done
    # Remove the emptied template package directories (and kotlin/com if nothing else uses it).
    dirs=()
    while IFS= read -r -d '' p; do dirs+=("$p"); done < <(
        find . "${PRUNE[@]}" -type d -path "*/kotlin/$TPL_ROOT_PATH" -print0 -prune)
    for p in ${dirs[@]+"${dirs[@]}"}; do
        # One rmdir per directory: with -depth a parent is tested only after its children are gone.
        find "$p" -depth -type d -empty -exec rmdir {} \;
        rmdir "$(dirname -- "$p")" 2>/dev/null || true
    done

    say "Updating LICENSE..."
    year=$(date +%Y)
    YEAR=$year AUTHOR=$AUTHOR perl -pi -e 's/^Copyright \(c\) \d{4} .*$/Copyright (c) $ENV{YEAR} $ENV{AUTHOR}/' LICENSE
}

verify_result() {
    local leftovers args=() dir=$PACKAGE_PATH
    say "Checking for template leftovers..."
    if [ "$NO_DESKTOP" = 1 ]; then args+=(--no-desktop); fi
    # The parent directories of the package path (io/github/<owner>) are the user's too.
    while :; do
        args+=(--allow "$dir")
        case $dir in */*) dir=${dir%/*} ;; *) break ;; esac
    done
    if ! leftovers=$("$BASH" "$TPL/check-leftovers.sh" "${args[@]}" --allow "$NAME" \
        --allow "$DISPLAY_NAME" --allow "$PACKAGE" --allow "$BUNDLE_ID" --allow "$AUTHOR" . 2>&1); then
        printf '%s\n' "$leftovers" >&2
        die "$EX_INTERNAL" "template leftovers remain (listed above); this is a setup.sh bug"
    fi
    if [ ! -f AGENTS.md ] || [ "$(cat CLAUDE.md 2>/dev/null)" != "@AGENTS.md" ]; then
        die "$EX_INTERNAL" "AGENTS.md or the CLAUDE.md that imports it is missing"
    fi
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

# next_step <key> <value> [why]: one JSON object for the "next" list.
next_step() {
    local why=''
    if [ $# -ge 3 ]; then why=",\"why\":$(json_str "$3")"; fi
    printf '{"%s":%s%s}' "$1" "$(json_str "$2")" "$why"
}

finish() {
    local next desktop=true values i move_json='' removed
    if [ "$NO_DESKTOP" = 1 ]; then desktop=false; fi
    values=$(printf '"name":%s,"package":%s,"bundleId":%s,"displayName":%s,"author":%s,"desktop":%s' \
        "$(json_str "$NAME")" "$(json_str "$PACKAGE")" "$(json_str "$BUNDLE_ID")" \
        "$(json_str "$DISPLAY_NAME")" "$(json_str "$AUTHOR")" "$desktop")

    if [ "$DRY_RUN" = 1 ]; then
        say ""
        say "Next: $APPLY_COMMAND"
        if [ "$JSON" = 1 ]; then
            for i in ${MOVE_FROM[@]+"${!MOVE_FROM[@]}"}; do
                move_json="$move_json${move_json:+,}{\"from\":$(json_str "${MOVE_FROM[$i]}"),\"to\":$(json_str "${MOVE_TO[$i]}")}"
            done
            printf '{"status":"ok","dryRun":true,%s,"plan":{"delete":%s,"write":%s,"edit":%s,"move":[%s]},"next":[%s]}\n' \
                "$values" \
                "$(json_array ${DELETE[@]+"${DELETE[@]}"} ${BUILD_OUTPUT[@]+"${BUILD_OUTPUT[@]}"})" \
                "$(json_array "${WRITE[@]}")" "$(json_array ${EDIT[@]+"${EDIT[@]}"})" "$move_json" \
                "$(next_step run "$APPLY_COMMAND" "apply this plan")" >&3
        fi
        return 0
    fi

    PHASE=finished
    rm -rf "$WORK"
    next=$(next_step run "./gradlew check" "the proof that the project works: setup.sh renamed and checked files but built nothing")
    next="$next,$(next_step read AGENTS.md "commands, where settings live, and the definition of done")"
    if [ "$KEEP_GIT" = 1 ]; then
        next="$next,$(next_step run "git add -A && git commit -m 'Initialize project from $TEMPLATE_SLUG'" "--keep-git left the changes uncommitted")"
    elif [ "$COMMITTED" = 0 ]; then
        next="$next,$(next_step run "git commit -m 'Initial commit from $TEMPLATE_SLUG'" "the files are staged but not committed")"
    fi
    say ""
    say "Done: $NAME is ready. Next: ./gradlew check, then read AGENTS.md."
    if [ "$JSON" = 1 ]; then
        removed=$(json_array ${DELETE[@]+"${DELETE[@]}"})
        printf '{"status":"ok","dryRun":false,%s,"removed":%s,"committed":%s,"verified":false,"next":[%s]}\n' \
            "$values" "$removed" "$([ "$COMMITTED" = 1 ] && echo true || echo false)" "$next" >&3
    fi
}

main() {
    local arg
    # Results go to fd 3, the real stdout, so a failure inside a function whose output is
    # redirected to a file still reports to the caller.
    exec 3>&1
    for arg in "$@"; do
        if [ "$arg" = --json ]; then JSON=1 OUT=2; fi
        if [ "$arg" != --dry-run ]; then APPLY_COMMAND="$APPLY_COMMAND $(printf '%q' "$arg")"; fi
    done
    APPLY_COMMAND="./setup.sh$APPLY_COMMAND"
    trap 'on_err $? "$LINENO" "$BASH_COMMAND"' ERR
    trap 'die "$EX_INTERNAL" "interrupted"' INT TERM

    ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
    cd "$ROOT"
    parse_args "$@"
    if [ "$HELP" = 1 ]; then
        if [ "$JSON" = 1 ]; then
            usage >&2
            printf '{"status":"ok","help":true}\n' >&3
        else
            usage
        fi
        exit 0
    fi
    check_initialized
    resolve_values
    validate_values
    check_git
    compute_plan
    print_plan
    if [ "$DRY_RUN" = 1 ]; then
        finish
        exit 0
    fi
    confirm
    prepare_work
    apply_changes
    verify_result
    start_history
    finish
}

main "$@"
