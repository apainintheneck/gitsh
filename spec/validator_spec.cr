require "./spec_helper"
require "../src/validator"

describe Validator do
  describe "with default settings" do
    describe "with history and config files" do
      it "is valid" do
        History.init!
        Config.config_hash # calls `Config.write_default!` internally

        Validator.all_valid?.should be_true
        File.exists?(History::FILE_PATH).should be_true
        File.exists?(Config::FILE_PATH).should be_true
      ensure # Cleanup
        File.delete(History::FILE_PATH) if File.exists?(History::FILE_PATH)
        File.delete(Config::FILE_PATH) if File.exists?(Config::FILE_PATH)
        Config.clear!
      end
    end

    describe "without history and config files" do
      it "is valid" do
        Validator.all_valid?.should be_true
        File.exists?(History::FILE_PATH).should be_false
        File.exists?(Config::FILE_PATH).should be_false
      ensure # Cleanup
        File.delete(History::FILE_PATH) if File.exists?(History::FILE_PATH)
        File.delete(Config::FILE_PATH) if File.exists?(Config::FILE_PATH)
        Config.clear!
      end
    end
  end
end
