#!/usr/bin/perl -wT
#
# name: pingweb.pl
# author: jgor <jgor@indiecom.org>
# created: 2010-02-02
#
# This script determines whether a given webpage is available, and optionally
# sends an email alert upon failure or unexpected content (e.g. http error).

package Local::PingWeb;

use strict;
use warnings;
use Getopt::Std;
use LWP::UserAgent;

########## Begin Configuration ##########
#
# default_timeout : timeout value (in seconds) for http request
my $default_timeout = 45;
#
#
# default_from_addr : From: address for email alerts
my $default_from_addr = 'pingweb@example.com';
#
#
# default_pattern : pattern to verify webpage is operational
my $default_pattern = '</html>';
#
#
# default_status_file : file pingweb uses to track down/up status between runs
my $default_status_file = '/tmp/pingweb_down';
#
#
# default_name : webpage name used in email alert
my $default_name = 'webpage';
#
#
# user_agent : custom user agent used in the http requests
my $user_agent = 'PingWeb/0.1';
#
########## End Configuration   ##########

__PACKAGE__->main() unless caller;

sub main {
    my %opt;
    my $opt_string = 'b:c:de:f:hn:p:s:t:v';
    getopts ( "$opt_string", \%opt ) or usage();
    usage() if $opt{h};
    usage() unless $#ARGV+1 == 1;

    my $debug = $opt{d};
    my $verbose = $opt{v};

    my @to_addr   = split(/,/, $opt{e}) if $opt{e};
    $_ = ($_ =~ /(\w{1}[\w\-.]*)\@([\w\-.]+)/ ? "$1\@$2" : undef) foreach (@to_addr);

    my @cc_addr   = split(/,/, $opt{c}) if $opt{c};
    $_ = ($_ =~ /(\w{1}[\w\-.]*)\@([\w\-.]+)/ ? "$1\@$2" : undef) foreach (@cc_addr);

    my @bcc_addr  = split(/,/, $opt{b}) if $opt{b};
    $_ = ($_ =~ /(\w{1}[\w\-.]*)\@([\w\-.]+)/ ? "$1\@$2" : undef) foreach (@bcc_addr);

    my $from_addr = $opt{f} ? ($opt{f} =~ /(\w{1}[\w\-.]*)\@([\w\-.]+)/ ? "$1\@$2" : $default_from_addr) : $default_from_addr;

    my $name = $opt{n} ? ($opt{n} =~ /([\w\s\d\-_\.]+)/ ? $1 : $default_name) : $default_name;
    print STDERR "name = " . $name . "\n" if $debug;

    my $pattern = $opt{p} ? $opt{p} : $default_pattern;
    print STDERR "pattern = " . $pattern . "\n" if $debug;

    my $status_file = $opt{s} ? ($opt{s} =~ /([^\0\`\$]+)/ ? $1 : $default_status_file) : $default_status_file;
    print STDERR "status_file = " . $status_file . "\n" if $debug;

    my $timeout = $opt{t} ? ($opt{t} =~ /(\d+)/ ? $1 : $default_timeout) : $default_timeout;
    print STDERR "timeout = " . $timeout . "\n" if $debug;

    my $url = $ARGV[0];
    print STDERR "url = " . $url . "\n" if $debug;

    my $ua = LWP::UserAgent->new;
    $ua->agent($user_agent . ' ' . $ua->_agent);
    $ua->timeout($timeout);
    my $request = HTTP::Request->new('GET', $url);
    my $response = $ua->request($request);

    my $content = $response->is_success ? $response->content : undef;

    if (defined $content) {
        if ($content =~ /$pattern/) {
        print "The page is available.\n" if ($verbose || !(@to_addr));
                if (-e $status_file) {
                    unlink($status_file);
                    alert($from_addr, \@to_addr, \@cc_addr, \@bcc_addr, $url, $name, 'back up') if @to_addr;
                }
                exit 0;
        }
        else {
        print "Pattern not found.\n" if ($verbose || !(@to_addr));
                if (! -e $status_file) {
            open(FH, '>', $status_file) or die $!;
            close(FH) or die $!;
            alert($from_addr, \@to_addr, \@cc_addr, \@bcc_addr, $url, $name, 'DOWN') if @to_addr;
                }
                exit 1;
        }
    }
    else {
        print "No page returned.\n" if ($verbose || !(@to_addr));
        if (! -e $status_file) {
            open(FH, '>', $status_file) or die $!;
            close(FH) or die $!;
            alert($from_addr, \@to_addr, \@cc_addr, \@bcc_addr, $url, $name, 'DOWN') if @to_addr;
        }
        exit 1;
    }
}

sub alert {
    my $from_addr = shift;
    my $to_addr   = shift;
    my $cc_addr   = shift;
    my $bcc_addr  = shift;
    my $url       = shift;
    my $name      = shift;
    my $status    = shift;

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my $timestamp = sprintf '%d-%02d-%02d %02d:%02d:%02d', $year + 1900, $mon + 1, $mday, $hour, $min, $sec;

    local $ENV{'PATH'} = '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin';
    open(MAIL, "| sendmail -t") or die $!;

    print MAIL 'From: ' . $from_addr . "\n";
    print MAIL 'To: ' . $_ . "\n" foreach (@$to_addr);
    print MAIL 'Cc: ' . $_ . "\n" foreach (@$cc_addr);
    print MAIL 'Bcc: ' . $_ . "\n" foreach (@$bcc_addr);
    print MAIL 'Subject: Monitor Alert: ' . $name . ' is ' . $status . "\n\n";
    print MAIL $url . ' is ' . $status . ' at ' . $timestamp . "\n";

    close(MAIL) or die $!;

    return;
}

sub usage {
    print STDERR << "EOF";

This script determines whether a given webpage is available.

usage: $0 [-hdv] [-e eml1,eml2] [-c eml3,eml4] [-b eml5,eml6] [-f from_eml] [-n name] [-p pattern] [-s tmpfile] [-t timeout] url

-h      : this (help) message
-d      : debug output
-v      : verbose output
-e eml1,eml2    : comma-separated list of To: addresses for email alert
          (email alerts are enabled iff this is provided)
-c eml3,eml4    : comma-separated list of Cc: addresses for email alert
-b eml5,eml6    : comma-separated list of Bcc: addresses for email alert
-f from_eml : From: address for email alert
-n name     : friendly name of webpage, used in email alerts
-p pattern  : pattern (regex) to match on valid webpage
-s tmpfile  : unique temporary file used to track page status between runs
-t timeout  : timeout (in seconds) to wait for an HTTP response

example: $0 -p "[Ww]elcome \\w+ Example\\.com" -e support\@example.com -c boss\@example.com,qa\@example.com -f monitor\@example.com http://www.example.com/

EOF
    exit;
}

