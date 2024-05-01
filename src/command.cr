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
