require "file_utils"
require "xdg"

module History
  DIRECTORY = XDG::DATA::HOME / "gitsh"
  FILE_PATH = DIRECTORY / "gitsh_history"

  def self.init!
    return if File.exists?(FILE_PATH)

    FileUtils.mkdir_p(DIRECTORY)
    FileUtils.touch(FILE_PATH)
  end
end
