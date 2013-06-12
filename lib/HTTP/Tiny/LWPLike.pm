package HTTP::Tiny::LWPLike;
use strict;
use warnings;
use HTTP::Tiny;
use HTTP::Response;
use Hash::MultiValue;

sub new {
    my $class = shift;
    my $self  = bless {}, $class;
    $self->{http} = @_ == 1 ? $_[0] : HTTP::Tiny->new(@_);
    $self;
}

sub _flatten_headers {
    my($self, $headers) = @_;

    my @hdrs;
    while (my($k, $v) = each %$headers) {
        if (ref $v eq 'ARRAY') {
            push @hdrs, map { ($k => $_) } @$v;
        } else {
            push @hdrs, $k => $v;
        }
    }

    return \@hdrs;
}

sub request {
    my($self, $req) = @_;

    my @headers;
    $req->headers->scan(sub { push @headers, @_ });

    my $response = $self->{http}->request(
        $req->method, $req->url, {
            headers => Hash::MultiValue->new(@headers)->mixed,
            content => $req->content,
        },
    );

    my $res = HTTP::Response->new(
        $response->{status},
        $response->{reason},
        [ Hash::MultiValue->from_mixed($response->{headers})->flatten ],
        $response->{content},
    );
    $res->request($req);

    return $res;
}

1;

__END__

=head1 NAME

HTTP::Tiny::LWPLike - HTTP::Request/Response compatible interface with HTTP::Tiny backend

=head1 SYNOPSIS

  use HTTP::Tiny::LWPLike;

  my $request = HTTP::Request->new(GET => 'http://perl.com/');

  my $ua = HTTP::Tiny::LWPLike->new;
  my $res = $ua->request($request); # returns HTTP::Response

=head1 DESCRIPTION

This module is an adapter object that implements one method,
C<request> that acts like L<LWP::UserAgent>'s request method
i.e. takes HTTP::Request object and returns HTTP::Response object.

=head1 INCOMPATIBILITIES

=over 4

=item *

SSL is not supported unless required modules are installed.

=item *

authentication is not handled via the UA methods. You can encode the
C<Authorization> headers in the C<$request> by yourself.

=cut

There might be more - see L<HTTP::Tiny> for the details.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<HTTP::Tiny> L<LWP::UserAgent>

=cut
