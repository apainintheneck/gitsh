require "spec"
require "file_utils"
require "process"

# Copied from `Library/Homebrew/dev-cmd/tests.rb`.
# This prevents git repo set up errors.
%w[AUTHOR COMMITTER].each do |role|
  ENV["GIT_#{role}_NAME"] = "gitsh tests"
  ENV["GIT_#{role}_EMAIL"] = "gitsh-tests@localhost"
  ENV["GIT_#{role}_DATE"] = "Sun Jan 22 19:59:13 2017 +0000"
end

module TestShell
  # Runs a system command without printing to stdout or stderr.
  def self.quiet_system(command)
    Process.run(
      command: command,
      shell: true,
    )
  end
end

module TestDir
  private def self.in_temp_directory(&block)
    old_dir = Dir.current
    tmp_dir = File.tempname

    begin
      Dir.mkdir tmp_dir
      Dir.cd tmp_dir
      block.call
    ensure
      Dir.cd old_dir
      FileUtils.rm_rf tmp_dir
    end
  end

  # Creates a temporary directory without a git repo.
  # The given block is then run in this directory.
  def self.without_git_repo(&block)
    in_temp_directory(&block)
  end

  # Creates a temporary directory and initializes a git repo in it.
  # The given block is then run in this directory.
  def self.with_git_repo(&block)
    in_temp_directory do
      TestShell.quiet_system("git init")
      # Add a commit to be able to set the branch name.
      FileUtils.touch ".keep"
      TestShell.quiet_system("git add .keep && git commit -m 'init'")
      TestShell.quiet_system("git branch -m main")

      block.call
    end
  end
end
