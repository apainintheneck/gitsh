# frozen_string_literal: true

require_relative "gitsh/version"
require "reline"
require "xdg"

module Gitsh
  class Error < StandardError; end

  # When the error is caught at the tokenizer level.
  class SyntaxError < Error; end

  # When the error is caught at the parser level.
  class ParseError < Error; end

  # Used to indicate that the user wants to exit the program.
  class ExitError < Error; end

  # When a line of code should never be reached in normal execution.
  class UnreachableError < Error; end

  # Send messages from option blocks to the commander.
  class MessageError < Error; end

  autoload :Commander, "gitsh/commander"
  autoload :Completer, "gitsh/completer"
  autoload :Executor, "gitsh/executor"
  autoload :Git, "gitsh/git"
  autoload :GitHelp, "gitsh/git_help"
  autoload :Highlighter, "gitsh/highlighter"
  autoload :Hinter, "gitsh/hinter"
  autoload :Parser, "gitsh/parser"
  autoload :Prompt, "gitsh/prompt"
  autoload :Stringer, "gitsh/stringer"
  autoload :Token, "gitsh/token"
  autoload :TokenZipper, "gitsh/token_zipper"
  autoload :Tokenizer, "gitsh/tokenizer"

  HISTORY_FILE_PATH = (XDG::Data.new.home / "gitsh/history").freeze
  USE_COLOR = ENV["NO_COLOR"].then { _1.nil? || _1.empty? }

  # Sets up shell history, completions, syntax highlighting and starts the REPL.
  def self.run!
    # Set up shell history.
    original_history = Reline::HISTORY.to_a
    if HISTORY_FILE_PATH.exist?
      Reline::HISTORY.replace(HISTORY_FILE_PATH.read.lines(chomp: true))
    else
      HISTORY_FILE_PATH.dirname.mkpath
      Reline::HISTORY.clear
    end

    # Set up shell completions.
    Reline.autocompletion = true
    Reline.completion_proc = Completer::CALLBACK

    # Set up shell hints.
    Reline.add_dialog_proc(:hint, Hinter.callback, Reline::DEFAULT_DIALOG_CONTEXT)

    # Set up syntax highlighting.
    Reline.output_modifier_proc = Highlighter::CALLBACK if USE_COLOR

    puts "# Welcome to gitsh!"

    exit_code = 0

    # Run the shell REPL in a loop.
    loop do
      prompt = Prompt.string(exit_code: exit_code)
      line = Reline.readline(prompt)&.strip
      raise ExitError if line.nil? # for ctrl-d
      next if line.empty?

      result = Executor.execute_line(line: line)

      case result
      when Gitsh::Executor::Result::Success
        # Save the current input line to the shell history.
        if Reline::HISTORY.last != line
          Reline::HISTORY.push(line)
          HISTORY_FILE_PATH.write("#{line}\n", mode: "a")
        end
      when Gitsh::Executor::Result::Failure
        # Only save the lines with syntax or parsing errors to the session history.
        if Reline::HISTORY.last != line
          Reline::HISTORY.push(line)
        end
      end

      exit_code = result.exit_code
    # Exit based on "exit", "quit", ctrl-d or ctrl-c.
    rescue ExitError, Interrupt
      puts "Have a nice day!"
      break
    end
  ensure
    # Note: This is only useful when testing in IRB.
    Reline::HISTORY.replace(original_history)
  end

  # @return [Array<String>]
  def self.all_command_names
    @all_command_names ||= (Git.command_names + Commander.internal_command_names).freeze
  end
end
