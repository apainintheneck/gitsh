require "option_parser"
require "./config"
require "./history"
require "./repl"

Config.init
History.init

OptionParser.parse do |parser|
  parser.banner = <<-BANNER
  gitsh -- a simple shell for git

  This shell includes completions and history.
  Run any `git` command without prefixing `git`
  and just `exit` when you're done.

  Options:
  BANNER

  parser.on("--validate-config", "Validate the config file contents") do
    exit Config.valid? ? 0 : 1
  end

  parser.on("--reset-config", "Reset the config file to its default state") do
    Config.reset
    exit
  end

  parser.on("--config-path", "Path to the config file") do
    puts Config::FILE
    exit
  end

  parser.on("--history-path", "Path to the history file") do
    puts History::FILE
    exit
  end

  parser.on("-v", "--version", "Show the current version") do
    puts "0.2.0"
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
