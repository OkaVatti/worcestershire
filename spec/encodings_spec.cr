require "./spec_helper"

module Worcestershire
  describe "ENCODING_TYPES" do
    it "base64" do
      ENCODING_TYPES["base64"].call("test").should eq(Base64.encode("test"))
    end

    it "base32" do
      ENCODING_TYPES["base32"].call("test").should eq(Base64.strict_encode("test"))
    end

    it "url" do
      ENCODING_TYPES["url"].call("hello world").should eq(URI.encode_www_form("hello world"))
    end

    it "md5" do
      ENCODING_TYPES["md5"].call("test").should eq(Digest::MD5.hexdigest("test"))
    end

    it "sha1" do
      ENCODING_TYPES["sha1"].call("test").should eq(Digest::SHA1.hexdigest("test"))
    end

    it "sha256" do
      ENCODING_TYPES["sha256"].call("test").should eq(Digest::SHA256.hexdigest("test"))
    end

    it "sha512" do
      ENCODING_TYPES["sha512"].call("test").should eq(Digest::SHA512.hexdigest("test"))
    end

    it "hex" do
      ENCODING_TYPES["hex"].call("test").should eq("74657374")
    end
  end
end
