#!/usr/bin/perl -w

# Synopsis:
#
# produces a PDF or postscript "offprint" of a Stanford 
# Encyclopedia of Philosophy (SEP) article
#
# Argument is an entry name from SEP, as it appears in the URL.
# For example, to get the article on classical logic, which is at
# http://plato.stanford.edu/entries/logic-classical/, just type
#
#   perl sep-offprint logic-classical
#
# and it will create logic-classical.pdf.
#
# There are many command-line options.  For a list, type
#
#   perl sep-offprint --help
#
# The programs html2ps and ps2pdf must be in the user's path:
#
# html2ps can be found at http://user.it.uu.se/~jan/html2ps.html.
# Download the tarball or zip file and run the "install" script.
#
# ps2pdf is part of Ghostscript -- many users will have it
# already:  http://www.cs.wisc.edu/~ghost/doc/AFPL/get851.htm
#
# In addition, the LWP package for Perl must be installed.
#
# For more information and updates, see 
# http://philosophy.berkeley.edu/macfarlane/sep-offprint.html

my $version_number = '1.11';

use Getopt::Long;
use File::Temp qw/ tempdir /;
use File::Copy;
use File::Basename;
use File::Spec;

# printhelp - returns a usage message

sub printhelp {
    die 
"Produces a PDF offprint from a Stanford Encyclopedia of Philosophy article.
(http://plato.stanford.edu/)

Usage:                 sep-offprint [options] <entry name>

Examples:              sep-offprint russell
                       sep-offprint --1up --ps --paper a4 frege

Options (* indicates a default):

--1up                  print one page per sheet, portrait orientation
--2up                  print two pages per sheet, landscape orientation*
--ps                   produce postscript (PS) output
--pdf                  produce PDF output*
--output FILENAME      name of output file (defaults to ENTRYNAME.ps|pdf)
--font FONT            specify font (Times*, Helvetica, Palatino, Courier)
--size SIZE            specify font size (10pt, 12pt, 14pt*, 16pt)
--align ALIGN          specify alignment (left, justified*)
--paper PAPERSIZE      specify paper size (letter*, legal, a4)
--linkcolor COLOR      specify color of hyperlinks (black*, gray, blue, ...)
--help                 this message
--version              prints version number\n";
}

# slurp - slurps contents of a file and returns as a string;
# takes filename as argument 

sub slurp {
    my $file = shift;
    local( $/, *FILE ); 
	open(FILE, "< $file") or die "Couldn't open $file to read";
	my $contents = <FILE>;
	close(FILE);
    return $contents;
}

# uniq - remove duplicates from an array, preserving the order of the original

sub uniq {
    my @in = @_;
    undef %seen;
    grep(!$seen{$_}++, @in); 
}

# preprocess html - preprocess HTML file, stripping out navigation bars,
# etc., and replacing entity references with appropriate characters or images.
# takes filename as argument

sub preprocess_html {
    my $file = $_;
    my $contents = slurp $file;

    # get rid of header stuff 
	$contents =~ s/<body>.*?<!--DO NOT MODIFY THIS LINE AND ABOVE-->/<body><div id="content"><div id="aueditable">/gs;

    # get rid of "(Stanford Encyclopedia of Philosophy)" in title:
    $contents =~ s/<title>(.*)\ \(Stanford Encyclopedia of Philosophy\)/<title>$1/;

    # make publication date into regular paragraph
    $contents =~ s/<br \/><span class="xsmall">(.*)<\/span><\/h1>/<\/h1><p>$1<\/p>/g;

    # center copyright notice
	$contents =~ s/<div id="foot">(.*?)<\/div>/<center>$1<\/center>/gs;

	# replace unicode character references
	%replacements = (
                     "&\#133;"  => "&hellip;",
                     "&\#145;"  => "&lsquo;",
                     "&\#146;"  => "&rsquo;",
                     "&\#147;"  => "&ldquo;",
                     "&\#148;"  => "&rdquo;",
                     "&\#149;"  => "&bull;",
                     "&\#150;"  => "&minus;", 
                     "&\#257;"  => "a", 
                     "&\#261;"  => "a", 
                     "&\#263;"  => "c", 
                     "&\#269;"  => "c", 
                     "&\#281;"  => "e", 
                     "&\#299;"  => "i", 
                     "&\#321;"  => "L", 
                     "&\#322;"  => "l", 
                     "&\#324;"  => "n", 
                     "&\#333;"  => "o", 
                     "&\#345;"  => "r", 
                     "&\#346;"  => "S", 
                     "&\#347;"  => "s", 
                     "&\#351;"  => "s", 
                     "&\#363;"  => "u", 
                     "&\#365;"  => "u", 
                     "&\#369;"  => "u", 
                     "&\#378;"  => "z", 
                     "&\#380;"  => "z", 
                     "&\#381;"  => "Z", 
                     "&\#599;"  => "u", 
                     "&\#768;"  => "", 
                     "&\#769;"  => "", 
                     "&\#770;"  => "", 
                     "&\#771;"  => "", 
                     "&\#772;"  => "", 
                     "&\#773;"  => "", 
                     "&\#775;"  => "", 
                     "&\#803;"  => "", 
                     "&\#8209;" => "-", 
                     "&\#8600;" => "<img alt=\"southeast-arrow\" src=\"http:\/\/plato.stanford.edu\/symbols\/searrow.gif\">",
                     "<sup>&\#9484;<\/sup>" => "<img alt=\"left-corner-quote\" src=\"http:\/\/plato.stanford.edu\/symbols\/l-corner-quote.gif\">",
                     "<sup>&\#9488;<\/sup>" => "<img alt=\"right-corner-quote\" src=\"http:\/\/plato.stanford.edu\/symbols\/r-corner-quote.gif\">",
                     "&\#8463;" => "<img alt=\"hbar\" src=\"http:\/\/plato.stanford.edu\/symbols\/hbar.gif\">",
                     "&\#9633;" => "<img alt=\"Box\" src=\"http:\/\/plato.stanford.edu\/symbols\/Box.gif\">"
					 );
	while ( my ($ref, $rep) = each(%replacements) ) {
		$contents =~ s/$ref/$rep/g;
    }
	
    # write back to file
	open(FILE, "> $file") or die "Couldn't open $file to write"; 
	print FILE $contents;
	close(FILE);
}

#
# parse command-line options
#

GetOptions( '1up|1' => \$oneup,
            '2up|2' => \$twoup,
            'ps' => \$ps,
            'pdf' => \$pdf,
            'output|o=s' => \$outfile,
            'font=s' => \$fontfamily,
            'size=s' => \$fontsize,
            'align=s' => \$textalign,
            'paper=s' => \$papersize,
            'linkcolor=s' => \$linkcolor,
            'help|h' => \$help,
            'version|v' => \$version);

if ($version) {die "sep-offprint $version_number\n";}; 

if ($#ARGV < 0) {&printhelp;};
$sourceArg = $ARGV[0];

# remove trailing slash, if any, from sourceArg:
$sourceArg =~ s{/$}{};

# derive entry name from argument:
$entryname = $sourceArg;

# remove uppercase and spaces
$entryname =~ tr/A-Z/a-z/;
$entryname =~ tr/ /-/;

# remove /index.html if specified
$entryname =~ s{/index\.html$}{};

# remove URL prefix (everything before slash)
$entryname =~ s{.*/}{};

if ($sourceArg =~ /^file:/) {
  $source = $sourceArg;   # file URL was specified - use local source
}
else {
  $source = "http://plato.stanford.edu/entries/$entryname/";
}
$footer = $source;

$current = File::Spec->curdir;  # working directory from which sep-offprint is run

if ($help) {&printhelp;};
if (not ($pdf or $ps)) {$pdf=1};
if ($oneup) {$twoup = 0} else {$twoup = 1};
if (not $fontsize) {$fontsize = "14pt"};
if (not $outfile) { $outfile = $entryname; }
if (not $fontfamily) {$fontfamily = "Times"};
if (not $textalign) {$textalign = "justify"};
if (not $papersize) {$papersize = "letter"};
if (not $linkcolor) {$linkcolor = "black"};

# strip .pdf or .ps extension from outfile name, and add path:
my($filename, $directories, $suffix) = fileparse($outfile,qr/\.pdf|\.ps/);
if (not $directories) { $directories = $current };
my $outpath = File::Spec->rel2abs(File::Spec->catfile($directories,$filename));

# create temporary directory
$temp = tempdir ( CLEANUP => 1 );

# get all the source files and put them in temp directory,
# then change to temp directory

chdir $temp;
# download all the HTML files
print STDERR "Retrieving files...\n";
$downloadedFiles = `lwp-rget --limit=200 $source/index.html 2>&1`;
(-e "index.html") or die "Could not retrieve files from $source\nAre you sure you have the right entry name?\n"; 

# create blank html file to work around html2ps bug.
# without this blank file after notes.html, html2ps will cut off 
# the last page of an entry if it occurs in the left column in 2up mode.

$blank = "blankpage";

open FILE, ">$blank" or die "unable to open $blank: $!";

print FILE <<EOF; 
<html>
<head>
<title>&nbsp;</title>
</head>
<body>
<p>&nbsp;</p>
</body>
</html>
EOF

close FILE;

# create a configuration file with appropriate footers

$html2psrc = "html2psrc";

open FILE, ">$html2psrc" or die "unable to open $html2psrc: $!";

print FILE <<EOF; 
BODY {
    font-size: $fontsize; 
    font-family: $fontfamily; 
    text-align: $textalign; 
}
A:link {
    color: $linkcolor;
}
\@page { 
    margin-left: 2.5cm; 
    margin-right: 2.5cm; 
    margin-top: 2.5cm; 
    margin-bottom: 2.5cm; 
}
\@html2ps { 
    option { 
        twoup: $twoup; 
        landscape: $twoup; 
        number: 0; 
    } 
    paper { type: $papersize } 
	header {
	    right: "STANFORD ENCYCLOPEDIA OF PHILOSOPHY";
		left: \$T;
    }
    footer {
        left: \$N;
        right: $footer;
    }
}
EOF

close FILE;

# name of temporary file to hold postscript output of html2ps
$pstemp = "pstemp";

# preprocess all the html files in the working (i.e., temp) directory
preprocess_html foreach <*.html>; 

#
# determine the order in which the HTML pages should be processed:
#

@htmlFiles = $downloadedFiles =~ /^.*\.html$/gim;

# make a space-separated list of the HTML files to process, in order
my $orderedHtmlFiles = join(' ', @htmlFiles);

# set $notes to "notes.html" if there are notes
my $notes = "";
if ($orderedHtmlFiles =~ /notes\.html/) {
  $notes = "notes.html"
  }

# discard index.html and notes.html from the list
$orderedHtmlFiles =~ s/(index|notes)\.html//g;

print STDERR "Creating offprint...\n";

# call html2ps to create the postscript version of the entry
system("html2ps -D -U -f $html2psrc -o $pstemp index.html " . $orderedHtmlFiles . " $notes $blank");

# create pdf if requested
if ($pdf) {system("ps2pdf -sPAPERSIZE=$papersize $pstemp $outpath.pdf") || print "Created $outpath.pdf\n";};

# copy ps file if requested
if ($ps) {copy($pstemp, "$outpath.ps") && print "Created $outpath.ps\n";};

# note: temporary directory will be deleted automatically on exit

