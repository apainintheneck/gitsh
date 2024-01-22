require "./git"
require "linenoise"
require "process"

Linenoise::Completion.add(Git.commands + %w[exit quit])
Linenoise::Completion.enable_hints!

puts <<-WELCOME
# Welcome to gitsh!
# This is a simple wrapper around Git that acts like a shell.
#
# Type any Git subcommand to run it without prefixing 'git'.
# Type 'sh' before running any normal shell commands.
# Type 'exit' or 'quit' to leave this shell.
#############################################################
WELCOME

loop do
  line = Linenoise.prompt("gitsh> ").try(&.strip)
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
end
