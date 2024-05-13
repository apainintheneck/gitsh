require "option_parser"
require "./config"
require "./history"
require "./repl"
require "./validator"

OptionParser.parse do |parser|
  parser.banner = <<-BANNER
  gitsh -- a simple shell for git

  This shell includes completions and history.
  Run any `git` command without prefixing `git`
  and just `exit` when you're done.

  Options:
  BANNER

  parser.on("--diagnostic-check", "Validate the environment, config and history") do
    exit Validator.diagnostic_check? ? 0 : 1
  end

  parser.on("--reset-config", "Reset the config file to its default state") do
    Config.write_default
    exit
  end

  parser.on("--config-path", "Path to the config file") do
    puts Config::FILE_PATH
    exit
  end

  parser.on("--history-path", "Path to the history file") do
    puts History::FILE_PATH
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
    abort <<-ERROR
      Error: #{flag} is not a valid option.

      #{parser}
      ERROR
  end
end

REPL.run!
