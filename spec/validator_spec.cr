require "./spec_helper"
require "../src/validator"

describe Validator do
  after_each do
    Config.clear
    File.delete?(History::FILE_PATH)
    File.delete?(Config::FILE_PATH)
    Dir.delete?(History::DIRECTORY)
    Dir.delete?(Config::DIRECTORY)
  end

  describe "with default settings" do
    describe "with history and config files" do
      it "is valid" do
        History.init
        Config.config_hash

        Validator.all_valid?.should be_true
        File.exists?(History::FILE_PATH).should be_true
        File.exists?(Config::FILE_PATH).should be_true

        stdout_buffer = IO::Memory.new
        Validator.diagnostic_check?(stdout_buffer)

        stdout_buffer.to_s.should eq(<<-OUTPUT)
        [Aliases] ✔
        [Commands] ✔
        [Config File] ✔
        [Config Sections] ✔
        [History File] ✔
        [History Section] ✔
        [History Size] ✔

        OUTPUT
      end
    end

    describe "without history and config files" do
      it "is valid" do
        Validator.all_valid?.should be_true
        File.exists?(History::FILE_PATH).should be_false
        File.exists?(Config::FILE_PATH).should be_false

        stdout_buffer = IO::Memory.new
        Validator.diagnostic_check?(stdout_buffer)

        stdout_buffer.to_s.should eq(<<-OUTPUT)
        [Aliases] ✔
        [Commands] ✔
        [Config File] ✔
        [Config Sections] ✔
        [History File] ✔
        [History Section] ✔
        [History Size] ✔

        OUTPUT
      end
    end
  end

  it "fails with an invalid alias" do
    FileUtils.mkdir_p(Config::DIRECTORY)
    File.write(Config::FILE_PATH, <<-INI)
    [aliases]
    invalid = add --all && commit -m 'tmp'
    valid = help alias
    INI

    Config.config_hash
    Validator.all_valid?.should be_false

    stdout_buffer = IO::Memory.new
    Validator.diagnostic_check?(stdout_buffer)

    stdout_buffer.to_s.should eq(<<-OUTPUT)
    [Aliases] ✘
    - Invalid alias includes boolean logic: 'invalid' = 'add --all && commit -m 'tmp''
    [Commands] ✔
    [Config File] ✔
    [Config Sections] ✔
    [History File] ✔
    [History Section] ✔
    [History Size] ✔

    OUTPUT
  end

  it "fails with an invalid command" do
    FileUtils.mkdir_p(Config::DIRECTORY)
    File.write(Config::FILE_PATH, <<-INI)
    [commands]
    invalid = && add -all && commit
    valid = add -all && commit
    INI

    Config.config_hash
    Validator.all_valid?.should be_false

    stdout_buffer = IO::Memory.new
    Validator.diagnostic_check?(stdout_buffer)

    stdout_buffer.to_s.should eq(<<-OUTPUT)
    [Aliases] ✔
    [Commands] ✘
    - Invalid command: 'invalid' = '&& add -all && commit'
    [Config File] ✔
    [Config Sections] ✔
    [History File] ✔
    [History Section] ✔
    [History Size] ✔

    OUTPUT
  end

  it "fails with an unreadable config file" do
    Config.write_default
    File.chmod(Config::FILE_PATH, 0o222)

    Config.config_hash
    Validator.all_valid?.should be_false

    stdout_buffer = IO::Memory.new
    Validator.diagnostic_check?(stdout_buffer)

    stdout_buffer.to_s.should eq(<<-OUTPUT)
    [Aliases] ✔
    [Commands] ✔
    [Config File] ✘
    - Invalid config file: #{Config::FILE_PATH}
    [Config Sections] ✔
    [History File] ✔
    [History Section] ✔
    [History Size] ✔

    OUTPUT
  end

  it "fails with an unparsable config file" do
    FileUtils.mkdir_p(Config::DIRECTORY)
    File.write(Config::FILE_PATH, "INVALID INI FILE FORMAT")

    Config.config_hash
    Validator.all_valid?.should be_false

    stdout_buffer = IO::Memory.new
    Validator.diagnostic_check?(stdout_buffer)

    stdout_buffer.to_s.should eq(<<-OUTPUT)
    [Aliases] ✔
    [Commands] ✔
    [Config File] ✘
    - Invalid config file: #{Config::FILE_PATH}
    [Config Sections] ✔
    [History File] ✔
    [History Section] ✔
    [History Size] ✔

    OUTPUT
  end

  it "fails with an unexpected config section" do
    FileUtils.mkdir_p(Config::DIRECTORY)
    File.write(Config::FILE_PATH, <<-INI)
    [commands]
    valid = add -all && commit

    [invalid]
    option = value
    INI

    Config.config_hash
    Validator.all_valid?.should be_false

    stdout_buffer = IO::Memory.new
    Validator.diagnostic_check?(stdout_buffer)

    stdout_buffer.to_s.should eq(<<-OUTPUT)
    [Aliases] ✔
    [Commands] ✔
    [Config File] ✔
    [Config Sections] ✘
    - Unexpected section 'invalid' found in the config file
    [History File] ✔
    [History Section] ✔
    [History Size] ✔

    OUTPUT
  end

  it "fails with an unreadable history file" do
    History.init
    File.chmod(History::FILE_PATH, 0o222)

    Config.config_hash
    Validator.all_valid?.should be_false

    stdout_buffer = IO::Memory.new
    Validator.diagnostic_check?(stdout_buffer)

    stdout_buffer.to_s.should eq(<<-OUTPUT)
    [Aliases] ✔
    [Commands] ✔
    [Config File] ✔
    [Config Sections] ✔
    [History File] ✘
    - Invalid history file: #{History::FILE_PATH}
    [History Section] ✔
    [History Size] ✔

    OUTPUT
  end

  it "fails with an unexpected history section key" do
    FileUtils.mkdir_p(Config::DIRECTORY)
    File.write(Config::FILE_PATH, <<-INI)
    [history]
    size = 100
    duplicates = false
    INI

    Config.config_hash
    Validator.all_valid?.should be_false

    stdout_buffer = IO::Memory.new
    Validator.diagnostic_check?(stdout_buffer)

    stdout_buffer.to_s.should eq(<<-OUTPUT)
    [Aliases] ✔
    [Commands] ✔
    [Config File] ✔
    [Config Sections] ✔
    [History File] ✔
    [History Section] ✘
    - Unexpected history section key in the config file: 'duplicates'
    [History Size] ✔

    OUTPUT
  end

  it "fails with an invalid history size" do
    FileUtils.mkdir_p(Config::DIRECTORY)
    File.write(Config::FILE_PATH, <<-INI)
    [history]
    size = sldkfsd
    INI

    Config.config_hash
    Validator.all_valid?.should be_false

    stdout_buffer = IO::Memory.new
    Validator.diagnostic_check?(stdout_buffer)

    stdout_buffer.to_s.should eq(<<-OUTPUT)
    [Aliases] ✔
    [Commands] ✔
    [Config File] ✔
    [Config Sections] ✔
    [History File] ✔
    [History Section] ✔
    [History Size] ✘
    - Invalid history size: "sldkfsd"

    OUTPUT
  end
end
