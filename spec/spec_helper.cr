require "spec"
require "file"
require "../src/worcestershire"

# ---------------------------------------------------------------------------
# Platform-aware binary path
# ---------------------------------------------------------------------------

BIN_PATH = {% if flag?(:windows) %}
             File.join(Dir.current, "bin", "worcestershire.exe")
           {% else %}
             File.join(Dir.current, "bin", "worcestershire")
           {% end %}

# ---------------------------------------------------------------------------
# Temp-file helpers
# ---------------------------------------------------------------------------

# Create a temporary file, yield its path, then delete it on exit.
def with_tempfile(prefix = "test", suffix = "", &block : String ->)
  file = File.tempfile(prefix, suffix)
  path = file.path
  file.close
  begin
    yield path
  ensure
    File.delete(path) if File.exists?(path)
  end
end

# Create a temporary wordlist file containing *lines*, one per line.
def with_temp_wordlist(lines : Array(String), &block : String ->)
  with_tempfile("words", ".txt") do |path|
    File.write(path, lines.join("\n"))
    yield path
  end
end

# ---------------------------------------------------------------------------
# stdout / stderr capture
# ---------------------------------------------------------------------------

def with_captured_stdout(&block) : String
  read_pipe, write_pipe = IO.pipe
  original = STDOUT.dup
  begin
    STDOUT.reopen(write_pipe)
    yield
    STDOUT.flush
  ensure
    STDOUT.reopen(original)
    write_pipe.close
  end
  out = read_pipe.gets_to_end
  read_pipe.close
  out
end

def with_captured_stderr(&block) : String
  read_pipe, write_pipe = IO.pipe
  original = STDERR.dup
  begin
    STDERR.reopen(write_pipe)
    yield
    STDERR.flush
  ensure
    STDERR.reopen(original)
    write_pipe.close
  end
  out = read_pipe.gets_to_end
  read_pipe.close
  out
end

# ---------------------------------------------------------------------------
# Subprocess helpers
# ---------------------------------------------------------------------------

# Run the worcestershire source directly with `crystal run`.
# Slow (recompiles each call) but works without a pre-built binary.
# Returns {status: Bool, output: String, error: String}.
def run_cli(args : Array(String))
  cmd_args = ["run", "src/worcestershire.cr", "--no-color", "--"] + args
  output = IO::Memory.new
  error = IO::Memory.new
  status = Process.run("crystal", cmd_args, output: output, error: error)
  {status: status.success?, output: output.to_s, error: error.to_s}
end

# Run the pre-compiled binary directly — fast, safe for integration tests.
# Raises if the binary does not exist.
def run_binary(args : Array(String)) : NamedTuple(status: Bool, output: String, error: String)
  raise "Binary not found at #{BIN_PATH}. Run 'shards build' first." \
    unless File.exists?(BIN_PATH)

  output = IO::Memory.new
  error = IO::Memory.new
  status = Process.run(BIN_PATH, args, output: output, error: error)
  {status: status.success?, output: output.to_s, error: error.to_s}
end
