require "file_utils"
require "xdg"

module History
  DIRECTORY = XDG::DATA::HOME / "gitsh"
  FILE      = DIRECTORY / "gitsh_history"

  def self.init
    return if File.exists?(FILE)

    FileUtils.mkdir_p(DIRECTORY)
    FileUtils.touch(FILE)
  end
end
