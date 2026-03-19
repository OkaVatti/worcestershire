require "json"

module Worcestershire
  class ResumeState
    include JSON::Serializable

    property last_word : String?
    property combinations_done : Array(Int32)
    property position : UInt64
    # Stored as an ISO-8601 string because Time is not directly JSON::Serializable.
    property timestamp : String

    def initialize(
      @last_word = nil,
      @combinations_done = [] of Int32,
      @position = 0_u64,
    )
      @timestamp = Time.utc.to_s("%Y-%m-%dT%H:%M:%SZ")
    end

    def save(path : String)
      File.write(path, to_json)
    end

    def self.load(path : String) : ResumeState?
      return nil unless File.exists?(path)
      from_json(File.read(path))
    rescue
      nil
    end
  end
end
