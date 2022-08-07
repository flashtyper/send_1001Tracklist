#!/usr/bin/perl

use strict;
use warnings;
use HTML::TagParser;
use Data::Dumper;
use JSON::XS;
use REST::Client;
use URI::Fetch;


chdir("<your working directory>");
my $webhook_url = '<your discord webhook url';





main();


sub httpfetch {
        my $dj = shift;
        my $res = URI::Fetch->fetch("https://www.1001tracklists.com/dj/$dj/index.html") or die URI::Fetch->errstr;
        return $res->content if $res->is_success;
        return -1;
}

sub htmlparse {
        my $content = shift;
        my $html = HTML::TagParser->new($content);
        my @list = $html->getElementsByClassName("bItm action oItm ");

        if (scalar @list != 0) {
                my $elem = $list[0]->subTree;
                return $elem;
        } else {
                return -1;
        }
}




sub generateDiscordMessage {
        my ($elem, $new_title, $dj_display) = @_;

        # getting basic information about the new playlist
        my $set_link = $elem->{flat}->[3]->[4]->{href};
        my $set_pic = $elem->{flat}->[0]->[4]->{"data-src"};
        my @split = split('//', $set_pic);
        $set_pic = $split[1];


        # getting the available media (e.g. soundcloud, youtube ....)
        my %media;
        foreach my $innerElem (@{$elem->{flat}}) {
                my $innerTitle = $innerElem->[4]->{title};
                if (defined($innerTitle)) {
                        if ($innerTitle eq "with youtube video") {
                                $media{"Youtube"} = 1;
                        } elsif ($innerTitle eq "with soundcloud link") {
                                $media{"Soundcloud"} = 1;
                        } elsif ($innerTitle eq "with mixcloud link") {
                                $media{"Mixcloud"} = 1;
                        } elsif ($innerTitle eq "with audio link") {
                        $media{"Other"} = 1;
                        }
                }
        }

        # concat those media sources
        my $set_media = "";
        my $media_size = keys %media;
        if ($media_size > 0) {
                my @media_arr = keys %media;
                for (my $i=0; $i < scalar(@media_arr); $i++) {
                        $set_media = $set_media . $media_arr[$i] . ", ";
                }
                chop($set_media);
                chop($set_media);
        } else {
                $set_media = "not available";
        }

        # getting the playtime of the playlist if available
        my $set_playtime;
        for (my $i = 0; $i < scalar(@{$elem->{flat}}) - 1; $i++) {
                my $curr = $elem->{flat}->[$i]->[4]->{class};
                if (defined($curr)) {
                        if ($curr eq "fa fa-clock-o fa-20 spR") {
                                $set_playtime = $elem->{flat}->[$i + 1]->[3];
                                last;
                        }
                }
        }
        if (!defined($set_playtime)) {
                $set_playtime = "not available";
        }

        my @fields_arr;
        push(@fields_arr, {name => $new_title, value => "https://www.1001tracklists.com" . $set_link});
        push(@fields_arr, {name => "Playtime", value => $set_playtime, inline => "true"});
        push(@fields_arr, {name => "Media", value => $set_media, inline => "true"});


        my @image_arr;
        push(@image_arr, {url => "https://$set_pic"});

        my $payload = {
                username => "1001-Boii",
                embeds => [{"title" => "Neues Set von $dj_display", "fields" => [@fields_arr], "image" => @image_arr}]
        };
        return $payload;
}


sub generateJSON {
        my $payload = shift;
        my $json = encode_json($payload);
        return $json;
}

sub sendMessage {
        my $json_payload = shift;
        my $rest = REST::Client->new(timeout => 5);
        $rest->addHeader('Content-Type', 'application/json');
        $rest->POST($webhook_url, $json_payload);
        return ($rest->responseCode, $rest->responseContent);
}


sub main {
        my $dj = $ARGV[0];
        my $dj_display = $ARGV[1];
        if ($dj eq "" or $dj_display eq "") {
                print "Usage: ./script.pl <djname> <dj_displayname>";
                exit 3;
        }
        my $old_title;
        open(FH, '<', $dj) or die $!;
        while (<FH>) {
                $old_title = $_;
        }
        close (FH);
        my $content = httpfetch($dj);
        if ($content eq -1) {
                print "Failed to fetch url from 1001tracklist";
                exit 3;
        }
        my $parsed = htmlparse($content);
        if ($parsed eq -1) {
                print "Failed to parse html content";
                exit 3;
        }

        my $new_title = $parsed->{flat}->[3]->[3];
        if ($old_title ne $new_title) {
                my $payload = generateDiscordMessage($parsed, $new_title, $dj_display);
                my $payload_json = generateJSON($payload);
                my ($httpResponseCode, $httpResponseContent) = sendMessage($payload_json);
                if ($httpResponseCode > 299 or $httpResponseCode <= 200) {
                        print Dumper($httpResponseCode);
                        print Dumper($httpResponseContent);
                        print Dumper($payload);
                        exit 3;
                } else {
                        open(FH, '>', $dj) or die $!;
                        print FH $new_title;
                        close (FH);
                        print "New set from $dj_display found!";
                        exit 1;
                }
        } else {
                print "Nothing new for $dj_display";
                exit 0;
        }
}
