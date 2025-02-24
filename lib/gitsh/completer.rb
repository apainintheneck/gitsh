# frozen_string_literal: true

module Gitsh
  module Completer
    # Designed to be compatible with `Reline.completion_proc`.
    CALLBACK = lambda do |*|
      Completer.from_line(Reline.line_buffer.to_s)
    end

    # @param line [String]
    #
    # @return [Array<String>, nil]
    def self.from_line(line)
      return if line.end_with?(" ")

      zipper = Tokenizer.from_line(line)

      if zipper.last.command?
        for_command(zipper)
      elsif zipper.last.option? && zipper.last.options_allowed?
        for_option(zipper)
      end
    end

    # @param zipper [Gitsh::Zipper]
    #
    # @return [Array<String>, nil]
    def self.for_command(zipper)
      command_prefix_regex = /^#{Regexp.escape(zipper.last.token.raw_content)}/

      Gitsh
        .all_command_names
        # Complete all commands starting with the given prefix.
        .grep(command_prefix_regex)
        # Sort results by shortest command and then alphabetically.
        .sort_by { |cmd| [cmd.size, cmd] }
    end
    private_class_method :for_command

    # @param zipper [Gitsh::Zipper]
    #
    # @return [Array<String>, nil]
    def self.for_option(zipper)
      last_command_zipper = zipper.reverse_find(&:command?)
      return unless last_command_zipper

      command = last_command_zipper.token.content
      option_prefix_regex = /^#{Regexp.escape(zipper.last.token.raw_content)}/

      option_prefixes = if last_command_zipper.valid_git_command?
        GitHelp.for(command: command)&.option_prefixes
      elsif last_command_zipper.valid_internal_command?
        Commander.from_name(command)&.option_prefixes
      end

      return unless option_prefixes

      option_prefixes
        # Complete all commands starting with the given prefix.
        .grep(option_prefix_regex)
        # Sort results by shortest command and then alphabetically.
        .sort_by { |cmd| [cmd.size, cmd] }
    end
  end
end
