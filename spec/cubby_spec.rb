require 'pry'

describe Cubby do
  let(:path) { SpecHelper.tmpdir }

  describe '.config' do
    it 'sets the database root from path' do
      expect(LMDB).to receive(:new).with(path, kind_of(Hash))

      Cubby.open path
    end
  end

  describe '.store' do
    around do |spec|
      Cubby.open path
      spec.run
      Cubby.close!
    end

    it 'is an instance of store' do
      expect(Cubby.store).to be_instance_of(Cubby::Store)
    end
  end

  it '.store fails when not configured' do
    Cubby.close!
    expect { Cubby.store }.to raise_error(Cubby::Error)
  end

  it 'has a version number' do
    expect(Cubby::VERSION).not_to be nil
  end
end
