require "./command"
require "./executor"
require "./git"
require "./prompt"
require "linenoise"
require "process"

module REPL
  def self.run!
    Linenoise.set_multiline(true)

    # Set up shell history.
    Linenoise.load_history(History::FILE.to_s)
    Linenoise.max_history(500)

    # Set up shell completions.
    Linenoise::Completion.add(Git.commands + %w[exit quit])
    Linenoise::Completion.enable_hints!
    Linenoise::Completion.prefer_shorter_matches!

    puts "# Welcome to gitsh!"

    exit_code = 0

    # Run the shell REPL in a loop.
    loop do
      line = Linenoise.prompt(Prompt.string(exit_code)).try(&.strip)
      break if line.nil?
      next if line.blank?

      result = Executor.execute_line(line)

      case result.type
      in .success?
        # Save the current input line to the shell history.
        Linenoise.add_history(line)
        Linenoise.save_history(History::FILE.to_s)
      in .failure?
        # Don't save lines with syntax or parsing errors to the shell history.
        nil
      in .exit?
        # The user entered 'exit' or 'quit'.
        return
      end

      exit_code = result.exit_code
    end
  end
end
