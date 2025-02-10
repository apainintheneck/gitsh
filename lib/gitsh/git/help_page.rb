# frozen_string_literal: true

module Gitsh
  module Git
    # Represents the help page for a Git command along with
    # any relevant usage and option information that was
    # able to be parsed from it.
    class HelpPage
      # @param command [String]
      #
      # @return [Gitsh::Git::HelpPage, nil]
      def self.for(command:)
        return unless Git.command_set.include?(command)

        @for ||= {}
        @for[command] ||= new(command: command)
      end

      private_class_method :new

      # @param command [String]
      attr_reader :command

      # @param command [String]
      def initialize(command:)
        @command = command
      end

      # @return [Array<String>]
      def long_options
        @long_options ||= raw_options
          .select { |option| option.start_with?("--") }
          .map { |option| option.tr("=[<", "") }
          .freeze
      end

      # @param option [String]
      #
      # @return [Boolean]
      def option?(option)
        raw_options.include?(option)
      end

      private

      # Extract options from the help page.
      #
      # @return [Array<String>]
      def raw_options
        @raw_options ||= [].tap do |options|
          help_text = Git.help_page(command: @command)
          next unless help_text

          scanner = StringScanner.new(help_text)

          # Skip straight to the OPTIONS section.
          scanner.skip_until(/\nOPTIONS\n/)

          # Parse until the end of the string or docs.
          until scanner.eos? || scanner.match?(/GIT/)
            # Skip leading whitespace.
            scanner.skip(/[ ]+/)

            # Continue parsing options prefixed by dashes.
            while scanner.match?("-")
              if (option = scanner.scan(/-[a-zA-Z]/) || scanner.scan(/-(?:-[a-zA-Z]+)+/))
                # Parse short or long options.
                options << option
              elsif (reversible_option = scanner.skip("--[no]") && scanner.scan(/(?:-[a-zA-Z]+)+/))
                # Parse long reversible options.
                # Ex. `--[no]-source`
                options << "-#{reversible_option}"
                options << "--no#{reversible_option}"
              else
                # Break when no options are parsed.
                break
              end

              # Skip everything up to and including the next
              # comma and space that separates multiple options.
              break unless scanner.skip(/[^\n,]*,[ ]+/)
            end

            # Parse until the end of the line.
            scanner.skip_until(/\n/)
          end
        end.uniq.freeze
      end
    end
  end
end
