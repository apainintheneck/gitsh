require "./git"
require "./parser"

module Executor
  record Result, type : Result::Type, exit_code : Int32 do
    enum Type
      Success # No major problems running commands.
      Failure # Syntax or parsing errors before running commands.
      Exit    # The user has decided to close the program.
    end
  end

  def self.execute_line(line : String, output : IO = STDOUT, error : IO = STDERR) : Result
    exit_code = 0
    skip_to_end = false

    Parser.parse(line).each do |command|
      case command.action
      in .and?
        next if skip_to_end
        next unless exit_code.zero?
      in .or?
        skip_to_end = true if exit_code.zero?
        next if skip_to_end
      in .end?
        skip_to_end = false
      end

      case command.arguments.first
      when "git"
        command.arguments.shift
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
