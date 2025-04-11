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
```

### Error handling
```ruby
TypedPoint = Rasti::Model[x: T::Integer, y: T::Integer]

point = TypedPoint.new x: true
point.x # => Rasti::Types::CastError: Invalid cast: true -> Rasti::Types::Integer
point.y # => Rasti::Model::NotAssignedAttributeError: Not assigned attribute y
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/gabynaiman/rasti-model.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

