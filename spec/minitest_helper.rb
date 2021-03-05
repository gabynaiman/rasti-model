require 'coverage_helper'
require 'minitest/autorun'
require 'minitest/colorin'
require 'pry-nav'
require 'rasti-model'

T = Rasti::Types

Point = Rasti::Model[:x, :y]

Point3D = Point[:z]

class Position < Rasti::Model
  attribute :type,  T::Enum['2D', '3D'], default: '2D'
  attribute :point, :cast_point

  private

  def cast_point(value)
    type == '2D' ? Point.new(value) : Point3D.new(value)
  end
end