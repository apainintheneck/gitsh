require "./git"
require "./prompt"
require "linenoise"
require "process"

HISTORY_FILE = File.expand_path("~/.gitsh_history", home: true)
Linenoise.load_history(HISTORY_FILE)
Linenoise.max_history(500)

Linenoise::Completion.add(Git.commands + %w[exit quit])
Linenoise::Completion.enable_hints!
Linenoise::Completion.prefer_shorter_matches!

puts "# Welcome to gitsh!"

loop do
  line = Linenoise.prompt(Prompt.string).try(&.strip)
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

  Git.run(args)

  Linenoise.add_history(line)
  Linenoise.save_history(HISTORY_FILE)
end
