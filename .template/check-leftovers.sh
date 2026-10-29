#!/usr/bin/env bash
# Reports template leftovers in a generated project.
#
# Usage: check-leftovers.sh [--no-desktop] [--allow <literal>]... <dir>
#
# Reports, one per line as "<path>:<line>: <text>" (line 0 for a path):
# - every path listed in template-only.txt that still exists (with --no-desktop, also every
#   DESKTOP_PATHS entry from manifest.env);
# - every path and every line of every text file matching a Perl regex in forbidden.txt (with
#   --no-desktop, also forbidden-desktop.txt).
# Directories named in SKIP_DIR_NAMES (manifest.env) are skipped unless they are under a src/
# directory. An --allow literal that itself matches a pattern is a legitimate user value (an
# author named nkrebs13, say), so it is masked out of each line before matching.
#
# Exit codes: 0 no leftovers, 1 leftovers found, 2 usage error.
set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
no_desktop=0
dir=''
allow_file=$(mktemp "${TMPDIR:-/tmp}/check-leftovers.XXXXXX")
trap 'rm -f "$allow_file"' EXIT

usage() {
    echo "usage: check-leftovers.sh [--no-desktop] [--allow <literal>]... <dir>"
}

while [ $# -gt 0 ]; do
    case $1 in
        --no-desktop) no_desktop=1 ;;
        --allow)
            if [ $# -lt 2 ]; then usage >&2 && exit 2; fi
            printf '%s\0' "$2" >>"$allow_file"
            shift
            ;;
        -h | --help) usage && exit 0 ;;
        -*) usage >&2 && exit 2 ;;
        *)
            if [ -n "$dir" ]; then usage >&2 && exit 2; fi
            dir=$1
            ;;
    esac
    shift
done
if [ -z "$dir" ] || [ ! -d "$dir" ]; then usage >&2 && exit 2; fi

# Paths reach perl as arguments, never joined into one string, so any character is safe in them.
perl -e '
use strict;
use warnings;
use File::Find;

my ($root, $here, $no_desktop, $allow_file) = @ARGV;

sub read_lines {
    my ($file) = @_;
    open my $fh, "<", $file or die "check-leftovers: cannot read $file: $!\n";
    return grep { !/^\s*(?:#|$)/ } map { chomp; $_ } <$fh>;
}

my %manifest;
for (read_lines("$here/manifest.env")) {
    $manifest{$1} = $2 if /^([A-Z_]+)="?(.*?)"?$/;
}
my %skip = map { $_ => 1 } split " ", ($manifest{SKIP_DIR_NAMES} // die "check-leftovers: no SKIP_DIR_NAMES\n");

my @gone = read_lines("$here/template-only.txt");
my @patterns = map { qr/$_/ } read_lines("$here/forbidden.txt");
if ($no_desktop) {
    push @gone, split " ", ($manifest{DESKTOP_PATHS} // die "check-leftovers: no DESKTOP_PATHS\n");
    push @patterns, map { qr/$_/ } read_lines("$here/forbidden-desktop.txt");
}

# Only values that would otherwise be reported need masking; longest first.
open my $afh, "<", $allow_file or die "check-leftovers: cannot read the allow list: $!\n";
my @allow = sort { length $b <=> length $a }
    grep { my $v = $_; length $v && grep { $v =~ $_ } @patterns }
    do { local $/ = "\0"; map { chomp; $_ } <$afh> };

sub hit {
    my ($text) = @_;
    $text =~ s/\Q$_\E//g for @allow;
    for my $re (@patterns) { return 1 if $text =~ $re }
    return 0;
}

my $found = 0;
for my $path (@gone) {
    if (-e "$root/$path" || -l "$root/$path") { print "$path:0: (template-only path)\n"; $found++ }
}
find({
    no_chdir => 1,
    preprocess => sub { sort @_ },
    wanted => sub {
        my $path = $File::Find::name;
        (my $rel = $path) =~ s{^\Q$root\E/?}{};
        return if $rel eq "";
        my ($name) = $path =~ m{([^/]+)$};
        if ($skip{$name} && ($name eq ".git" || -d $path) && "/$rel" !~ m{/src/}) {
            $File::Find::prune = 1;
            return;
        }
        if (hit($rel)) { print "$rel:0: (path)\n"; $found++ }
        return unless -f $path && !-l $path && -T $path;
        open my $fh, "<", $path or die "check-leftovers: cannot read $path: $!\n";
        while (my $line = <$fh>) {
            next unless hit($line);
            chomp $line;
            print "$rel:$.: $line\n";
            $found++;
        }
        close $fh;
    },
}, $root);
exit($found ? 1 : 0);
' "${dir%/}" "$here" "$no_desktop" "$allow_file"
