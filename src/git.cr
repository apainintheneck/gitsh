require "process"

module Git
  @@executable_path : String = begin
    Process.find_executable("git").not_nil!
  rescue NilAssertionError
    abort "Error: Git cannot be found in path"
  end

  def self.executable_path : String
    @@executable_path
  end

  # Whether or not we are currently in a git repo.
  def self.repo? : Bool
    buffer = IO::Memory.new

    Process.run(
      command: executable_path,
      args: %w[rev-parse --is-inside-work-tree],
      output: buffer,
    )

    buffer.to_s.strip == "true"
  end

  # The name of the current branch or nil if there isn't one.
  def self.current_branch : String?
    buffer = IO::Memory.new

    Process.run(
      command: executable_path,
      args: %w[rev-parse --abbrev-ref HEAD],
      output: buffer,
    )

    branch = buffer.to_s.strip
    return if branch.empty?

    branch
  end

  record Changes, staged_count : UInt32, unstaged_count : UInt32

  # Get the counts of uncommitted changes for the shell prompt.
  def self.uncommitted_changes : Changes
    buffer = IO::Memory.new

    Process.run(
      command: executable_path,
      args: %w[status --porcelain],
      output: buffer,
    )

    staged_count = 0_u32
    unstaged_count = 0_u32

    buffer.rewind.each_line do |line|
      staged_count += 1 if ('A'..'Z').covers?(line[0])
      unstaged_count += 1 if ('A'..'Z').covers?(line[1])
    end

    Changes.new staged_count: staged_count, unstaged_count: unstaged_count
  end

  @@commands : Array(String) = begin
    buffer = IO::Memory.new(capacity: 2048)

    Process.run(
      command: executable_path,
      args: %w[--list-cmds=main,nohelpers],
      output: buffer,
    )

    buffer
      .to_s
      .split("\n")
      .map(&.strip)
      .reject(&.blank?)
  end

  # An array of all builtin Git commands.
  def self.commands : Array(String)
    @@commands
  end

  # Run Git with the given arguments.
  def self.run(args : Array(String), output : IO = STDOUT, error : IO = STDERR) : Process::Status
    Process.run(
      command: executable_path,
      args: args,
      output: output,
      error: error,
      input: :inherit,
    )
  end
end
