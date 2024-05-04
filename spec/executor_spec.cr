require "./spec_helper"
require "../src/executor"

describe Executor do
  describe ".execute_line" do
    # SUCCESS
    context "with a single command" do
      it "executes a command with the git prefix" do
        out_buffer = IO::Memory.new
        err_buffer = IO::Memory.new

        Executor.execute_line(line: "git help", output: out_buffer, error: err_buffer).should eq(
          Executor::Result.new(Executor::Result::Type::Success, 0)
        )

        out_buffer.to_s.should start_with("usage: git")
        err_buffer.to_s.should be_empty
      end

      it "executes a command without the git prefix" do
        out_buffer = IO::Memory.new
        err_buffer = IO::Memory.new

        Executor.execute_line(line: "help", output: out_buffer, error: err_buffer).should eq(
          Executor::Result.new(Executor::Result::Type::Success, 0)
        )

        out_buffer.to_s.should start_with("usage: git")
        err_buffer.to_s.should be_empty
      end

      it "executes an unknown command and returns a non-zero exit code" do
        out_buffer = IO::Memory.new
        err_buffer = IO::Memory.new

        Executor.execute_line(line: "unknown command", output: out_buffer, error: err_buffer).should eq(
          Executor::Result.new(Executor::Result::Type::Success, 1)
        )

        out_buffer.to_s.should be_empty
        err_buffer.to_s.should eq("git: 'unknown' is not a git command. See 'git --help'.\n")
      end
    end

    context "with two commands" do
      context "with '&&'" do
        it "executes the second command when the first succeeds" do
          out_buffer = IO::Memory.new
          err_buffer = IO::Memory.new

          Executor.execute_line(line: "help && unknown command", output: out_buffer, error: err_buffer).should eq(
            Executor::Result.new(Executor::Result::Type::Success, 1)
          )

          out_buffer.to_s.should start_with("usage: git")
          err_buffer.to_s.should eq("git: 'unknown' is not a git command. See 'git --help'.\n")
        end

        it "skips the second command when the first fails" do
          out_buffer = IO::Memory.new
          err_buffer = IO::Memory.new

          Executor.execute_line(line: "unknown command && help", output: out_buffer, error: err_buffer).should eq(
            Executor::Result.new(Executor::Result::Type::Success, 1)
          )

          out_buffer.to_s.should be_empty
          err_buffer.to_s.should eq("git: 'unknown' is not a git command. See 'git --help'.\n")
        end
      end

      context "with '||'" do
        it "skips the second command when the first succeeds" do
          out_buffer = IO::Memory.new
          err_buffer = IO::Memory.new

          Executor.execute_line(line: "help || unknown command", output: out_buffer, error: err_buffer).should eq(
            Executor::Result.new(Executor::Result::Type::Success, 0)
          )

          out_buffer.to_s.should start_with("usage: git")
          err_buffer.to_s.should be_empty
        end

        it "executes the second command when the first fails" do
          out_buffer = IO::Memory.new
          err_buffer = IO::Memory.new

          Executor.execute_line(line: "unknown command || help", output: out_buffer, error: err_buffer).should eq(
            Executor::Result.new(Executor::Result::Type::Success, 0)
          )

          out_buffer.to_s.should start_with("usage: git")
          err_buffer.to_s.should eq("git: 'unknown' is not a git command. See 'git --help'.\n")
        end
      end

      context "with semicolon" do
        it "executes the second command when the first succeeds" do
          out_buffer = IO::Memory.new
          err_buffer = IO::Memory.new

          Executor.execute_line(line: "help; unknown command", output: out_buffer, error: err_buffer).should eq(
            Executor::Result.new(Executor::Result::Type::Success, 1)
          )

          out_buffer.to_s.should start_with("usage: git")
          err_buffer.to_s.should eq("git: 'unknown' is not a git command. See 'git --help'.\n")
        end

        it "executes the second command when the first fails" do
          out_buffer = IO::Memory.new
          err_buffer = IO::Memory.new

          Executor.execute_line(line: "unknown command; help", output: out_buffer, error: err_buffer).should eq(
            Executor::Result.new(Executor::Result::Type::Success, 0)
          )

          out_buffer.to_s.should start_with("usage: git")
          err_buffer.to_s.should eq("git: 'unknown' is not a git command. See 'git --help'.\n")
        end
      end
    end

    context "with chained commands" do
      it "when it succeeds it skips everything after || until ;" do
        out_buffer = IO::Memory.new
        err_buffer = IO::Memory.new
        line = "help || help || help && help; unknown command"

        Executor.execute_line(line: line, output: out_buffer, error: err_buffer).should eq(
          Executor::Result.new(Executor::Result::Type::Success, 1)
        )

        out_buffer.to_s.scan(/usage: git/).size.should eq(1)
        err_buffer.to_s.should eq("git: 'unknown' is not a git command. See 'git --help'.\n")
      end

      it "when it fails it skips everything after && until ||" do
        out_buffer = IO::Memory.new
        err_buffer = IO::Memory.new
        line = "unknown command && help && help || version && help; version"

        Executor.execute_line(line: line, output: out_buffer, error: err_buffer).should eq(
          Executor::Result.new(Executor::Result::Type::Success, 0)
        )

        out_buffer.to_s.scan(/usage: git/).size.should eq(1)
        out_buffer.to_s.scan(/git version/).size.should eq(2)
        err_buffer.to_s.should eq("git: 'unknown' is not a git command. See 'git --help'.\n")
      end

      it "when it fails it skips everything after && until ;" do
        out_buffer = IO::Memory.new
        err_buffer = IO::Memory.new
        line = "unknown command && version && version && version; version"

        Executor.execute_line(line: line, output: out_buffer, error: err_buffer).should eq(
          Executor::Result.new(Executor::Result::Type::Success, 0)
        )

        out_buffer.to_s.scan(/git version/).size.should eq(1)
        err_buffer.to_s.should eq("git: 'unknown' is not a git command. See 'git --help'.\n")
      end
    end

    # EXIT
    it "exits successfully" do
      %w[exit quit].each do |command|
        out_buffer = IO::Memory.new
        err_buffer = IO::Memory.new

        Executor.execute_line(line: command, output: out_buffer, error: err_buffer).should eq(
          Executor::Result.new(Executor::Result::Type::Exit, 0)
        )

        out_buffer.to_s.should eq("Have a nice day!\n")
        err_buffer.to_s.should be_empty
      end
    end

    # FAILURE
    it "fails when there is a tokenizer error" do
      out_buffer = IO::Memory.new
      err_buffer = IO::Memory.new

      Executor.execute_line(line: "first second 'third fourth", output: out_buffer, error: err_buffer).should eq(
        Executor::Result.new(Executor::Result::Type::Failure, 127)
      )

      out_buffer.to_s.should be_empty
      err_buffer.to_s.should end_with("Missing matching single-quote to close string\n")
    end

    it "fails when there is a parser error" do
      out_buffer = IO::Memory.new
      err_buffer = IO::Memory.new

      Executor.execute_line(line: "first && && fourth", output: out_buffer, error: err_buffer).should eq(
        Executor::Result.new(Executor::Result::Type::Failure, 127)
      )

      out_buffer.to_s.should be_empty
      err_buffer.to_s.should end_with("Expected a string after '&&' but got '&&' instead\n")
    end
  end
end
