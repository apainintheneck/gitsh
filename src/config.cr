require "file_utils"
require "ini"
require "xdg"

module Config
  DIRECTORY = XDG::CONFIG::HOME / "gitsh"
  FILE_PATH = DIRECTORY / "gitsh_config.ini"
  SECTIONS  = Set{"aliases", "history"}

  module Default
    CONFIG       = {{read_file("#{__DIR__}/default_config.ini")}}
    HISTORY_SIZE = 5_000_u32
  end

  def self.write_default
    FileUtils.mkdir_p(DIRECTORY)
    File.write(FILE_PATH, Default::CONFIG)
    nil
  end

  @@config_hash : Hash(String, Hash(String, String))?

  def self.config_hash : Hash(String, Hash(String, String))
    @@config_hash ||= begin
      write_default unless File.exists?(FILE_PATH)

      begin
        content = File.read(FILE_PATH)
        INI.parse(content)
      rescue
        INI.parse(Default::CONFIG)
      end
    end
  end

  @@aliases : Hash(String, String)?

  def self.aliases : Hash(String, String)
    @@aliases ||= begin
      config_hash
        .fetch("aliases") { {} of String => String }
        .transform_keys { |key| key.starts_with?(":") ? key : ":#{key}" }
    end
  end

  def self.history_size : UInt32
    @@history_size ||= begin
      size_string = config_hash.dig? "history", "size"
      size_string.try &.to_u32? || Default::HISTORY_SIZE
    end
  end

  def self.clear
    @@aliases = nil
    @@config_hash = nil
    @@history_size = nil
  end
end
