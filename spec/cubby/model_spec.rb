module Fixtures
  def self.reset!
    remove_const :TestModel
  end
end

describe Cubby::Model do
  before do
    Fixtures::TestModel = Class.new(Cubby::Model)
  end

  after do
    Fixtures.reset!
  end

  let(:model_class) do
    Fixtures::TestModel
  end

  context 'when subclassed' do
    it 'can be instantiated' do
      expect(model_class.new).to be_instance_of(model_class)
    end

    it 'is storable' do
      expect(model_class.new).to be_kind_of(Cubby::Model::Storable)
    end
  end

  describe Cubby::Model::Storable do
    it '.store by default delegates to Cubby.store' do
      expect(Cubby).to receive(:store)
      model_class.store
    end

    it '.store= overrides the model store' do
      model_store = double(:store)
      model_class.store = model_store

      expect(model_class.store).to be(model_store)
    end
  end

  describe '.attribute' do
    before do
      model_class.class_eval do
        attribute :field, Cubby::Types::String
      end
    end

    subject { model_class.new }

    it 'creates an accessor and setter' do
      expect(subject).to respond_to(:field)
      expect(subject).to respond_to(:field=)
    end

    it 'creates an attribute that can be set and read' do
      subject.field = 'value'
      expect(subject.field).to eq('value')
    end

    it 'converts the value to the given type' do
      subject.field = 1

      expect(subject.field).to eq('1')
    end

    describe 'types' do
      [
        [Cubby::Types::String, 123, '123'],
        [Cubby::Types::Integer, "123", 123],
        [Cubby::Types::Boolean, 1, true],
        [Cubby::Types::Float, '0.5', 0.5],
        [Cubby::Types::Date, Date.today.to_s, Date.today],
        [Cubby::Types::DateTime, (expected = DateTime.now).iso8601(9).to_s, expected]
      ].each do |type, input, output|
        it "correctly coerces #{type}" do
          model_class.class_eval do
            attribute :coerce_field, type
          end

          subject.coerce_field = input
          expect(subject.coerce_field).to eq(output)
        end

        it "allows assignment of nil for #{type}" do
          model_class.class_eval do
            attribute :coerce_field, type
          end

          subject.coerce_field = input
          subject.coerce_field = nil
          expect(subject.coerce_field).to be_nil
        end

        it "correctly coerces Array[#{type}]" do
          model_class.class_eval do
            attribute :coerce_field,
              Cubby::Types::Array[type]
          end

          subject.coerce_field = [input]
          expect(subject.coerce_field).to eq([output])
        end

        it "allows assignment of nil for Array[#{type}]" do
          model_class.class_eval do
            attribute :coerce_field,
              Cubby::Types::Array[type]
          end

          subject.coerce_field = [input]
          subject.coerce_field = nil
          expect(subject.coerce_field).to be_nil
        end

        it "allows assignment of an array with nil for Array[#{type}]" do
          model_class.class_eval do
            attribute :coerce_field,
              Cubby::Types::Array[type]
          end

          subject.coerce_field = [input]
          subject.coerce_field = [nil]
          expect(subject.coerce_field).to eq([nil])
        end

        it "coerces a value added by << Array[#{type}]" do
          model_class.class_eval do
            attribute :coerce_field,
              Cubby::Types::Array[type]
          end

          subject.coerce_field = []
          subject.coerce_field << input
          expect(subject.coerce_field).to eq([output])
        end
      end
    end

    describe 'dirty checking' do
      it 'tracks changes to the model' do
        expect(subject.changed?).to be_falsey
        expect(subject.field_changed?).to be_falsey

        subject.field = 'new value'

        expect(subject.changed?).to be_truthy
        expect(subject.field_changed?).to be_truthy
      end

      it 'tracks changes via << to an Array' do
        model_class.class_eval do
          attribute :array_field, Cubby::Types::Array[Cubby::Types::Integer]
        end

        subject.array_field = [1]
        subject.send(:clear_changes_information)

        subject.array_field << 2
        expect(subject.changed?).to be_truthy
        expect(subject.array_field_changed?).to be_truthy
      end

      it 'tracks changes via delete_at to an Array' do
        model_class.class_eval do
          attribute :array_field, Cubby::Types::Array[Cubby::Types::Integer]
        end

        subject.array_field = [1, 2]
        subject.send(:clear_changes_information)

        subject.array_field.delete_at(0)
        expect(subject.changed?).to be_truthy
        expect(subject.array_field_changed?).to be_truthy
      end
    end
  end

  describe '.fields' do
    before do
      model_class.class_eval do
        attribute :field1, Cubby::Types::String
        attribute :field2, Cubby::Types::String
      end
    end

    it 'returns a list of fields' do
      expect(model_class.fields).to eq([:field1, :field2])
    end
  end

  describe '#attributes' do
    before do
      model_class.class_eval do
        attribute :field1, Cubby::Types::String
        attribute :field2, Cubby::Types::String
      end
    end

    it 'returns a hash of field => values' do
      subject = model_class.new
      subject.field1 = 'value1'
      subject.field2 = 'value2'

      expect(subject.attributes).to eq(field1: 'value1', field2: 'value2')
    end
  end

  describe '.has_one' do
    before do
      model_class.store = Cubby::Store.new SpecHelper.tmpdir

      model_class.class_eval do
        has_one :child_model, ::Fixtures::TestModel
      end
    end

    after do
      model_class.store.close!
    end

    let(:child_model) { ::Fixtures::TestModel.new }
    subject { ::Fixtures::TestModel.new }

    it 'allows a model to be assigned' do
      subject.child_model = child_model
      expect(subject.child_model).to eq(child_model)
    end

    it 'assigns the id' do
      subject.child_model = child_model
      expect(subject.child_model_id).to eq(child_model.id)
    end

    it 'allows for nil' do
      subject.child_model = child_model
      subject.child_model = nil

      expect(subject.child_model_id).to be_nil
      expect(subject.child_model).to be_nil
    end
  end

  describe '#save' do
    before do
      model_class.store = Cubby::Store.new SpecHelper.tmpdir

      model_class.class_eval do
        attribute :field1, Cubby::Types::String
        attribute :field2, Cubby::Types::String
      end
    end

    after do
      model_class.store.close!
    end

    subject do
      model_class.new.tap do |m|
        m.field1 = 'value1'
        m.field2 = 'value2'
      end
    end

    it 'can be saved' do
      subject.save
    end

    it 'is a new model until saved' do
      expect(subject.new_model?).to be_truthy
      subject.save
      expect(subject.new_model?).to be_falsey
    end

    it 'is not dirty after save' do
      expect(subject.changed?).to be_truthy
      subject.save
      expect(subject.changed?).to be_falsey
    end

    it 'tracks the changes during save' do
      changes = subject.changes
      subject.save
      expect(subject.previous_changes).to eq(changes)
    end

    it 'updates the created and saved at metadata'
    it 'can save all types'
  end

  describe '.find' do
    before do
      model_class.store = Cubby::Store.new SpecHelper.tmpdir

      model_class.class_eval do
        attribute :field1, Cubby::Types::String
        attribute :field2, Cubby::Types::String
      end
    end

    after do
      model_class.store.close!
    end

    let(:id) do
      model_class.new.tap do |m|
        m.field1 = 'value1'
        m.field2 = 'value2'
        m.save
      end.id
    end

    it 'loads an instance of the model' do
      model = model_class.find(id)
      expect(model).to_not be_nil
    end

    context 'when loading a model instance' do
      subject { model_class.find(id) }
      it 'sets the model id' do
        expect(subject.id).to eq(id)
      end

      it 'is not dirty on load' do
        expect(subject.changed?).to be_falsey
      end

      it 'loads the stored fields' do
        expect(subject.field1).to eq('value1')
        expect(subject.field2).to eq('value2')
      end

      it 'is not a new model' do
        expect(subject.new_model?).to be_falsey
      end
    end
  end

  context 'when saving and restoring' do
    before { model_class.store = Cubby::Store.new SpecHelper.tmpdir }
    after  { model_class.store.close! }

    [
      [Cubby::Types::String, 123, '123'],
      [Cubby::Types::Integer, "123", 123],
      [Cubby::Types::Boolean, true, true],
      [Cubby::Types::Float, 1, 1.0],
      [Cubby::Types::Date, Date.today.to_s, Date.today],
      [Cubby::Types::DateTime, (expected = DateTime.now).iso8601(9).to_s, expected]
    ].each do |type, input, output|
      it "handles #{type} corectly" do
        model_class.class_eval do
          attribute :field, type
        end

        saved_model = model_class.new
        saved_model.field = input
        saved_model.save

        restored_model = model_class.find(saved_model.id)
        expect(restored_model.field).to eq(output)
      end

      it "handles an Array[#{type}]" do
        model_class.class_eval do
          attribute :field, Cubby::Types::Array[type]
        end

        saved_model = model_class.new
        saved_model.field = [input, input, input]
        saved_model.save

        restored_model = model_class.find(saved_model.id)
        expect(restored_model.field).to eq([output, output, output])
      end

      it 'handles a has_one relation' do
        ::Fixtures::TestModel.class_eval do
          has_one :field, ::Fixtures::TestModel
        end

        child_model = ::Fixtures::TestModel.new
        child_model.save

        saved_model = ::Fixtures::TestModel.new
        saved_model.field = child_model
        saved_model.save

        restored_model = model_class.find(saved_model.id)
        expect(restored_model.field_id).to eq(child_model.id)
        expect(restored_model.field).to eq(child_model)
      end
    end
  end
end
