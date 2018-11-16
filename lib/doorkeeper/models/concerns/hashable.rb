# frozen_string_literal: true

module Doorkeeper
  module Models
    ##
    # Hashable finder to provide lookups for input plaintext values which are
    # mapped to their hashes before lookup.
    module Hashable
      extend ActiveSupport::Concern

      module ClassMethods
        private

        # Returns an instance of the Doorkeeper::AccessToken with
        # specific token value.
        #
        # @param attr [Symbol]
        #   The token attribute we're looking with.
        #
        # @param token [#to_s]
        #   token value (any object that responds to `#to_s`)
        #
        # @return [Doorkeeper::AccessToken, nil] AccessToken object or nil
        #   if there is no record with such token
        #
        def find_by_hashed_or_plain_token(attr, token)
          unless Doorkeeper.configuration.hash_secrets?
            return find_by(attr => token.to_s)
          end

          mapped_token = Doorkeeper.configuration.hashed_or_plain_token(
            token.to_s
          )

          # Allow looking up previously unhashed tokens as a fallback
          find_by(attr => mapped_token.to_s) || find_by(attr => token.to_s)
        end
      end
    end
  end
end
