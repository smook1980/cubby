describe Cubby::Store::Bucket do
  around do |spec|
    Cubby.open SpecHelper.tmpdir
    spec.run
    Cubby.close!
  end

  let(:model) do
    Class.new(Cubby::Model) do
      def self.name
        'TestModel'.freeze
      end
    end
  end

  let(:lmdb_env) { Cubby.store.env }
  subject        { described_class.new Cubby.store, model }

  describe '#initialize' do
    it 'sets the model_class' do
      expect(subject.model_class).to be(model)
    end

    it 'defines the namespace' do
      expect(subject.namespace).to eq(model.name)
    end

    it 'open the key value store' do
      expect(subject.kvs).to be_instance_of(Cubby::Store::SerializingProxy)
    end
  end
end
