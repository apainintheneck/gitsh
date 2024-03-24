require "./git"

module Prompt
  @@default : String?

  def self.string : String
    if Git.repo?
      changes = Git.uncommitted_changes
      build(
        branch: Git.current_branch,
        unstaged_changes: changes[:unstaged_count],
        staged_changes: changes[:staged_count],
      )
    else
      @@default ||= build
    end
  end

  private def self.build(branch : String? = nil, unstaged_changes : UInt32 = 0, staged_changes : UInt32 = 0) : String
    String.build do |str|
      str << "gitsh".colorize(:light_cyan).mode(:bold)
      if branch
        str << "(" << branch.colorize(:magenta).mode(:bold) << "|"

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
end
