require "./git"
require "./prompt"
require "linenoise"
require "process"

module REPL
  HISTORY_FILE = File.expand_path("~/.gitsh_history", home: true)

  def self.run!
    # Set up shell history.
    Linenoise.load_history(HISTORY_FILE)
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

      args = Process.parse_arguments(line)
      next if args.empty?

      case args.first
      when "git"
        puts "Warn: 'git' is added automatically before all commands"
        args.shift
      when "exit", "quit"
        puts "Have a nice day!"
        break
      end

      exit_code = Git.run(args).exit_code

      # Save the current input line to the shell history.
      Linenoise.add_history(line)
      Linenoise.save_history(HISTORY_FILE)
    end
  end
end
