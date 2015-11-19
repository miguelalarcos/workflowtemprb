module SimpleUnit
  class Unit
    @@units = {
        :volume => {
            'liter' => 1,
            'centiliter' => 0.01,
            'mililiter' => 0.001,
            'botella250cl' => 0.25,
            'caja4b250cl' => 1
        },
        :unit => {
            'unit' => 1
        }
    }
    attr_reader :measure, :unit
    def initialize(measure, unit=nil)
      if unit.nil?
        measure, unit = measure.split
        measure = measure.to_f
      end

      do_break = false
      base = nil
      factor = nil
      @@units.each do |key, val|
        val.each do |unit_, value|
          if value == 1
            base = unit_
          end
          if unit_ == unit
            factor = value
            do_break = true
            break
          end
        end
        break if do_break
      end
      @measure = measure * factor
      @unit = base
    end

    def +(other)
      if other.is_a? Numeric
        other = Unit(other, @unit)
      end
      if @unit != other.unit
        raise 'units must be of same type'
      end
      Unit.new(@measure + other.measure, @unit)
    end

    def -(other)
      if other.is_a? Numeric
        other = Unit(other, @unit)
      end
      if @unit != other.unit
        raise 'units must be of same type'
      end
      Unit.new(@measure - other.measure, @unit)
    end

    def *(num)
      Unit.new(@measure*num, @unit)
    end

    def to(unit)
      @@units.each do |key, val|
        val.each do |unit_, value|
          if unit_ == unit
            return @measure / value
          end
        end
      end
    end
    def to_s
      @measure.to_s + ' ' + @unit
    end
  end
end

U = SimpleUnit::Unit

class ThingModel
  attr_reader :measure, :unit, :product
  attr_accessor :stock
  def initialize(measure:, product:, stock: 0)
    @measure = U.new(measure)
    @stock = stock
    @product = product
    @unit = nil
  end

  def +(other)
    if @product != other.product
      raise '+ must be same product'
    end
    @measure*@stock + other.measure*other.stock
  end

end

class Thing
  def initialize(code:, model:)
    @code = code
    @model = model

  end
end

c1 = ThingModel.new measure: '1 liter', product: 'zumo naranja normal', stock: 5
c2 = ThingModel.new measure: '1.5 liter', product: 'zumo naranja normal', stock: 7

print c1 + c2

t1 = ThingModel.new measure: '1 unit', product: 'LG-televisor-101E', stock: 100
cu1 = ThingModel.new measure: '5 unit', product: 'Guillet cuchilla afeitar A-105', stock: 1000
cu2 = ThingModel.new measure: '1 unit', product: 'Guillet cuchilla afeitar A-105', stock: 501

puts

print cu1 + cu2