require "./command"
require "./tokenizer"

module Parser
  class Exception < Exception; end

  # Parse the line of input into a series of commands.
  def self.parse(line : String) : Array(Command)
    command_list = [] of Command
    tokens = Tokenizer.tokenize(line)
    return command_list if tokens.empty?

    if tokens.first.type.string?
      command_list << Command.new(action: Command::Action::End, arguments: [tokens.first.content])
    else
      raise Exception.new(message: "#{tokens.first.location}: Expected a string to start the line but got '#{tokens.first.content}' instead")
    end

    if tokens.last.type.and? || tokens.last.type.or?
      raise Exception.new(message: "#{tokens.last.location}: Expected a string or a semicolon to end the line but got '#{tokens.last.content}' instead")
    end

    tokens.each_cons_pair do |prev_token, token|
      case {prev_token.type, token.type}
      when {_, .string?} # Token is a string.
        command_list.last.arguments << token.content
      when {.string?, _} # Token is an action.
        command_list << Command.new(action: token.type.to_action!)
      else
        raise Exception.new(message: "#{token.location}: Expected a string after '#{prev_token.content}' but got '#{token.content}' instead")
      end
    end

    # Remove any trailing semicolons from the command list.
    command_list.pop if command_list.last.action.end? && command_list.last.arguments.empty?

    command_list
  end
end
