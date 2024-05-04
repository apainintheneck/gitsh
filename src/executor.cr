require "./git"
require "./parser"

# Executes a series of commands based on their associated actions.
# See `Command` for more information.
module Executor
  record Result, type : Result::Type, exit_code : Int32 do
    enum Type
      Success # No major problems running commands.
      Failure # Syntax or parsing errors before running commands.
      Exit    # The user has decided to close the program.
    end
  end

  # Run a series of commands based on their actions and return the result of the last command.
  def self.execute_line(line : String, output : IO = STDOUT, error : IO = STDERR) : Result
    exit_code = 0

    # We skip to the next `end` action when a successful command is followed by the `or` action.
    # For example: `first || second || third && fourth; fifth`
    #
    # In this case, only the `first` and `fifth` commands would get run.
    # The rest of the commands would get skipped.
    skip_to_end = false

    Parser.parse(line).each do |command|
      case command.action
      in .and?
        next if skip_to_end
        # Skip the command if the previous one failed.
        next unless exit_code.zero?
      in .or?
        # Skip to the end if the previous command succeeded.
        skip_to_end = true if exit_code.zero?
        next if skip_to_end
      in .end?
        # Always run the command after the `end` action.
        skip_to_end = false
      end

      case command.arguments.first
      when "git"
        command.arguments.shift # ignore unnecessary 'git' prefix
      when "exit", "quit"
        output.puts "Have a nice day!"
        return Result.new type: Result::Type::Exit, exit_code: 0
      end

      exit_code = Git.run(
        args: command.arguments,
        output: output,
        error: error,
      ).exit_code
    end

    return Result.new type: Result::Type::Success, exit_code: exit_code
  rescue ex : Parser::Exception | Tokenizer::SyntaxException
    error.puts ex.message
    return Result.new type: Result::Type::Failure, exit_code: 127
  end
end
