# frozen_string_literal: true

RSpec.describe Gitsh::Git do
  describe ".installed?" do
    it "returns true when git exists" do
      expect(described_class.installed?).to be(true)
    end
  end

  describe ".repo?" do
    it "returns true when in a repo" do
      expect(described_class.repo?).to be(true)
    end
  end

  describe ".current_branch" do
    it "returns a branch name" do
      expect(described_class.current_branch).to be_a(String)
    end
  end

  describe ".uncommitted_changes" do
    it "returns a Changes struct" do
      expect(described_class.uncommitted_changes).to be_a(described_class::Changes)
    end
  end

  describe ".commands" do
    it "returns a list of Git commands" do
      expect(described_class.commands).to include(
        "commit", "push", "pull", "status", "diff", "grep", "log"
      )
    end
  end

  describe ".run" do
    it "succeeds with a valid command" do
      status = described_class.run(["help"], out: File::NULL, err: File::NULL)
      expect(status).to be_a(Process::Status)
      expect(status.exitstatus).to eq(0)
    end

    it "fails with an invalid command" do
      status = described_class.run(["not-a-command"], out: File::NULL, err: File::NULL)
      expect(status).to be_a(Process::Status)
      expect(status.exitstatus).to eq(1)
    end
  end
end
