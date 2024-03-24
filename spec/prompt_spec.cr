require "./spec_helper"
require "../src/prompt.cr"

GITSH    = "gitsh".colorize(:light_cyan).mode(:bold)
HEAD     = "HEAD".colorize(:magenta).mode(:bold)
MASTER   = "master".colorize(:magenta).mode(:bold)
CHECK    = "✔".colorize(:green).mode(:bold)
STAGED   = "●2".colorize(:yellow)
UNSTAGED = "+1".colorize(:blue)

describe Prompt do
  describe ".string" do
    context "with git repo" do
      context "with no changes" do
        it "returns expected prompt" do
          TestDir.with_git_repo do
            Prompt.string.should eq "#{GITSH}(#{HEAD}|#{CHECK})> "
          end
        end
      end

      context "with 2 staged changes" do
        it "returns expected prompt" do
          TestDir.with_git_repo do
            # Two staged file changes
            FileUtils.touch "file1"
            FileUtils.touch "file2"
            Test.quiet_system("git add file1 file2")

            Prompt.string.should eq "#{GITSH}(#{HEAD}|#{STAGED})> "
          end
        end
      end

      context "with 1 unstaged change" do
        it "returns expected prompt" do
          TestDir.with_git_repo do
            # Commit one file
            FileUtils.touch "file1"
            Test.quiet_system("git add file1")
            system("git commit -m 'first' --author='Test <test@test.com>'")
            # One unstaged file change
            File.write "file1", "text"

            Prompt.string.should eq "#{GITSH}(#{MASTER}|#{UNSTAGED})> "
          end
        end
      end

      context "with 2 staged changes and 1 unstaged change" do
        it "returns expected prompt" do
          TestDir.with_git_repo do
            # Two staged file changes
            FileUtils.touch "file1"
            FileUtils.touch "file2"
            Test.quiet_system("git add file1 file2")
            # One unstaged file change
            File.write "file1", "text"

            Prompt.string.should eq "#{GITSH}(#{HEAD}|#{STAGED}#{UNSTAGED})> "
          end
        end
      end
    end

    context "without git repo" do
      it "returns default prompt string" do
        TestDir.without_git_repo do
          Prompt.string.should eq "#{GITSH}> "
        end
      end
    end
  end
end
