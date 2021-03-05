require 'minitest_helper'

describe Rasti::Model do

  describe 'Initialization' do

    it 'All attributes' do
      point = Point.new x: 1, y: 2
      point.x.must_equal 1
      point.y.must_equal 2
    end

    it 'Some attributes' do
      point = Point.new x: 1

      point.assigned?(:x).must_equal true
      point.assigned?(:y).must_equal false

      point.x.must_equal 1

      error = proc { point.y }.must_raise Rasti::Model::NotAssignedAttributeError
      error.message.must_equal 'Not assigned attribute y'
    end

    it 'Invalid attributes' do
      error = proc { Point.new z: 3 }.must_raise Rasti::Model::InvalidAttributesError
      error.message.must_equal 'Invalid attributes: z'
    end

    it 'Indifferent attribute keys' do
      point = Point.new 'x' => 1, 'y' => 2
      point.x.must_equal 1
      point.y.must_equal 2
    end

  end

  describe 'Casting' do

    it 'Attribute' do
      model = Rasti::Model[text: T::String]
      m = model.new text: 123
      m.text.must_equal '123'
    end

    it 'Nested model' do
      range = Rasti::Model[min: T::Integer, max: T::Integer]
      model = Rasti::Model[range: T::Model[range]]

      m = model.new range: {min: '1', max: '10'}

      m.range.must_be_instance_of range
      m.range.min.must_equal 1
      m.range.max.must_equal 10
    end

    it 'Custom' do
      position_1 = Position.new type: '2D', point: {x: 1, y: 2}

      position_1.point.must_be_instance_of Point
      position_1.point.x.must_equal 1
      position_1.point.y.must_equal 2

      position_2 = Position.new type: '3D', point: {x: 1, y: 2, z: 3}

      position_2.point.must_be_instance_of Point3D
      position_2.point.x.must_equal 1
      position_2.point.y.must_equal 2
      position_2.point.z.must_equal 3
    end

    it 'Invalid value' do
      model = Rasti::Model[boolean: T::Boolean]

      m = model.new boolean: 'x'

      error = proc { m.boolean }.must_raise Rasti::Types::CastError
      error.message.must_equal "Invalid cast: 'x' -> Rasti::Types::Boolean"
    end

    it 'Invalid nested value' do
      range = Rasti::Model[min: T::Integer, max: T::Integer]
      model = Rasti::Model[range: T::Model[range]]

      m = model.new range: {min: 1, max: true}

      error = proc { m.range.max }.must_raise Rasti::Types::CastError
      error.message.must_equal "Invalid cast: true -> Rasti::Types::Integer"
    end

  end

  describe 'Defaults' do

    it 'Value' do
      model = Class.new(Rasti::Model) do
        attribute :text, T::String, default: 'xyz'
      end

      m = model.new
      m.text.must_equal 'xyz'
    end

    it 'Block' do
      model = Class.new(Rasti::Model) do
        attribute :time_1, T::Time['%F']
        attribute :time_2, T::Time['%F'], default: ->(m) { m.time_1 }
      end

      m = model.new time_1: Time.now
      m.time_2.must_equal m.time_1
    end

  end

  describe 'Comparable' do

    it 'Equivalency (==)' do
      point_1 = Point.new x: 1, y: 2
      point_2 = Point3D.new x: 1, y: 2
      point_3 = Point.new x: 2, y: 1

      assert point_1 == point_2
      refute point_1 == point_3
    end

    it 'Equality (eql?)' do
      point_1 = Point.new x: 1, y: 2
      point_2 = Point.new x: 1, y: 2
      point_3 = Point3D.new x: 1, y: 2
      point_4 = Point.new x: 2, y: 1

      assert point_1.eql?(point_2)
      refute point_1.eql?(point_3)
      refute point_1.eql?(point_4)
    end

    it 'hash' do
      point_1 = Point.new x: 1, y: 2
      point_2 = Point.new x: 1, y: 2
      point_3 = Point3D.new x: 1, y: 2
      point_4 = Point.new x: 2, y: 1

      point_1.hash.must_equal point_2.hash
      point_1.hash.wont_equal point_3.hash
      point_1.hash.wont_equal point_4.hash
    end

  end

  describe 'Serialization and deserialization' do

    let :address_class do
      Rasti::Model[
        street: T::String,
        number: T::Integer
      ]
    end

    let :birthday_class do
      Rasti::Model[
        day:   T::Integer,
        month: T::Integer,
        year:  T::Integer
      ]
    end

    let :contact_class do
      Rasti::Model[
        name:      T::String,
        birthday:  T::Model[birthday_class],
        phones:    T::Hash[T::Symbol, T::Integer],
        addresses: T::Array[T::Model[address_class]],
        labels:    T::Array[T::String]
      ]
    end

    let :attributes do
      {
        name: 'John',
        birthday: {
          day: 19,
          month: 6,
          year: 1993
        },
        phones: {
          office: 1234567890,
          house:  456456456
        },
        addresses: [
          {street: 'Lexington Avenue', number: 123},
          {street: 'Park Avenue',      number: 456}
        ],
        labels: ['Friend', 'Work']
      }
    end

    it 'All' do
      contact = contact_class.new attributes
      contact.to_h.must_equal attributes
    end

    it 'Only' do
      contact = contact_class.new attributes

      contact.to_h(only: [:name, :birthday]).must_equal name: attributes[:name],
                                                        birthday: attributes[:birthday]
    end

    it 'Except' do
      contact = contact_class.new attributes

      contact.to_h(except: [:age, :addresses]).must_equal name: attributes[:name],
                                                          birthday: attributes[:birthday],
                                                          phones: attributes[:phones],
                                                          labels: attributes[:labels]
    end

  end

  it 'Merge' do
    point_1 = Point.new x: 1, y: 2
    point_2 = point_1.merge x: 10

    point_1.x.must_equal 1
    point_1.y.must_equal 2

    point_2.x.must_equal 10
    point_2.y.must_equal 2
  end

  it 'to_s' do
    Position.to_s.must_equal 'Position[type, point]'

    Position.new(point: {x: 1, y: 2}).to_s.must_equal 'Position[type: "2D", point: Point[x: 1, y: 2]]'

    Position.attributes.map(&:to_s).must_equal [
      'Rasti::Model::Attribute[name: :type, type: Rasti::Types::Enum["2D", "3D"], options: {:default=>"2D"}]',
      'Rasti::Model::Attribute[name: :point, type: :cast_point, options: {}]'
    ]
  end

  it 'Ihnerits superclass attributes' do
    point = Point3D.new x: 1, y: 2, z: 3
    point.x.must_equal 1
    point.y.must_equal 2
    point.z.must_equal 3
  end

  it 'Invalid attribute redefinition' do
    error = proc { Point[x: T::String] }.must_raise ArgumentError
    error.message.must_equal 'Attribute x already exists'
  end

end