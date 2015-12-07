describe Cubby::Store::Bucket do
  around do |spec|
    Cubby.open SpecHelper.tmpdir
    spec.run
    Cubby.close!
  end

  let(:model) do
    SpecHelper.test_user_model
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

  describe '#each' do
    before do
      @users = (1..5).map { SpecHelper.build_user_instance.tap(&:save) }
    end

    it 'yields for each model saved' do
      models = []
      subject.each { |model| models << model }
      expect(models.count).to be(5)
    end
  end
end
