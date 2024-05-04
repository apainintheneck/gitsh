require "./command"
require "string_scanner"

module Tokenizer
  class SyntaxException < Exception; end

  record Token, type : Token::Type, content : String, start_position : Int32, end_position : Int32 do
    def_equals @type, @content # for testing

    enum Type
      String # "string"
      And    # &&
      Or     # ||
      End    # ;

      def to_action : Command::Action?
        case self
        in .and?
          Command::Action::And
        in .or?
          Command::Action::Or
        in .end?
          Command::Action::End
        in .string?
          nil
        end
      end

      def to_action! : Command::Action
        to_action.not_nil!
      end
    end

    def location : String
      "#{start_position}:#{end_position}"
    end
  end

  # Turn a line of input into a series of action and string tokens.
  def self.tokenize(line : String) : Array(Token)
    tokens = [] of Token
    scanner = StringScanner.new(line)

    while !scanner.eos?
      start_position = scanner.offset

      if scanner.skip(/\s+/) # whitespace
        next
      elsif scanner.scan(/&{2}/) # and (&&)
        tokens << Token.new(
          type: Token::Type::And,
          content: "&&",
          start_position: start_position,
          end_position: scanner.offset,
        )
      elsif scanner.scan(/[|]{2}/) # or (||)
        tokens << Token.new(
          type: Token::Type::Or,
          content: "||",
          start_position: start_position,
          end_position: scanner.offset,
        )
      elsif scanner.scan(/;/) # end (;)
        tokens << Token.new(
          type: Token::Type::End,
          content: ";",
          start_position: start_position,
          end_position: scanner.offset,
        )
      else # quoted or unquoted string
        tokens << Token.new(
          type: Token::Type::String,
          content: scan_string_token(scanner),
          start_position: start_position,
          end_position: scanner.offset,
        )
      end
    end

    tokens
  end

  # Scan a quoted or unquoted string. Only quoted strings can contain whitespace.
  private def self.scan_string_token(scanner : StringScanner) : String
    String.build do |builder|
      while !scanner.eos? && !scanner.check(/&{2}|[|]{2}|;|\s/)
        # a single ampersand or pipe character
        str = scanner.scan(/[&|]/)

        # TODO: Handle exempting quotes with the backslash character in strings.

        # a single-quoted string (without the quotes)
        str ||= if scanner.scan(/'([^']*)'/)
                  scanner[1]
                end

        # a double-quoted string (without the quotes)
        str ||= if scanner.scan(/"([^"]*)"/)
                  scanner[1]
                end

        # everything else that is not:
        # - an ampersand
        # - a pipe character
        # - a semicolon
        # - a single or double quote
        # - a whitespace character
        str ||= scanner.scan(/[^&|;'"\s]+/)

        if str
          builder << str
        else
          case scanner.peek(1)
          when "'"
            raise SyntaxException.new(message: "#{scanner.offset}: Missing matching single-quote to close string")
          when "\""
            raise SyntaxException.new(message: "#{scanner.offset}: Missing matching double-quote to close string")
          else
            # This should be unreachable but we provide sensible error message anyway.
            raise SyntaxException.new(message: "#{scanner.offset}: Unknown syntax error")
          end
        end
      end
    end
  end
end
