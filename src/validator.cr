require "./config"
require "./git"
require "./history"
require "./parser"

class Validator
  # Instance
  def initialize(&validation : -> Nil | String | Array(String))
    @validation = validation
  end

  def offenses : Array(String)
    result = begin
      @validation.call
    rescue ex
      "Validation error: #{ex.message}"
    end

    case result
    in Nil
      [] of String
    in String
      [result]
    in Array(String)
      result
    end
  end

  def valid? : Bool
    offenses.empty?
  end

  # Class
  @@validations = {} of String => Validator

  def self.all_valid? : Bool
    @@validations.all? do |_name, validator|
      validator.valid?
    end
  end

  def self.diagnostic_check?(output : IO = STDOUT) : Bool
    is_valid = true

    @@validations.to_a.sort_by(&.first).each do |name, validator|
      if (offenses = validator.offenses).empty?
        output.puts "[#{name}] ✔"
      else
        output.puts "[#{name}] ✘"
        offenses.each do |offense|
          output.puts "- #{offense}"
        end
        is_valid = false
      end
    end

    is_valid
  end

  private def self.add_validation(name : String, &validation : -> Nil | String | Array(String))
    raise ArgumentError.new("Duplicate validation name: #{name}") if @@validations.includes?(name)

    @@validations[name] = new(&validation)
  end

  add_validation "Config Sections" do
    next unless File.exists?(Config::FILE_PATH)

    Config.config_hash.keys.sort.compact_map do |section|
      next if Config::SECTIONS.includes?(section)

      "Unexpected section '#{section}' found in the config file"
    end
  end

  add_validation "Config File" do
    next unless File.exists?(Config::FILE_PATH)

    begin
      contents = File.read(Config::FILE_PATH)
      INI.parse(contents)
      nil
    rescue
      "Invalid config file: #{Config::FILE_PATH}"
    end
  end

  add_validation "History File" do
    next unless File.exists?(History::FILE_PATH)

    begin
      File.read(History::FILE_PATH)
      nil
    rescue
      "Invalid history file: #{History::FILE_PATH}"
    end
  end

  add_validation "History Size" do
    next unless File.exists?(Config::FILE_PATH)

    history_hash = Config.config_hash["history"]?
    next unless history_hash
    next unless history_hash.has_key?("size")

    raw_size = history_hash["size"]?
    size = raw_size.try &.to_u32?
    next if size.is_a?(UInt32)

    "Invalid history size: #{raw_size.inspect}"
  end

  add_validation "History Section" do
    next unless File.exists?(Config::FILE_PATH)

    history_hash = Config.config_hash["history"]?
    next unless history_hash

    history_hash.keys.compact_map do |key|
      next if key == "size"

      "Unexpected history section key in the config file: '#{key}'"
    end
  end

  add_validation "Aliases" do
    next unless File.exists?(Config::FILE_PATH)

    Config.aliases.compact_map do |name, line|
      Parser.parse(line)
      nil
    rescue
      "Invalid alias: '#{name}' = '#{line}'"
    end
  end
end
