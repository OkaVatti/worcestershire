require "./spec_helper"

module Worcestershire
  describe WorkerPool do
    it "executes tasks" do
      results = Channel(Int32).new
      pool = WorkerPool.new(2)
      5.times do |i|
        pool.schedule { results.send(i) }
      end
      pool.shutdown
      received = [] of Int32
      5.times { received << results.receive }
      received.sort.should eq([0, 1, 2, 3, 4])
    end
  end
end
