#!/usr/bin/perl

use strict;
use warnings;
use HTML::TagParser;
use Data::Dumper;
use JSON::XS;
use REST::Client;

chdir("your working directory");
my $webhook_url = 'your webhook url';


my $dj = $ARGV[0];
my $dj_display = $ARGV[1];
if ($dj eq "" or $dj_display eq "") {
        print "dj nicht angegeben";
        exit 3;
}

file_old_article();



sub file_old_article {
  my $old_title;
  open(FH, '<', $dj) or die $!;
  while (<FH>) {
    $old_title = $_;
  }
  close (FH);

  my $curl = `curl -s https://www.1001tracklists.com/dj/$dj/index.html`;
  my $html = HTML::TagParser->new($curl);
  my @list = $html->getElementsByClassName("bItm action oItm ");

  my $elem = $list[0]->subTree;


  my $set_title = $elem->{flat}->[3]->[3];

  if ($old_title ne $set_title) {
    my $set_link = $elem->{flat}->[3]->[4]->{href};
    my $set_pic = $elem->{flat}->[0]->[4]->{"data-src"};
    my @split = split('//', $set_pic);
    $set_pic = $split[1];
    my $set_playtime;


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
    push(@fields_arr, {name => $set_title, value => "https://www.1001tracklist.com" . $set_link});
    push(@fields_arr, {name => "Playtime", value => $set_playtime, inline => "true"});
    push(@fields_arr, {name => "Media", value => $set_media, inline => "true"});


    my @image_arr;
    push(@image_arr, {url => "https://$set_pic"});

    my $payload = {
      username => "1001-Boii",
      embeds => [{"title" => "Neues Set von $dj_display", "fields" => [@fields_arr], "image" => @image_arr}]
    };

    my $json = encode_json($payload);
    my $rest = REST::Client->new(timeout => 5);
    $rest->addHeader('Content-Type', 'application/json');

    open(FH, '>', $dj) or die $!;
    print FH $set_title;
    close (FH);
    $rest->POST($webhook_url, $json);
    if ($rest->responseCode > 299 or $rest->responseCode <= 200) {
      print Dumper($rest->responseCode);
      print Dumper($rest->responseContent);
      print Dumper($payload);
      exit 2;
    }
    print "Neues Set von $dj_display";
    exit 1;
   } else {
     print "Kein neues Set fuer $dj gefunden";
     exit 0;
   }

}
