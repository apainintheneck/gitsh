require "./spec_helper"
require "../src/config"

describe Config do
  after_each do
    Config.clear
    File.delete?(Config::FILE_PATH)
    Dir.delete?(Config::DIRECTORY)
  end

  it "generates a config file when it doesn't exist yet" do
    File.exists?(Config::FILE_PATH).should be_false

    Config.config_hash

    File.exists?(Config::FILE_PATH).should be_true
  end

  it "reads expected values from the config file" do
    FileUtils.mkdir_p(Config::DIRECTORY)
    File.write(Config::FILE_PATH, <<-INI)
    [aliases]
    current_branch = branch --show-current

    [commands]
    amend = commit --amend

    [history]
    size = 300
    INI

    Config.aliases.should eq({"current_branch" => "branch --show-current"})
    Config.commands.should eq({"amend" => "commit --amend"})
    Config.history_size.should eq(300)
  end

  it "provides default values when the config file is invalid" do
    FileUtils.mkdir_p(Config::DIRECTORY)
    File.write(Config::FILE_PATH, <<-INI)
    Nothing... remember the old nothing... it was so peaceful!
    INI

    Config.aliases.should be_a(Hash(String, String))
    Config.commands.should be_a(Hash(String, String))
    Config.history_size.should eq(5_000)
  end
end
