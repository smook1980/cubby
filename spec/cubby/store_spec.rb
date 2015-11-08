describe Cubby::Store do
  let(:path)        { SpecHelper.tmpdir }
  subject           { Cubby::Store.new path }
  let(:model_class) { Class.new(Cubby::Model) }

  describe '#[]' do
    after { subject.close! }

    it 'creates a bucket given a Cubby::Model subtype' do
      db = subject[model_class]
      expect(db).to be_kind_of(Cubby::Store::Bucket)
    end

    it 'creates a bucket given an instance of a Cubby::Model subtype' do
      db = subject[model_class.new]
      expect(db).to be_kind_of(Cubby::Store::Bucket)
    end

    it 'fails with Cubby::Error when not given a Cubby::Model subtype' do
      expect { subject[Object] }.to raise_error Cubby::Error
    end

    it 'fails with Cubby::Error when not given a Cubby::Model subtype instance' do
      expect { subject[Object.new] }.to raise_error Cubby::Error
    end

    context 'returns the same bucket when called multiple times' do
      it 'with the same model class' do
        db1 = subject[model_class]
        db2 = subject[model_class]

        expect(db1).to be(db2)
      end

      it 'with difference instances of the same model class' do
        db1 = subject[model_class.new]
        db2 = subject[model_class.new]

        expect(db1).to be(db2)
      end

      it 'with the same instance of the model class' do
        model = model_class.new
        db1 = subject[model]
        db2 = subject[model]

        expect(db1).to be(db2)
      end

      it 'with a model class and an instance of the model class' do
        db1 = subject[model_class]
        db2 = subject[model_class.new]

        expect(db1).to be(db2)
      end
    end
  end

  describe '.close!' do
    it 'delegates to the LMDB env' do
      expect_any_instance_of(LMDB::Environment).to receive(:close).and_call_original
      subject.close!
    end
  end

  describe '.config' do
    after { subject.close! }

    it 'delegates to the LMDB env' do
      expect_any_instance_of(LMDB::Environment).to receive(:close).and_call_original
      expect(subject.config).to_not be_nil
    end
  end

  describe '.with_transaction' do
    after { subject.close! }

    it 'open a transaction for write' do
      expect_any_instance_of(LMDB::Environment).to receive(:transaction)
        .with(false)
        .and_call_original

      subject.with_transaction do
        # Write some data...
      end
    end

    it 'allows for read only transactions' do
      expect_any_instance_of(LMDB::Environment).to receive(:transaction)
        .with(true)
        .and_call_original

      subject.with_transaction(read_only: true) do
        # Read some data...
      end
    end
  end
end
