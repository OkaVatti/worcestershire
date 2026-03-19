require "progress_bar.cr/progress_bar"

module Worcestershire
  # Wrapper for progress bar to handle optional display
  class ProgressWrapper
    @bar : ProgressBar?
    @enabled : Bool
    @total : Int32

    def initialize(total : Int32, enabled : Bool)
      @enabled = enabled
      @total = total
      @bar = ProgressBar.new(ticks: total, completion_message: "Complete!") if enabled
    end

    def init(message : String = "")
      return unless @enabled
      @bar.try(&.init)
      @bar.try(&.message(message))
    end

    def tick
      return unless @enabled
      @bar.try(&.tick)
    end

    def increment(by : Int32 = 1)
      return unless @enabled
      by.times { @bar.try(&.tick) }
    end

    def finish
      return unless @enabled
      @bar.try(&.complete)
    end
  end
end