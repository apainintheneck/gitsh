# frozen_string_literal: true

module Gitsh
  module Completer
    # @param zipper [Gitsh::Zipper]
    #
    # @return [Array<String>, nil]
    def self.completions(zipper)
      if zipper.last.command?
        for_command(zipper)
      elsif zipper.last.long_option? && zipper.last.options_allowed?
        for_long_option(zipper)
      end
    end

    # @param zipper [Gitsh::Zipper]
    #
    # @return [Array<String>, nil]
    def self.for_command(zipper)
      return if zipper.last.valid_command?

      command_prefix_regex = /^#{Regexp.escape(zipper.last.token.raw_content)}./

      Gitsh
        .all_commands
        # Complete all commands starting with the given prefix.
        .grep(command_prefix_regex)
        # Sort results by shortest command and then alphabetically.
        .sort_by { |cmd| [cmd.size, cmd] }
    end
    private_class_method :for_command

    # @param zipper [Gitsh::Zipper]
    #
    # @return [Array<String>, nil]
    def self.for_long_option(zipper)
      last_command_zipper = zipper.reverse_find(&:command?)
      return unless last_command_zipper&.valid_command?

      command = last_command_zipper.token.content
      long_option_prefix_regex = /^#{Regexp.escape(zipper.last.token.raw_content)}./

      Git::HelpPage
        .for(command: command)
        .long_options
        # Complete all commands starting with the given prefix.
        .grep(long_option_prefix_regex)
        # Sort results by shortest command and then alphabetically.
        .sort_by { |cmd| [cmd.size, cmd] }
    end
  end
end
