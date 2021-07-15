# frozen_string_literal: true

module Supplejack
  module Util
    class << self
      #
      # Return a array no matter what.
      #
      def array(object)
        case object
        when Array
          object
        when NilClass
          []
        else
          [object]
        end
      end

      #
      # Try to parse any string into a Time object
      #
      def time(time)
        return time if time.is_a?(Time) || time.is_a?(DateTime)

        begin
          Time.parse(time)
        rescue StandardError
          nil
        end
      end

      #
      # Perform a deep merge of hashes, returning the result as a new hash.
      # See #deep_merge_into for rules used to merge the hashes
      #
      # ==== Parameters
      #
      # left<Hash>:: Hash to merge
      # right<Hash>:: The other hash to merge
      #
      # ==== Returns
      #
      # Hash:: New hash containing the given hashes deep-merged.
      #
      def deep_merge(left, right)
        deep_merge_into({}, left, right)
      end

      #
      # Perform a deep merge of the right hash into the left hash
      #
      # ==== Parameters
      #
      # left:: Hash to receive merge
      # right:: Hash to merge into left
      #
      # ==== Returns
      #
      # Hash:: left
      #
      def deep_merge!(left, right)
        deep_merge_into(left, left, right)
      end

      private

      #
      # Deep merge two hashes into a third hash, using rules that produce nice
      # merged parameter hashes. The rules are as follows, for a given key:
      #
      # * If only one hash has a value, or if both hashes have the same value,
      #   just use the value.
      # * If either of the values is not a hash, create arrays out of both
      #   values and concatenate them.
      # * Otherwise, deep merge the two values (which are both hashes)
      #
      # ==== Parameters
      #
      # destination<Hash>:: Hash into which to perform the merge
      # left<Hash>:: One hash to merge
      # right<Hash>:: The other hash to merge
      #
      # ==== Returns
      #
      # Hash:: destination
      #
      def deep_merge_into(destination, left, right)
        left.to_hash.symbolize_keys!
        right.to_hash.symbolize_keys!
        left.each_pair do |name, left_value|
          right_value = right[name] if right
          destination[name] =
            if right_value.nil? || left_value == right_value
              left_value
            elsif !left_value.respond_to?(:each_pair) || !right_value.respond_to?(:each_pair)
              Array(left_value) + Array(right_value)
            else
              merged_value = {}
              deep_merge_into(merged_value, left_value, right_value)
            end
        end
        left_keys = Set.new(left.keys)
        destination.merge!(right.reject { |k, _v| left_keys.include?(k) })
        destination
      end
    end
  end
end
