module Worcestershire
  class ResumeState
    property last_word : String?
    property combinations_done : Array(Int32)
    property position : UInt64
    property timestamp : Time

    def initialize(@last_word = nil, @combinations_done = [] of Int32, @position = 0_u64)
      @timestamp = Time.utc
    end

    def save(path : String)
      File.write(path, to_json)
    end

    def self.load(path : String) : ResumeState?
      return nil unless File.exists?(path)
      data = File.read(path)
      from_json(data)
    rescue
      nil
    end

    def to_json : String
      {
        last_word:         @last_word,
        combinations_done: @combinations_done,
        position:          @position,
        timestamp:         @timestamp.to_s("%Y-%m-%d %H:%M:%S UTC"),
      }.to_json
    end

    def self.from_json(json : String) : ResumeState
      parsed = JSON.parse(json)
      new(
        parsed["last_word"]?.try(&.as_s),
        parsed["combinations_done"]?.try(&.as_a.map(&.as_i)) || [] of Int32,
        parsed["position"]?.try(&.as_i.to_u64) || 0_u64
      )
    end
  end
end
