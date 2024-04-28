require "./git"

module Prompt
  @@default : String?

  def self.string(exit_code : Int32 = 0) : String
    if Git.repo?
      build(
        status: exit_code,
        branch: Git.current_branch,
        changes: Git.uncommitted_changes,
      )
    else
      build(status: exit_code)
    end
  end

  private def self.build(status : Int32, branch : String? = nil, changes : Git::Changes? = nil) : String
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

      if status.positive?
        Colorize.with.red.surround(str) do
          str << "[" << status << "]"
        end
      end

      str << "> "
    end
  end
end
