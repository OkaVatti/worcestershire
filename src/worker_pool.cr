module Worcestershire
  class WorkerPool
    @workers = [] of Fiber
    @queue = Channel(->).new
    @done = Channel(Nil).new

    def initialize(size : Int32)
      size.times do
        @workers << spawn do
          while task = @queue.receive?
            task.call
          end
        rescue Channel::ClosedError
          next
        end
      end
    end

    def schedule(&task : ->)
      @queue.send(task)
    end

    def shutdown
      @queue.close
      @workers.each { |f| f.resume }        # wake any sleeping fibers
      @workers.size.times { @done.receive } # wait for all to finish
    end
  end
end
