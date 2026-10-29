#!/usr/bin/env bash
# Reports template leftovers in a generated project.
#
# Usage: check-leftovers.sh [--no-desktop] [--allow <literal>]... <dir>
#
# Every text file under <dir> (skipping .git, build, .gradle, .kotlin and .idea directories) and
# every path is matched against the Perl regexes in forbidden.txt next to this script, plus
# forbidden-desktop.txt with --no-desktop. Each match prints as "<file>:<line>: <text>" (line 0
# for a path). An --allow literal that itself matches a pattern is a legitimate user value (an
# author named nkrebs13, say), so it is masked out of each line before matching.
#
# Exit codes: 0 no leftovers, 1 leftovers found, 2 usage error.
set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
patterns="$here/forbidden.txt"
dir=''
allow_file=$(mktemp "${TMPDIR:-/tmp}/check-leftovers.XXXXXX")
trap 'rm -f "$allow_file"' EXIT

usage() {
    echo "usage: check-leftovers.sh [--no-desktop] [--allow <literal>]... <dir>" >&2
    exit 2
}

while [ $# -gt 0 ]; do
    case $1 in
        --no-desktop) patterns="$patterns:$here/forbidden-desktop.txt" ;;
        --allow)
            [ $# -ge 2 ] || usage
            printf '%s\n' "$2" >>"$allow_file"
            shift
            ;;
        -h | --help) usage ;;
        -*) usage ;;
        *)
            [ -z "$dir" ] || usage
            dir=$1
            ;;
    esac
    shift
done
[ -n "$dir" ] && [ -d "$dir" ] || usage

PATTERN_FILES=$patterns ALLOW_FILE=$allow_file perl -e '
use strict;
use warnings;
use File::Find;

my @patterns;
for my $file (split /:/, $ENV{PATTERN_FILES}) {
    open my $fh, "<", $file or die "cannot read $file: $!\n";
    while (my $line = <$fh>) {
        chomp $line;
        next if $line =~ /^\s*(#|$)/;
        push @patterns, qr/$line/;
    }
}

# Only values that would otherwise be reported need masking; longest first.
open my $afh, "<", $ENV{ALLOW_FILE} or die "cannot read allow list: $!\n";
my @allow = sort { length $b <=> length $a }
    grep { my $v = $_; length $v && grep { $v =~ $_ } @patterns }
    map { chomp; $_ } <$afh>;

sub hit {
    my ($text) = @_;
    $text =~ s/\Q$_\E//g for @allow;
    for my $re (@patterns) { return 1 if $text =~ $re }
    return 0;
}

my $root = shift @ARGV;
my $found = 0;
find({
    no_chdir => 1,
    preprocess => sub { sort @_ },
    wanted => sub {
        my $path = $File::Find::name;
        (my $rel = $path) =~ s{^\Q$root\E/?}{};
        return if $rel eq "";
        # .git is a directory, or a file in a worktree; skip it either way.
        if ($path =~ m{(?:^|/)\.git$}) {
            $File::Find::prune = 1;
            return;
        }
        if (-d $path && $path =~ m{(?:^|/)(?:build|\.gradle|\.kotlin|\.idea)$}) {
            $File::Find::prune = 1;
            return;
        }
        if (hit($rel)) { print "$rel:0: (path)\n"; $found++ }
        return unless -f $path && !-l $path && -T $path;
        open my $fh, "<", $path or die "cannot read $path: $!\n";
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
' "${dir%/}"
