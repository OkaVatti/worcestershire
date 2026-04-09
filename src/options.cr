require "yaml"
require "./utils"

module Worcestershire
  class Options
    property words : Array(String)
    property input_files : Array(String)
    property output_file : String
    property combinations : Array(Int32)
    property depth : Int32
    property min_length : Int32
    property max_length : Int32
    property encoding : String?
    property verbose : Bool
    property no_progress : Bool
    property list_combinations : Bool
    property format : String
    property compress : Bool
    property config_file : String?
    property max_combinations : UInt64?
    property rule_file : String?
    property resume : String?
    property log_file : String?
    property log_level : String
    property buffer_size : Int32
    property no_color : Bool
    property force : Bool
    property dry_run : Bool
    property quiet : Bool
    property preset : String?
    property suggest : Bool
    property homograph_dict : String?
    property leet_dict : String?
    property salt_dict : String?
    property affix_dict : String?
    property parallel : Bool
    property workers : Int32
    property cache_size : Int32
    property max_memory : UInt64?
    property pipeline : Array(Int32)?
    property deduplicate : Bool
    property output_delimiter : String
    property benchmark : Bool
    property pattern : String?

    def initialize(
      @words = [] of String,
      @input_files = [] of String,
      @output_file = "output.lst",
      @combinations = [] of Int32,
      @depth = 3,
      @min_length = 0,
      @max_length = 20,
      @encoding = nil,
      @verbose = false,
      @no_progress = false,
      @list_combinations = false,
      @format = "txt",
      @compress = false,
      @config_file = nil,
      @max_combinations = nil,
      @rule_file = nil,
      @resume = nil,
      @log_file = nil,
      @log_level = "info",
      @buffer_size = 1_048_576,
      @no_color = false,
      @force = false,
      @dry_run = false,
      @quiet = false,
      @preset = nil,
      @suggest = false,
      @homograph_dict = nil,
      @leet_dict = nil,
      @salt_dict = nil,
      @affix_dict = nil,
      @parallel = false,
      @workers = 4,
      @cache_size = 1000,
      @max_memory = nil,
      @pipeline = nil,
      @deduplicate = false,
      @output_delimiter = "",
      @benchmark = false,
      @pattern = nil,
    )
    end

    def load_config!
      return unless config = @config_file
      begin
        yaml = File.open(config) { |f| YAML.parse(f) }
        if h = yaml.as_h?
          @depth = h["depth"]?.try(&.as_i) || @depth
          @min_length = h["min_length"]?.try(&.as_i) || @min_length
          @max_length = h["max_length"]?.try(&.as_i) || @max_length
          @format = h["format"]?.try(&.as_s) || @format
          @compress = h["compress"]?.try(&.as_bool) || @compress
          @max_combinations = h["max_combinations"]?.try(&.as_i.to_u64) || @max_combinations
          @buffer_size = h["buffer_size"]?.try(&.as_i) || @buffer_size
          @workers = h["workers"]?.try(&.as_i) || @workers
          @cache_size = h["cache_size"]?.try(&.as_i) || @cache_size
          @max_memory = h["max_memory"]?.try(&.as_i.to_u64) || @max_memory
          @output_delimiter = h["output_delimiter"]?.try(&.as_s) || @output_delimiter
          @deduplicate = h["deduplicate"]?.try(&.as_bool) || @deduplicate
          if combos = h["combinations"]?.try(&.as_a)
            @combinations = combos.map(&.as_i) if @combinations.empty?
          end
          if steps = h["pipeline"]?.try(&.as_a)
            @pipeline = steps.map(&.as_i)
          end
        end
      rescue e
        Utils.print_error("Failed to load config: #{e.message}")
        exit(1)
      end
    end
  end
end
