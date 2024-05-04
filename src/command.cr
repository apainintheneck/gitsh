# Represents a single shell command and action pair.
# - Action: The logical action between the previous command and this one.
# - Command: The shell command to run as an array of strings.
#
# There are three possible actions:
# 1. '&&' - Requires the previous command to exit successfully.
# 2. '||' - Requires the previous command to fail.
# 3. ';'  - Runs no matter what happened with the previous command.
class Command
  def_equals @action, @arguments # for testing

  enum Action
    And # Run this command if the previous one succeeded.
    Or  # Run this command if the previous one failed.
    End # Run this command regardless of the previous command.
  end

  getter action : Action
  property arguments : Array(String)

  def initialize(@action, @arguments = [] of String)
  end
end
