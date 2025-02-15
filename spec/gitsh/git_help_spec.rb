# frozen_string_literal: true

RSpec.describe Gitsh::GitHelp do
  subject(:help_page) { described_class.for(command: "diff") }

  before do
    allow(Gitsh).to receive(:all_commands)
      .and_return(%w[diff])
    allow(Gitsh::Git).to receive(:help_page)
      .with(command: "diff")
      .and_return(fixture("git_diff_help_page.txt"))
  end

  describe ".for" do
    it "returns nil for invalid command" do
      expect(described_class.for(command: "dance")).to be_nil
    end

    it "returns instance of itself when command is valid" do
      expect(described_class.for(command: "diff")).to be_a(Gitsh::GitHelp)
    end
  end

  describe "#long_option_prefixes" do
    it "should include expected prefixes" do
      expect(help_page.long_option_prefixes.sort)
        .to match_snapshot("git_diff_long_option_prefixes")
    end
  end

  describe "#options" do
    it "should include all options" do
      expect(help_page.options).to match_snapshot("git_diff_all_options")
    end
  end
end
