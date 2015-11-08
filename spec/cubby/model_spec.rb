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
end
