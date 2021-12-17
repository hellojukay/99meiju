#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use HTTP::Tiny;
use Encode;
use HTML::Element;
use HTML::Query 'Query';
use Getopt::Long;

GetOptions(
    "o|output=s" => \( my $output ),
    "h|help"     => \( my $help ),
    "v|verbose"  => \( my $verbose ),
    "u|url=s"    => \( my $web )
);

sub usage($) {
    my $code = shift;
    my $msg  = <<EOF;
[options]  save all images to file.
    -h
    --help        Print help message

    -u
    --url     电视剧集合页面地址
EOF
    print($msg);
    exit($code);
}

if ($help) {
    usage(0);
}

binmode( STDOUT, ":utf8" );

sub get ($) {

    #    my $response = HTTP::Tiny->new->get(shift);
    #    die "Failed! $response->{status}\n" unless $response->{success};
    #    return decode( "utf8", $response->{content} );
    my $agent =
      "Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/81.0";
    my $url  = shift;
    my $cmd  = "curl -A \"$agent\" -s -k $url";
    my $html = `$cmd`;
    $html = decode( "utf8", $html );
    if ($verbose) {
        printf "%s\n", $cmd;
    }
    return $html;
}

sub get_indexs ($) {
    my $q     = Query( text => shift );
    my @links = $q->query('#playlist1 a')->get_elements();
    return map { sprintf "https://www.99meiju.org%s", $_->attr('href') } @links;
}

# 获取 title 标签中的集数
sub get_title ($) {
    my $html  = get(shift);
    my $q     = Query( text => $html );
    my @links = $q->query('title')->get_elements();
    my $title = $links[0]->as_trimmed_text;
    if ($title) {
        if ( $title =~ m/(第\d+集)/ ) {
            $title = $1;
        }
    }
    return $title;
}

sub get_m3u8 ($) {
    my $html = get(shift);

    # "url": "https:\/\/cdn.zoubuting.com\/20210624\/qrO7lWbu\/index.m3u8"
    my $url;
    if ( $html =~ m/"url":"(https.*?m3u8)"/ ) {
        $url = $1;
    }
    if ($url) {
        $url = $url =~ s/\\//gr;
    }
    return $url;
}

if ($verbose) {
    printf "now scrap from $web\n";
}
my $html  = get($web);
my @index = get_indexs($html);
foreach my $url (@index) {
    my $m3u8 = get_m3u8($url);
    printf "%s\t%s\n", $m3u8, get_title($url);
}
