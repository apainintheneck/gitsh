# frozen_string_literal: true

module Gitsh
  module Git
    # Represents a single option associated with a Git command.
    # These come in three main varieties.
    #
    # 1. Option prefix without parameter suffix
    #    Ex. `--all-match`
    #
    # 2. Option prefix withparameter suffix
    #    Ex. `--grep=<pattern>`
    #
    # 3. Option prefix with trailing parameters
    #    Ex. `--merged [<commit>]`
    class Option
      # @return [String]
      attr_reader :prefix
      # @return [String]
      attr_reader :suffix

      # @param prefix [String]
      # @param suffix [String]
      def initialize(prefix:, suffix:)
        @prefix = prefix
        @suffixes = suffix
      end

      def to_regex_str
      end

      private

      def parsed_suffix_hash
      end
    end
  end
end
