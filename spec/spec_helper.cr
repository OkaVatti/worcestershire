require "spec"
require "file"
require "../src/worcestershire"

# Helper to create a temporary file and yield its path, ensuring cleanup.
def with_tempfile(prefix = "test", suffix = "", &block : String ->)
  file = File.tempfile(prefix, suffix)
  begin
    yield file.path
  ensure
    file.close
    File.delete(file.path) if File.exists?(file.path)
  end
end

# Helper to create a temporary wordlist file.
def with_temp_wordlist(lines : Array(String), &block : String ->)
  with_tempfile("words", ".txt") do |path|
    File.write(path, lines.join("\n"))
    yield path
  end
end

# Helper to capture stdout for testing code that does not exit.
# This manually redirects STDOUT to a pipe, captures the output, and restores it.
def with_captured_stdout(&block)
  read_pipe, write_pipe = IO.pipe
  original_stdout = STDOUT.dup
  STDOUT.reopen(write_pipe)
  write_pipe.close

  yield

  STDOUT.reopen(original_stdout)
  original_stdout.close
  read_pipe.gets_to_end
ensure
  read_pipe.close if read_pipe
  write_pipe.close if write_pipe
  original_stdout.close if original_stdout
end

def with_captured_stderr(&block)
  read_pipe, write_pipe = IO.pipe
  original_stderr = STDERR.dup
  STDERR.reopen(write_pipe)
  write_pipe.close

  yield

  STDERR.reopen(original_stderr)
  original_stderr.close
  read_pipe.gets_to_end
ensure
  read_pipe.close if read_pipe
  write_pipe.close if write_pipe
  original_stderr.close if original_stderr
end

# Run the CLI in a separate process using `crystal run`.
# Returns a named tuple with :status (Bool), :output (String), :error (String).
def run_cli(args : Array(String))
  cmd = ["crystal", "run", "src/worcestershire.cr", "--"] + args
  output = IO::Memory.new
  error = IO::Memory.new
  status = Process.run(cmd[0], cmd, output: output, error: error)
  {status: status.success?, output: output.to_s, error: error.to_s}
end
