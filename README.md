
UTF-8 encoder and decoder, simple wide-string type, and stream I/O
==================================================================

This library contains a Standard ML implementation of a wide-string
type and an I/O type, with fast encoder and decoder to and from UTF-8.

(Although the encoder and decoder are provided as separate structures,
they are given only minimal signatures and aren't really intended to
be used separately. The general-purpose interface is through the
string structure and its signature, and the I/O structure.)

The decoder is designed for safe interoperability: it identifies
invalid and overlong encodings and substitutes the replacement
character for each such sequence as soon as it is recognised. It does
the same thing with codepoints above the 17-plane Unicode limit.

Copyright 2015-2018 Chris Cannam.

Decoder inspired by `Utf8.sml` by Martin Elsman
(https://github.com/melsman/unicode).

Encoder influenced by `utf8.sml` by John Reppy.

MIT/X11 licence. See the file COPYING for details.
