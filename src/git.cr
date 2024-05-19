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

  # Run a git command and return stdout as a string.
  # Stderr and all exit codes are ignored.
  def self.command_to_string(args : Array(String)) : String
    buffer = IO::Memory.new

    Process.run(
      command: executable_path,
      args: args,
      output: buffer,
    )

    buffer.to_s
  end

  # Whether or not we are currently in a git repo.
  def self.repo? : Bool
    "true" == command_to_string(%w[rev-parse --is-inside-work-tree]).strip
  end

  # The name of the current branch or nil if there isn't one.
  def self.current_branch : String?
    branch = command_to_string(%w[rev-parse --abbrev-ref HEAD]).strip
    branch unless branch.empty?
  end

  # The name of the previous branch or nil if there isn't one.
  def self.previous_branch : String?
    branch = command_to_string(%w[rev-parse --abbrev-ref @{-1}]).strip
    branch unless branch.empty?
  end

  # The name of the main branch if it is not ambiguous.
  def self.main_branch : String?
    branches = command_to_string(%w[branch -l main master --format='%(refname:short)']).strip.lines
    branches.first if branches.size == 1
  end

  record Changes, staged_count : UInt32, unstaged_count : UInt32

  # Get the counts of uncommitted changes for the shell prompt.
  def self.uncommitted_changes : Changes
    staged_count = 0_u32
    unstaged_count = 0_u32

    command_to_string(%w[status --porcelain]).each_line do |line|
      staged_count += 1 if ('A'..'Z').covers?(line[0])
      unstaged_count += 1 if ('A'..'Z').covers?(line[1])
    end

    Changes.new staged_count: staged_count, unstaged_count: unstaged_count
  end

  @@commands : Array(String) = begin
    command_to_string(%w[--list-cmds=main,nohelpers])
      .strip
      .lines
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
