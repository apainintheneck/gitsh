require "./spec_helper"
require "../src/parser"

class CommandFactory
  @commands = [] of Command

  def and(arguments : Array(String)) : self
    @commands << Command.new(Command::Action::And, arguments)
    self
  end

  def or(arguments : Array(String)) : self
    @commands << Command.new(Command::Action::Or, arguments)
    self
  end

  def end(arguments : Array(String)) : self
    @commands << Command.new(Command::Action::End, arguments)
    self
  end

  def to_a : Array(Command)
    @commands
  end
end

describe Parser do
  it "parses a single command" do
    Parser.parse("checkout auto_update_tap").should eq(
      CommandFactory.new.end(%w[checkout auto_update_tap]).to_a
    )
  end

  it "parses multiple commands joined with an action" do
    [
      {
        %{add --all; commit -m "tmp"},
        CommandFactory.new.end(%w[add --all]).end(%w[commit -m tmp]).to_a,
      },
      {
        %{add --all || commit -m "tmp"},
        CommandFactory.new.end(%w[add --all]).or(%w[commit -m tmp]).to_a,
      },
      {
        %{add --all && commit -m "tmp"},
        CommandFactory.new.end(%w[add --all]).and(%w[commit -m tmp]).to_a,
      },
    ].each do |line, parse_result|
      Parser.parse(line).should eq(parse_result)
    end
  end

  it "parses a long series of commands" do
    parse_result = CommandFactory.new
      .end(%w[add ex.js])
      .and(%w[add ex.rb])
      .end(%w[git diff])
      .end(%w[git commit -m commit])
      .to_a

    Parser.parse("add ex.js && add ex.rb; git diff; git commit -m 'commit'").should eq(parse_result)
  end

  it "parses and ignores a trailing semicolon" do
    Parser.parse(%{grep 'rescue GitHub::API';}).should eq(
      CommandFactory.new.end(["grep", "rescue GitHub::API"]).to_a
    )
  end

  it "raises an error when there is an action to start a line" do
    %w[&& || ;].each do |action|
      line = [action, "second", "third"].join(" ")
      error_message = "Expected a string to start the line but got '#{action}' instead"

      expect_raises(Parser::Exception, error_message) do
        Parser.parse(line)
      end
    end
  end

  it "raises an error when there are two actions in a row in the middle of a line" do
    %w[&& || ;].repeated_combinations(2).each do |combo|
      line = ["first", *combo, "last"].join(" ")
      error_message = "Expected a string after '#{combo.first}' but got '#{combo.last}' instead"

      expect_raises(Parser::Exception, error_message) do
        Parser.parse(line)
      end
    end
  end

  it "raises an error when there is a && or || action to end a line" do
    %w[&& ||].each do |action|
      line = ["first", "second", action].join(" ")
      error_message = "Expected a string or a semicolon to end the line but got '#{action}' instead"

      expect_raises(Parser::Exception, error_message) do
        Parser.parse(line)
      end
    end
  end
end
