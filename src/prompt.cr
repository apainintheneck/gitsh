require "./git"

module Prompt
  @@default : String?

  def self.string : String
    if Git.repo?
      build(
        branch: Git.current_branch,
        changes: Git.uncommitted_changes,
      )
    else
      @@default ||= build
    end
  end

  private def self.build(branch : String? = nil, changes : Git::Changes? = nil) : String
    String.build do |str|
      str << "gitsh".colorize(:light_cyan).mode(:bold)

      if branch
        str << "(" << branch.colorize(:magenta).mode(:bold)

        if changes
          str << "|"

          if changes.unstaged_count.zero? && changes.staged_count.zero?
            str << "✔".colorize(:green).mode(:bold)
          end

          if changes.staged_count.positive?
            Colorize.with.yellow.surround(str) do
              str << "●" << changes.staged_count
            end
          end

          if changes.unstaged_count.positive?
            Colorize.with.blue.surround(str) do
              str << "+" << changes.unstaged_count
            end
          end
        end

        str << ")"
      end

      str << "> "
    end
  end
end
