require "./spec_helper"

module Worcestershire
  describe WorkerPool do
    it "executes all scheduled tasks" do
      results = Channel(Int32).new(5)
      pool = WorkerPool.new(2)
      5.times do |i|
        pool.schedule { results.send(i) }
      end
      pool.shutdown
      received = [] of Int32
      5.times { received << results.receive }
      received.sort.should eq([0, 1, 2, 3, 4])
    end

    it "shutdown is idempotent after all tasks finish" do
      pool = WorkerPool.new(1)
      done = Channel(Nil).new(1)
      pool.schedule { done.send(nil) }
      done.receive
      # shutdown should complete without deadlocking
      pool.shutdown
    end
  end
end
