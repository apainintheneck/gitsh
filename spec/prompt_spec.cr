require "./spec_helper"
require "../src/prompt.cr"

GITSH     = "gitsh".colorize(:light_cyan).mode(:bold)
BRANCH    = "main".colorize(:magenta).mode(:bold)
CHECK     = "✔".colorize(:green).mode(:bold)
STAGED    = "●2".colorize(:yellow)
UNSTAGED  = "+1".colorize(:blue)
SUCCESS   =   0
FAILURE   = 127
EXIT_CODE = "[127]".colorize(:red)

describe Prompt do
  describe ".string" do
    context "with zero exit code" do
      context "with git repo" do
        around_each do |example|
          TestDir.with_git_repo { example.run }
        end

        context "with no changes" do
          it "returns expected prompt" do
            Prompt.string(SUCCESS).should eq "#{GITSH}(#{BRANCH}|#{CHECK})> "
          end
        end

        context "with 2 staged changes" do
          it "returns expected prompt" do
            # Two staged file changes
            FileUtils.touch "file1"
            FileUtils.touch "file2"
            TestShell.quiet_system("git add file1 file2")

            Prompt.string(SUCCESS).should eq "#{GITSH}(#{BRANCH}|#{STAGED})> "
          end
        end

        context "with 1 unstaged change" do
          it "returns expected prompt" do
            # Commit one file
            FileUtils.touch "file1"
            TestShell.quiet_system("git add file1")
            TestShell.quiet_system("git commit -m 'first'")
            # One unstaged file change
            File.write "file1", "text"

            Prompt.string(SUCCESS).should eq "#{GITSH}(#{BRANCH}|#{UNSTAGED})> "
          end
        end

        context "with 2 staged changes and 1 unstaged change" do
          it "returns expected prompt" do
            # Two staged file changes
            FileUtils.touch "file1"
            FileUtils.touch "file2"
            TestShell.quiet_system("git add file1 file2")
            # One unstaged file change
            File.write "file1", "text"

            Prompt.string(SUCCESS).should eq "#{GITSH}(#{BRANCH}|#{STAGED}#{UNSTAGED})> "
          end
        end
      end

      context "without git repo" do
        around_each do |example|
          TestDir.without_git_repo { example.run }
        end

        it "returns default prompt string" do
          Prompt.string(SUCCESS).should eq "#{GITSH}> "
        end
      end
    end

    context "with non-zero exit code" do
      context "with git repo" do
        around_each do |example|
          TestDir.with_git_repo { example.run }
        end

        context "with no changes" do
          it "returns expected prompt" do
            Prompt.string(FAILURE).should eq "#{GITSH}(#{BRANCH}|#{CHECK})#{EXIT_CODE}> "
          end
        end

        context "with 2 staged changes" do
          it "returns expected prompt" do
            # Two staged file changes
            FileUtils.touch "file1"
            FileUtils.touch "file2"
            TestShell.quiet_system("git add file1 file2")

            Prompt.string(FAILURE).should eq "#{GITSH}(#{BRANCH}|#{STAGED})#{EXIT_CODE}> "
          end
        end

        context "with 1 unstaged change" do
          it "returns expected prompt" do
            # Commit one file
            FileUtils.touch "file1"
            TestShell.quiet_system("git add file1")
            TestShell.quiet_system("git commit -m 'first'")
            # One unstaged file change
            File.write "file1", "text"

            Prompt.string(FAILURE).should eq "#{GITSH}(#{BRANCH}|#{UNSTAGED})#{EXIT_CODE}> "
          end
        end

        context "with 2 staged changes and 1 unstaged change" do
          it "returns expected prompt" do
            # Two staged file changes
            FileUtils.touch "file1"
            FileUtils.touch "file2"
            TestShell.quiet_system("git add file1 file2")
            # One unstaged file change
            File.write "file1", "text"

            Prompt.string(FAILURE).should eq "#{GITSH}(#{BRANCH}|#{STAGED}#{UNSTAGED})#{EXIT_CODE}> "
          end
        end
      end

      context "without git repo" do
        around_each do |example|
          TestDir.without_git_repo { example.run }
        end

        it "returns default prompt string" do
          Prompt.string(FAILURE).should eq "#{GITSH}#{EXIT_CODE}> "
        end
      end
    end
  end
end
