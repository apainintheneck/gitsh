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

def build_prompt(branch : String? = nil, unstaged_changes : UInt32 = 0, staged_changes : UInt32 = 0) : String
  String.build do |str|
    str << "gitsh".colorize(:light_cyan).mode(:bold)
    if branch
      str << " (" << branch.colorize(:magenta).mode(:bold) << "|"

      if unstaged_changes.zero? && staged_changes.zero?
        str << "✔".colorize(:green).mode(:bold)
      end

      if staged_changes.positive?
        Colorize.with.yellow.surround(str) do
          str << "●" << staged_changes
        end
      end

      if unstaged_changes.positive?
        Colorize.with.blue.surround(str) do
          str << "+" << unstaged_changes
        end
      end

      str << ")"
    end
    str << "> "
  end
end

DEFAULT_PROMPT = build_prompt

loop do
  if Git.repo?
    changes = Git.uncommitted_changes
    prompt_str = build_prompt(
      branch: Git.current_branch,
      unstaged_changes: changes[:unstaged_count],
      staged_changes: changes[:staged_count],
    )
  else
    prompt_str = DEFAULT_PROMPT
  end

  line = Linenoise.prompt(prompt_str).try(&.strip)
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
