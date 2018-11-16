# frozen_string_literal: true

require 'spec_helper'

describe 'Hashable' do
  let(:clazz) do
    Class.new do
      include Doorkeeper::Models::Hashable

      def self.find_by(*)
        raise 'stub this'
      end
    end
  end

  describe :find_by_hashed_or_plain_token do
    let(:plain_token) { 'asdf' }
    let(:subject) { clazz.send(:find_by_hashed_or_plain_token, :token, plain_token) }

    context 'when not configured' do
      it 'always finds with the plain value even when nil' do
        expect(clazz).to receive(:find_by).with(token: plain_token).once.and_return(nil)
        expect(subject).to eq(nil)
      end
    end

    context 'when hashing configured' do
      include_context 'with token hashing enabled'
      let(:hashed_token) { hash_function(plain_token) }

      it 'calls find_by only on the hashed value if it returns' do
        expect(clazz).not_to receive(:find_by).with(token: plain_token)
        expect(clazz).to receive(:find_by).with(token: hashed_token).and_return(:result)

        expect(subject).to eq(:result)
      end

      it 'also searches for the plain token if no hashed exists' do
        expect(clazz).to receive(:find_by).with(token: plain_token).and_return(:result)
        expect(clazz).to receive(:find_by).with(token: hashed_token).and_return(nil)

        expect(subject).to eq(:result)
      end
    end
  end
end
