package Gitalist::Util;

use Sub::Exporter -setup => {
   exports => ['to_utf8']
};

=pod

=head1 NAME

Gitalist::Util - Your usual catch all utility function package.

=cut

# decode sequences of octets in utf8 into Perl's internal form,
# which is utf-8 with utf8 flag set if needed.  gitweb writes out
# in utf-8 thanks to "binmode STDOUT, ':utf8'" at beginning
sub to_utf8 {
	my $str = shift;
	if (utf8::valid($str)) {
		utf8::decode($str);
		return $str;
	} else {
		return decode($fallback_encoding, $str, Encode::FB_DEFAULT);
	}
}

1;
