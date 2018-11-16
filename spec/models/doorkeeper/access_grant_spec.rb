require 'spec_helper'

describe Doorkeeper::AccessGrant do
  let(:clazz) { Doorkeeper::AccessGrant }
  subject { FactoryBot.build(:access_grant) }

  it { expect(subject).to be_valid }

  it_behaves_like 'an accessible token'
  it_behaves_like 'a revocable token'
  it_behaves_like 'a unique token' do
    let(:factory_name) { :access_grant }
  end

  context 'with hashing enabled' do
    let(:grant) { FactoryBot.create :access_grant }
    include_context 'with token hashing enabled'

    it 'holds a volatile plaintext token when created' do
      expect(grant.plaintext_token).to be_a(String)
      expect(grant.token).to eq(hash_function(grant.plaintext_token))

      # Finder method only finds the hashed token
      loaded = clazz.find_by(token: grant.token)
      expect(loaded).to eq(grant)
      expect(loaded.plaintext_token).to be_nil
      expect(loaded.token).to eq(grant.token)
    end

    it 'does not find_by plain text tokens' do
      expect(clazz.find_by(token: grant.plaintext_token)).to be_nil
    end

    it 'does provide lookups with either through by_token' do
      expect(clazz.by_token(grant.plaintext_token)).to eq(grant)
      # This will work only due to lookup of input token
      expect(clazz.by_token(grant.token)).to eq(grant)
    end
  end

  describe 'validations' do
    it 'is invalid without resource_owner_id' do
      subject.resource_owner_id = nil
      expect(subject).not_to be_valid
    end

    it 'is invalid without application_id' do
      subject.application_id = nil
      expect(subject).not_to be_valid
    end

    it 'is invalid without token' do
      subject.save
      subject.token = nil
      expect(subject).not_to be_valid
    end

    it 'is invalid without expires_in' do
      subject.expires_in = nil
      expect(subject).not_to be_valid
    end
  end

  describe '.revoke_all_for' do
    let(:resource_owner) { double(id: 100) }
    let(:application) { FactoryBot.create :application }
    let(:default_attributes) do
      {
        application: application,
        resource_owner_id: resource_owner.id
      }
    end

    it 'revokes all tokens for given application and resource owner' do
      FactoryBot.create :access_grant, default_attributes

      described_class.revoke_all_for(application.id, resource_owner)

      described_class.all.each do |token|
        expect(token).to be_revoked
      end
    end

    it 'matches application' do
      access_grant_for_different_app = FactoryBot.create(
        :access_grant,
        default_attributes.merge(application: FactoryBot.create(:application))
      )

      described_class.revoke_all_for(application.id, resource_owner)

      expect(access_grant_for_different_app.reload).not_to be_revoked
    end

    it 'matches resource owner' do
      access_grant_for_different_owner = FactoryBot.create(
        :access_grant,
        default_attributes.merge(resource_owner_id: 90)
      )

      described_class.revoke_all_for application.id, resource_owner

      expect(access_grant_for_different_owner.reload).not_to be_revoked
    end
  end
end
