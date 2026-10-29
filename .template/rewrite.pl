#!/usr/bin/perl
# Text rewrites for setup.sh. Reads NUL-separated file paths on stdin, rewrites the text files in
# place (apply) or only lists the ones that would change (report), and prints each changed path.
#
#   perl rewrite.pl tokens  report|apply   env: R_FROM_1, R_TO_1, R_FROM_2, R_TO_2, ...
#   perl rewrite.pl regions report|apply   deletes "region desktop" ... "endregion desktop" blocks
#
# Optional env SKIP: newline-separated paths (and everything under them) to leave alone.
#
# Tokens are literals (quotemeta, no regex or sed escaping) and are replaced in a single pass,
# longest first, so text one token produces is never rewritten by another.
use strict;
use warnings;

my ($what, $mode) = @ARGV;
die "usage: rewrite.pl tokens|regions report|apply\n"
    unless defined $mode && $what =~ /^(?:tokens|regions)$/ && $mode =~ /^(?:report|apply)$/;

my (%to, $token_re);
if ($what eq "tokens") {
    for (my $i = 1; defined $ENV{"R_FROM_$i"}; $i++) {
        my $from = $ENV{"R_FROM_$i"};
        die "rewrite.pl: empty token R_FROM_$i\n" unless length $from;
        $to{$from} = $ENV{"R_TO_$i"} // die "rewrite.pl: R_TO_$i is not set\n";
    }
    die "rewrite.pl: no tokens\n" unless %to;
    my $alternation = join "|", map { quotemeta } sort { length $b <=> length $a || $a cmp $b } keys %to;
    $token_re = qr/($alternation)/;
}

# A marker is a whole line: "// region desktop", "# region desktop" or "<!-- region desktop -->".
my $marker = qr{^[ \t]*(?://|\#|<!--)[ \t]*}m;

sub rewrite_regions {
    my ($file, $text) = @_;
    my $opens = () = $text =~ /${marker}region desktop\b/mg;
    my $closes = () = $text =~ /${marker}endregion desktop\b/mg;
    die "rewrite.pl: $file: $opens 'region desktop' but $closes 'endregion desktop' markers\n"
        if $opens != $closes;
    return $text unless $opens;
    $text =~ s/${marker}region desktop\b[^\n]*\n.*?${marker}endregion desktop\b[^\n]*\n//gms;
    die "rewrite.pl: $file: nested or misordered 'region desktop' markers\n"
        if $text =~ /${marker}(?:end)?region desktop\b/m;
    # Tidy what a removed block leaves behind: two blank lines where it stood, a blank line before
    # a closing bracket (ktlint rejects it), or blank lines at the end of the file.
    $text =~ s/\n{3,}/\n\n/g;
    $text =~ s/\n\n([ \t]*[)\]}])/\n$1/g;
    $text =~ s/\n+\z/\n/;
    return $text;
}

my @skip = grep { length } split /\n/, ($ENV{SKIP} // "");
my @files = do { local $/ = "\0"; map { chomp; s{^\./}{}; $_ } <STDIN> };

FILE: for my $file (sort @files) {
    for my $s (@skip) { next FILE if $file eq $s || index($file, "$s/") == 0 }
    next if -l $file || !-f $file || !-T $file;
    open my $in, "<:raw", $file or die "rewrite.pl: cannot read $file: $!\n";
    my $text = do { local $/; <$in> };
    close $in;
    my $new = $text;
    if ($what eq "tokens") {
        $new =~ s/$token_re/$to{$1}/g;
    } else {
        $new = rewrite_regions($file, $new);
    }
    next if $new eq $text;
    if ($mode eq "apply") {
        # Writing through the existing file keeps its permissions.
        open my $out, ">:raw", $file or die "rewrite.pl: cannot write $file: $!\n";
        print {$out} $new or die "rewrite.pl: cannot write $file: $!\n";
        close $out or die "rewrite.pl: cannot write $file: $!\n";
    }
    print "$file\n";
}
