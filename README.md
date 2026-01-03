# Rasti::Model

[![Gem Version](https://badge.fury.io/rb/rasti-model.svg)](https://rubygems.org/gems/rasti-model)
[![CI](https://github.com/gabynaiman/rasti-model/actions/workflows/ci.yml/badge.svg)](https://github.com/gabynaiman/rasti-model/actions/workflows/ci.yml)
[![Coverage Status](https://coveralls.io/repos/github/gabynaiman/rasti-model/badge.svg?branch=master)](https://coveralls.io/github/gabynaiman/rasti-model?branch=master)
[![Code Climate](https://codeclimate.com/github/gabynaiman/rasti-model.svg)](https://codeclimate.com/github/gabynaiman/rasti-model)

Domain models with typed attributes

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rasti-model'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rasti-model

## Usage

### Basic models
```ruby
class Point < Rasti::Model
  attribute :x
  attribute :y
end

point = Point.new x: 1, y: 2
point.x # => 1
point.y # => 2

# Unexpected attributes
Point.new z: 3 # => Rasti::Model::UnexpectedAttributesError: Unexpected attributes: z
```

### Typed models
```ruby
T = Rasti::Types

class TypedPoint < Rasti::Model
  attribute :x, T::Integer
  attribute :y, T::Integer
end

point = TypedPoint.new x: '1', y: '2'
point.x # => 1
point.y # => 2
```

### Inline definition
```ruby
Point = Rasti::Model[:x, :y]

TypedPoint = Rasti::Model[x: T::Integer, y: T::Integer]
```

### Serialization and deserialization
```ruby
City = Rasti::Model[name: T::String]
Country = Rasti::Model[name: T::String, cities: T::Array[T::Model[City]]]

attributes = {
  name: 'Argentina',
  cities: [
    {name: 'Buenos Aires'},
    {name: 'Córdoba'},
    {name: 'Rosario'}
  ]
}

country = Country.new attributes
country.name # => 'Argentina'
country.cities # => [City[name: "Buenos Aires"], City[name: "Córdoba"], City[name: "Rosario"]]

country.to_h # => attributes

# Attribute filtering
country.to_h(only: [:name]) # => {name: "Argentina"}
country.to_h(except: [:cities]) # => {name: "Argentina"}
```

### Default values
```ruby
class User < Rasti::Model
  attribute :name, T::String
  attribute :admin, T::Boolean, default: false
  attribute :created_at, T::Time, default: ->(m) { Time.now }
end

user = User.new name: 'John'
user.admin # => false
user.created_at # => 2026-01-02 23:19:15 -0300
```

### Merging models
```ruby
point_1 = Point.new x: 1, y: 2
point_2 = point_1.merge x: 10
point_2.to_h # => {x: 10, y: 2}
```

### Custom attribute options
You can add custom metadata to attributes that can be used later (e.g., for UI generation):

```ruby
class User < Rasti::Model
  attribute :name, T::String, description: 'The user full name'
end

attribute = User.attributes.first
attribute.option(:description) # => 'The user full name'
```

These options are also included in the schema representation.

### Equality
```ruby
point_1 = Point.new x: 1, y: 2
point_2 = Point.new x: 1, y: 2
point_3 = Point.new x: 2, y: 1

point_1 == point_2 # => true
point_1 == point_3 # => false
```

### Error handling
```ruby
TypedPoint = Rasti::Model[x: T::Integer, y: T::Integer]

point = TypedPoint.new x: true
point.x # => Rasti::Types::CastError: Invalid cast: true -> Rasti::Types::Integer
point.y # => Rasti::Model::NotAssignedAttributeError: Not assigned attribute y

# Bulk validation
point = TypedPoint.new x: 'invalid', y: 'invalid'
point.cast_attributes! # => Rasti::Types::CompoundError: x: ["Invalid cast: \"invalid\" -> Rasti::Types::Integer"], y: ["Invalid cast: \"invalid\" -> Rasti::Types::Integer"]
```

### Model Schema
It is possible to obtain a serializable representation of the model structure (schema).

```ruby
Point = Rasti::Model[x: T::Integer, y: T::Integer]
Point.to_schema
# => {
#      model: "Point",
#      attributes: [
#        {name: :x, type: :integer},
#        {name: :y, type: :integer}
#      ]
#    }
```

#### Custom type serializers
You can register custom serializers for your types to be used in the schema generation:

```ruby
Rasti::Model::Schema.register_type_serializer(MyCustomType, :custom)

# Or with a block for more details
Rasti::Model::Schema.register_type_serializer(MyCustomType) do |type|
  {type: :custom, details: type.some_info}
end
```

Also, if a type responds to `to_schema`, it will be used.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/gabynaiman/rasti-model.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

