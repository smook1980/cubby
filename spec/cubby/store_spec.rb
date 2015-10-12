require 'spec_helper'

describe Cubby::Store do
  let(:path) { SpecHelper.tmpdir }
  subject { Cubby::Store.new path }

  describe '#[]' do
    it 'creates a database given a string' do
      db = subject['Test']
      expect(db).to be_kind_of(Cubby::Database)
    end

    it 'creates a database given a symbol' do
      db = subject[:test]
      expect(db).to be_kind_of(Cubby::Database)
    end

    it 'creates a database given a class' do
      db = subject[Cubby::Model]
      expect(db).to be_kind_of(Cubby::Database)
    end

    context 'when called multiple times' do
      it 'returns the same instance when given the same string' do
        db1 = subject['test']
        db2 = subject['test']

        expect(db1).to be(db2)
      end

      it 'returns the same instance when given the same symbol' do
        db1 = subject[:test2]
        db2 = subject[:test2]

        expect(db1).to be(db2)
      end

      it 'returns the same instance when given the same class' do
        db1 = subject[Cubby::Model]
        db2 = subject[Cubby::Model]

        expect(db1).to be(db2)
      end

      it 'returns the same instance when given a string and class whos name matches' do
        db1 = subject[Cubby::Model]
        db2 = subject['model']
        expect(db1).to be(db2)
      end
    end
  end
end
