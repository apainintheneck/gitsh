require "file_utils"
require "ini"
require "xdg"

module Config
  DIRECTORY = XDG::CONFIG::HOME / "gitsh"
  FILE_PATH = DIRECTORY / "gitsh_config.ini"
  SECTIONS  = Set{"aliases", "commands", "history"}

  module Default
    CONFIG       = {{read_file("#{__DIR__}/default_config.ini")}}
    HISTORY_SIZE = 5_000_u32
  end

  def self.clear!
    @@config_hash = nil
    @@aliases = nil
    @@commands = nil
    @@history_size = nil
  end

  def self.write_default!
    FileUtils.mkdir_p(DIRECTORY)
    File.write(FILE_PATH, Default::CONFIG)
    nil
  end

  def self.load_file(file_path : Path)
    write_default! unless File.exists?(file_path)

    File.open(file_path) do |file|
      INI.parse(file)
    rescue
      INI.parse(Default::CONFIG)
    end
  end

  # Load a new config file in place and reset all of the
  # associated values parsed from the old config file.
  # Needed for testing.
  def self.load_file!(file_path : Path)
    clear!
    @@config_hash = load_file(file_path)
    nil
  end

  class_getter config_hash : Hash(String, Hash(String, String)) do
    load_file(FILE_PATH)
  end

  class_getter aliases : Hash(String, String) do
    config_hash.fetch("aliases") do
      {} of String => String
    end
  end

  class_getter commands : Hash(String, String) do
    config_hash.fetch("commands") do
      {} of String => String
    end
  end

  class_getter history_size : UInt32 do
    size_string = config_hash.dig? "history", "size"
    size_string.try &.to_u32? || Default::HISTORY_SIZE
  end
end
