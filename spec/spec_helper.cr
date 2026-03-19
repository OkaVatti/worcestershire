require "spec"
require "file"
require "../src/worcestershire"

# Helper to create a temporary file and yield its path, ensuring cleanup.
def with_tempfile(prefix = "test", suffix = "", &block : String ->)
  file = File.tempfile(prefix, suffix)
  path = file.path
  # Close the tempfile handle immediately so the block can open the path freely.
  file.close
  begin
    yield path
  ensure
    File.delete(path) if File.exists?(path)
  end
end

# Helper to create a temporary wordlist file.
def with_temp_wordlist(lines : Array(String), &block : String ->)
  with_tempfile("words", ".txt") do |path|
    File.write(path, lines.join("\n"))
    yield path
  end
end

# Captures all output written to STDOUT during the block and returns it as a
# String.  The write end of the pipe is kept open until after the block
# returns, then closed to signal EOF to the reader.
def with_captured_stdout(&block) : String
  read_pipe, write_pipe = IO.pipe
  original_stdout = STDOUT.dup
  begin
    STDOUT.reopen(write_pipe)
    yield
    STDOUT.flush
  ensure
    STDOUT.reopen(original_stdout)
    write_pipe.close
  end
  output = read_pipe.gets_to_end
  read_pipe.close
  output
end

# Same as with_captured_stdout but for STDERR.
def with_captured_stderr(&block) : String
  read_pipe, write_pipe = IO.pipe
  original_stderr = STDERR.dup
  begin
    STDERR.reopen(write_pipe)
    yield
    STDERR.flush
  ensure
    STDERR.reopen(original_stderr)
    write_pipe.close
  end
  output = read_pipe.gets_to_end
  read_pipe.close
  output
end

# Run the CLI in a separate process.
# Returns a named tuple with :status (Bool), :output (String), :error (String).
def run_cli(args : Array(String))
  cmd = ["crystal", "run", "src/worcestershire.cr", "--"] + args
  output = IO::Memory.new
  error = IO::Memory.new
  status = Process.run(cmd[0], cmd, output: output, error: error)
  {status: status.success?, output: output.to_s, error: error.to_s}
end
