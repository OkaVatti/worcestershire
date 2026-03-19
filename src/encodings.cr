require "digest"
require "base64"
require "uri"

module Worcestershire
  # Available encodings/hashes
  ENCODING_TYPES = {
    "base64"  => ->(s : String) { Base64.encode(s) },
    "base32"  => ->(s : String) { Base64.strict_encode(s) }, # Crystal's Base64 uses strict by default
    "url"     => ->(s : String) { URI.encode_www_form(s) },
    "md5"     => ->(s : String) { Digest::MD5.hexdigest(s) },
    "sha1"    => ->(s : String) { Digest::SHA1.hexdigest(s) },
    "sha256"  => ->(s : String) { Digest::SHA256.hexdigest(s) },
    "sha512"  => ->(s : String) { Digest::SHA512.hexdigest(s) },
    "hex"     => ->(s : String) { s.bytes.map { |b| b.to_s(16).rjust(2, '0') }.join },
  }
end