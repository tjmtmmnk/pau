package Pau::Util;
use strict;
use warnings;
use File::Slurp qw(read_file);
use JSON::XS    qw(encode_json decode_json);
use Try::Tiny;

sub last_modified_at {
    my ($class, $filename) = @_;
    my $stat = [ stat $filename ];
    return scalar(@$stat) > 0 ? $stat->[9] : 0;
}

sub read_json_file {
    my ($class, $filename) = @_;
    my $data = try {
        read_file($filename)
    }
    catch {
        undef;
    };
    return $data ? decode_json($data) : undef;
}

sub write_json_file {
    my ($class, $filename, $data) = @_;
    open my $fh, '>', $filename or die qq/Can't open file "$filename" : $!/;
    print $fh encode_json($data);
    close $fh or die qq/Can't close file $filename: $!/;
}

1;
