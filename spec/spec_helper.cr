require "spec"
require "file_utils"
require "process"

module Test
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
      Test.quiet_system("git init")
      block.call
    end
  end
end
