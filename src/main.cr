require "option_parser"
require "./repl"

OptionParser.parse do |parser|
  parser.banner = <<-BANNER
  gitsh -- a simple shell for git

  This shell includes completions and history.
  Run any `git` command without prefixing `git`
  and just `exit` when you're done.

  Options:
  BANNER

  # TODO: Add the following commands
  # --check-config : Validate the config file commands
  # --config-path  : Path to the config file
  # --reset-config : Reset the config file to its default state

  parser.on("--history-path", "Path to the history file") do
    puts REPL::HISTORY_FILE
    exit
  end

  parser.on("-h", "--help", "Show this help page") do
    puts parser
    exit
  end

  parser.invalid_option do |flag|
    STDERR.puts "ERROR: #{flag} is not a valid option."
    STDERR.puts
    STDERR.puts parser
    exit(1)
  end
end

REPL.run!
