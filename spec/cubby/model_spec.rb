describe Cubby::Model do
  subject do
    Class.new(Cubby::Model) do

    end
  end

  context 'when subclassed' do
    it 'can be instantiated' do
      expect(subject.new).to be_instance_of(subject)
    end

    it 'is storable' do
      expect(subject.new).to be_kind_of(Cubby::Model::Storable)
    end
  end

  describe Cubby::Model::Storable do
    it '.store by default delegates to Cubby.store' do
      expect(Cubby).to receive(:store)
      subject.store
    end

    it '.store= overrides the model store' do
      model_store = double(:store)
      subject.store = model_store

      expect(subject.store).to be(model_store)
    end
  end
end
