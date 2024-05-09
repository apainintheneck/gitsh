require "file_utils"
require "ini"
require "xdg"

module Config
  DIRECTORY = XDG::CONFIG::HOME / "gitsh"
  FILE      = DIRECTORY / "gitsh_config.ini"
  # DEFAULT   = {{read_file("./default_config.ini")}}
  DEFAULT = ""

  def self.init
    reset unless File.exists?(FILE)
  end

  def self.reset
    FileUtils.mkdir_p(DIRECTORY)
    File.write(FILE, DEFAULT)
  end

  def self.valid?
    true # TODO
  end

  @@config_hash : Hash(String, Hash(String, String))?

  private def self.config_hash
    @@config_hash ||= begin
      init

      File.open(FILE) do |file|
        INI.parse(file)
      end
    end
  end

  {% for name in ["aliases", "commands", "history"] %}
    def self.{{name.id}}?(field : String) : String?
      config_section = config_hash[{{name.id}}]?
      return unless config_section

      config_section[field]?
    end

    def self.{{name.id}}(field : String) : String
      result = {{name.id}}?
      return result if result

      raise KeyError.new(%{Missing config key: "{{name.id}}.#{field}"})
    end
  {% end %}
end
