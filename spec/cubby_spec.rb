require 'spec_helper'

describe Cubby do
  let(:path) { SpecHelper.tmpdir }

  describe '.config' do
    it 'sets the database root from path' do
      expect(LMDB).to receive(:new).with(path, kind_of(Hash))

      Cubby.config path
    end
  end

  describe '.store' do
    before { Cubby.config path }

    it 'is an instance of store' do
      expect(Cubby.store).to be_instance_of(Cubby::Store)
    end
  end

  it 'has a version number' do
    expect(Cubby::VERSION).not_to be nil
  end
end
