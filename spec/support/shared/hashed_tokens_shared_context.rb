# frozen_string_literal: true

shared_context 'with token hashing enabled' do
  def hash_function(str)
    Digest::SHA256.hexdigest(str)
  end

  before do
    hash_ref = method(:hash_function)
    Doorkeeper.configure do
      hash_secrets(&hash_ref)
    end
  end
end
