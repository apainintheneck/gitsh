require "./spec_helper"
require "../src/tokenizer.cr"

class TokenFactory
  @tokens = [] of Tokenizer::Token

  def and : self
    @tokens << new_token(Tokenizer::Token::Type::And, "&&")
    self
  end

  def or : self
    @tokens << new_token(Tokenizer::Token::Type::Or, "||")
    self
  end

  def end : self
    @tokens << new_token(Tokenizer::Token::Type::End, ";")
    self
  end

  def string(content : String) : self
    @tokens << new_token(Tokenizer::Token::Type::String, content)
    self
  end

  def to_a
    @tokens
  end

  # Note: Token position is not super important during tests and we only test for equality
  # based on token type and content for that reason.
  private def new_token(type : Tokenizer::Token::Type, content : String) : Tokenizer::Token
    Tokenizer::Token.new(type: type, content: content, start_position: 0, end_position: 0)
  end
end

describe Tokenizer do
  describe ".tokenize" do
    it "tokenizes blanks lines" do
      ["", "   ", "\t", "\n", "  \t \n"].each do |line|
        Tokenizer.tokenize(line).empty?.should be_true
      end
    end

    it "tokenizes commands without arguments" do
      %w{diff log branch commit}.each do |line|
        Tokenizer.tokenize(line).should eq(TokenFactory.new.string(line).to_a)
      end
    end

    it "tokenizes single-quoted strings" do
      [
        {
          %{grep 'type : Tokenizer'},
          TokenFactory.new.string("grep").string("type : Tokenizer").to_a,
        },
        {
          %{grep 'describe ".tokenize" do'  },
          TokenFactory.new.string("grep").string(%{describe ".tokenize" do}).to_a,
        },
        {
          %{add -- '*.js'},
          TokenFactory.new.string("add").string("--").string("*.js").to_a,
        },
        {
          %{ log --committer='Lawrence Kraft'},
          TokenFactory.new.string("log").string("--committer=Lawrence Kraft").to_a,
        },
      ].each do |line, tokens|
        Tokenizer.tokenize(line).should eq(tokens)
      end
    end

    it "tokenizes double-quoted strings" do
      [
        {
          %{grep   " type : Tokenizer"},
          TokenFactory.new.string("grep").string(" type : Tokenizer").to_a,
        },
        {
          %{log   --grep   "'exit' or 'quit'"},
          TokenFactory.new.string("log").string("--grep").string("'exit' or 'quit'").to_a,
        },
        {
          %{  add -- "*.js"},
          TokenFactory.new.string("add").string("--").string("*.js").to_a,
        },
        {
          %{log --author="One Punch Man"},
          TokenFactory.new.string("log").string("--author=One Punch Man").to_a,
        },
      ].each do |line, tokens|
        Tokenizer.tokenize(line).should eq(tokens)
      end
    end

    it "raises a syntax error when a matching closing quote is missing" do
      [
        %{grep "skdfsdklfj},
        %{commit -m 'slkdfjsdklfjds},
        %{log --author="sdkfsdlkj'dsfkjds'},
        %{branch -D 'sdkfsdlkj"dsfkjds"},
      ].each do |line|
        expect_raises(Tokenizer::SyntaxException, /Missing matching (?:single|double)-quote/) do
          Tokenizer.tokenize(line)
        end
      end
    end

    {% for name, action in {"and" => "&&", "or" => "||", "end" => ";"} %}
      it "tokenizes lines with '{{action.id}}'" do
        [
          "first {{action.id}} second",
          "first{{action.id}} second",
          "first {{action.id}}second",
          "first{{action.id}}second",
        ].each do |line|
          Tokenizer.tokenize(line).should eq(
            TokenFactory.new.string("first").{{name.id}}.string("second").to_a
          )
        end
      end

      it "tokenizes strings with '{{action.id}}'" do
        Tokenizer.tokenize("commit -m 'Fixed thing one {{action.id}} thing two'").should eq(
          TokenFactory.new.string("commit").string("-m").string("Fixed thing one {{action.id}} thing two").to_a
        )
      end
    {% end %}

    it "tokenizes strings with multiple actions" do
      [
        {
          "one && two; three || four",
          TokenFactory.new.string("one").and.string("two").end.string("three").or.string("four").to_a,
        },
        {
          "&&   &&&&;||",
          TokenFactory.new.and.and.and.end.or.to_a,
        },
      ].each do |line, tokens|
        Tokenizer.tokenize(line).should eq(tokens)
      end
    end
  end
end
