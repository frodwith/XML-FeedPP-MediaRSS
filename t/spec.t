use warnings;
use strict;

use Test::More;
use Test::Deep;
use XML::FeedPP;
use XML::FeedPP::MediaRSS;

sub spec_ok {
    my ($xml, $expected, $note) = @_;
    my $feed  = XML::FeedPP->new($xml, -type => 'string', use_ixhash => 1);
    my $media = XML::FeedPP::MediaRSS->new($feed);
    my @got   = map { $media->for_item($_) } ($feed->get_item);
    use Data::Dumper::Concise;
    print Dumper \@got;
    print Dumper $expected;
    cmp_deeply(\@got, noclass($expected), $note);
}

{
    my $xml = <<'XML';
<rss version="2.0" xmlns:media="http://search.yahoo.com/mrss/"
xmlns:creativeCommons="http://backend.userland.com/creativeCommonsRssModule">
<channel>
<title>My Movie Review Site</title>
<link>http://www.foo.com</link>
<description>I review movies.</description>
    <item>
        <title>Movie Title: Is this a good movie?</title>
        <link>http://www.foo.com/item1.htm</link>
        <media:content url="http://www.foo.com/trailer.mov" 
        fileSize="12216320" type="video/quicktime" expression="sample"/>
        <creativeCommons:license>
        http://www.creativecommons.org/licenses/by-nc/1.0
        </creativeCommons:license>
        <media:rating>nonadult</media:rating>
    </item>
</channel>
</rss>
XML
    my $expected = [
        {
            url        => 'http://www.foo.com/trailer.mov',
            fileSize   => 12216320,
            type       => 'video/quicktime',
            expression => 'sample',
            rating     => {
                simple => 'nonadult',
            },
        }
    ];
    spec_ok(
        $xml, $expected, 
        'A movie review with a trailer, using a Creative Commons license.'
    );
}

{
    my $xml = <<'XML';
<rss version="2.0" xmlns:media="http://search.yahoo.com/mrss/"
xmlns:dcterms="http://purl.org/dc/terms/">
<channel>
<title>Music Videos 101</title>
<link>http://www.foo.com</link>
<description>Discussions of great videos</description>
    <item>
        <title>The latest video from an artist</title>
        <link>http://www.foo.com/item1.htm</link>
        <media:content url="http://www.foo.com/movie.mov" fileSize="12216320" 
        type="video/quicktime" expression="full">
        <media:player url="http://www.foo.com/player?id=1111" 
        height="200" width="400"/>
        <media:hash algo="md5">dfdec888b72151965a34b4b59031290a</media:hash>
        <media:credit role="producer">producer's name</media:credit>
        <media:credit role="artist">artist's name</media:credit>
        <media:category scheme="http://blah.com/scheme">music/artist 
        name/album/song</media:category>
        <media:text type="plain">
        Oh, say, can you see, by the dawn's early light
        </media:text>
        <media:rating>nonadult</media:rating>
        <dcterms:valid>
            start=2002-10-13T09:00+01:00;
            end=2002-10-17T17:00+01:00;
            scheme=W3C-DTF
        </dcterms:valid>
        </media:content>
    </item>
</channel>
</rss>
XML
    my $expected = [
        {
            category => {
                'http://blah.com/scheme' => 
                    re(qr{music/\s*artist\s*name/\s*album/\s*song})
            },
            credit => {
                'urn:ebu' => {
                    artist   => [q"artist's name"],
                    producer => [q"producer's name"]
                }
            },
            expression => 'full',
            fileSize => 12216320,
            hash => {
                algorithm => 'md5',
                checksum  => 'dfdec888b72151965a34b4b59031290a'
            },
            player => {
                url    => 'http://www.foo.com/player?id=1111',
                width  => 400,
                height => 200,
            },
            rating => {
                simple => 'nonadult'
            },
            text => {
                text => re(
                    qr"^\s*Oh, say, can you see, by the dawn's early light\s*$",
                ),
                type => 'plain'
            },
            type => 'video/quicktime',
            url => 'http://www.foo.com/movie.mov'
        }
    ];
    spec_ok($xml, $expected, 'A music video with a link to a player window, and additional metadata about the video, including expiration date.');
}

{
    my $xml = <<'XML';
<rss version="2.0" xmlns:media="http://search.yahoo.com/mrss/">
<channel>
<title>Song Site</title>
<link>http://www.foo.com</link>
<description>Discussion on different songs</description>
    <item>
        <title>These songs make me think about blah</title>
        <link>http://www.foo.com/item1.htm</link>
        <media:content url="http://www.foo.com/band1-song1.mp3" 
        fileSize="1000" type="audio/mpeg" expression="full">
        <media:credit role="musician">member of band1</media:credit>
        <media:category>music/band1/album/song</media:category>
        <media:rating>nonadult</media:rating>
        </media:content>
        <media:content url="http://www.foo.com/band2-song1.mp3" 
        fileSize="2000" type="audio/mpeg" expression="full">
        <media:credit role="musician">member of band2</media:credit>
        <media:category>music/band2/album/song</media:category>
        <media:rating>nonadult</media:rating>
        </media:content>
        <media:content url="http://www.foo.com/band3-song1.mp3" 
        fileSize="1500" type="audio/mpeg" expression="full">
        <media:credit role="musician">member of band3</media:credit>
        <media:category>music/band3/album/song</media:category>
        <media:rating>nonadult</media:rating>
        </media:content>
    </item>
</channel>
</rss>
XML
    my $expected = [
        {
            category => {
                'none' => 'music/band1/album/song'
            },
            credit => {
                'urn:ebu' => {
                    musician => [
                        'member of band1'
                    ]
                }
            },
            expression => 'full',
            fileSize => 1000,
            rating => {
                simple => 'nonadult'
            },
            type => 'audio/mpeg',
            url => 'http://www.foo.com/band1-song1.mp3'
        },
        {
            category => {
                'none' => 'music/band2/album/song'
            },
            credit => {
                'urn:ebu' => {
                    musician => [
                        'member of band2'
                    ]
                }
            },
            expression => 'full',
            fileSize => 2000,
            rating => {
                simple => 'nonadult'
            },
            type => 'audio/mpeg',
            url => 'http://www.foo.com/band2-song1.mp3'
        },
        {
            category => {
                'none' => 'music/band3/album/song'
            },
            credit => {
                'urn:ebu' => {
                    musician => [
                        'member of band3'
                    ]
                }
            },
            expression => 'full',
            fileSize => 1500,
            rating => {
                simple => 'nonadult'
            },
            type => 'audio/mpeg',
            url => 'http://www.foo.com/band3-song1.mp3'
        },
    ];
    spec_ok($xml, $expected, 
        'Several different songs that relate to the same topic.');
}

{
    my $xml = <<'XML';

<rss version="2.0" xmlns:media="http://search.yahoo.com/mrss/">
<channel>
<title>Song Site</title>
<link>http://www.foo.com</link>
<description>Songs galore at different bitrates</description>
    <item>
        <title>Cool song by an artist</title>
        <link>http://www.foo.com/item1.htm</link>
        <media:group>
            <media:content url="http://www.foo.com/song64kbps.mp3" 
            fileSize="1000" bitrate="64" type="audio/mpeg" 
            isDefault="true" expression="full"/>
            <media:content url="http://www.foo.com/song128kbps.mp3" 
            fileSize="2000" bitrate="128" type="audio/mpeg" 
            expression="full"/>
            <media:content url="http://www.foo.com/song256kbps.mp3" 
            fileSize="4000" bitrate="256" type="audio/mpeg" 
            expression="full"/>
            <media:content url="http://www.foo.com/song512kbps.mp3.torrent" 
            fileSize="8000" type="application/x-bittorrent;enclosed=audio/mpeg" 
            expression="full"/>
            <media:content url="http://www.foo.com/song.wav" 
            fileSize="16000" type="audio/x-wav" expression="full"/>
            <media:credit role="musician">band member 1</media:credit>
            <media:credit role="musician">band member 2</media:credit>
            <media:category>music/artist name/album/song</media:category>
            <media:rating>nonadult</media:rating>
        </media:group>
    </item>
</channel>
</rss>
XML
    my $expected = [
        {
            url        => 'http://www.foo.com/song64kbps.mp3',
            fileSize   => 1000,
            bitrate    => 64,
            type       => 'audio/mpeg',
            expression => 'full',
            isDefault  => 1,
            credit     => {
                'urn:ebu' => {
                    musician => [
                        'band member 1',
                        'band member 2',
                    ]
                }
            },
            category => {
                'none' => 'music/artist name/album/song',
            },
            rating => {
                simple => 'nonadult',
            },
        },
        {
            url        => 'http://www.foo.com/song128kbps.mp3',
            fileSize   => 2000,
            bitrate    => 128,
            type       => 'audio/mpeg',
            expression => 'full',
            credit    => {
                'urn:ebu' => {
                    musician => [
                        'band member 1',
                        'band member 2',
                    ]
                }
            },
            category => {
                'none' => 'music/artist name/album/song',
            },
            rating => {
                simple => 'nonadult',
            },
        },
        {
            url        => 'http://www.foo.com/song256kbps.mp3',
            fileSize   => 4000,
            bitrate    => 256,
            type       => 'audio/mpeg',
            expression => 'full',
            credit    => {
                'urn:ebu' => {
                    musician => [
                        'band member 1',
                        'band member 2',
                    ]
                }
            },
            category => {
                'none' => 'music/artist name/album/song',
            },
            rating => {
                simple => 'nonadult',
            },
        },
        {
            url        => 'http://www.foo.com/song512kbps.mp3.torrent',
            fileSize   => 8000,
            type       => 'application/x-bittorrent;enclosed=audio/mpeg',
            expression => 'full',
            credit    => {
                'urn:ebu' => {
                    musician => [
                        'band member 1',
                        'band member 2',
                    ]
                }
            },
            category => {
                'none' => 'music/artist name/album/song',
            },
            rating => {
                simple => 'nonadult',
            },
        },
        {
            url        => 'http://www.foo.com/song.wav',
            fileSize   => 16000,
            type       => 'audio/x-wav',
            expression => 'full',
            credit    => {
                'urn:ebu' => {
                    musician => [
                        'band member 1',
                        'band member 2',
                    ]
                }
            },
            category => {
                'none' => 'music/artist name/album/song',
            },
            rating => {
                simple => 'nonadult',
            },
        }
    ];
    spec_ok($xml, $expected, 'Same song with multiple files at different bitrates and encodings.  (Bittorrent example as well)');
}
