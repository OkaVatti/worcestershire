module Worcestershire
  # WorkerPool manages a fixed number of fiber workers that pull tasks from a
  # shared queue channel.  shutdown drains the queue and waits for all workers
  # to exit cleanly.
  class WorkerPool
    @queue : Channel(Proc(Nil))
    @finished : Channel(Nil)
    @size : Int32

    def initialize(@size : Int32)
      @queue = Channel(Proc(Nil)).new
      @finished = Channel(Nil).new(@size)

      @size.times do
        spawn do
          # Each worker pulls tasks until the queue is closed.
          while task = @queue.receive?
            begin
              task.call
            rescue ex
              # Swallow task-level errors so the worker stays alive.
              STDERR.puts "WorkerPool task error: #{ex.message}"
            end
          end
        ensure
          @finished.send(nil)
        end
      end
    end

    def schedule(&task : ->)
      @queue.send(task)
    end

    # Close the queue (signals workers to stop) then wait for every worker to
    # finish.  Safe to call from the main fiber.
    def shutdown
      @queue.close
      @size.times { @finished.receive }
    end
  end
end
