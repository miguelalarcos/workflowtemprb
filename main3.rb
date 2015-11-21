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
    attr_accessor :product
    def initialize(measure:, unit:, product:)
      @product = product
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
      if @product != other.product
        raise '+ must be same product'
      end
      if other.is_a? Numeric
        other = Unit(other, @unit)
      end
      if @unit != other.unit
        raise 'units must be of same type'
      end
      Unit.new(@measure + other.measure, @unit)
    end

    def -(other)
      if @product != other.product
        raise '- must be same product'
      end
      if other.is_a? Numeric
        other = Unit(other, @unit)
      end
      if @unit != other.unit
        raise 'units must be of same type'
      end
      Unit.new(measure: @measure - other.measure, unit: @unit, product: @product)
    end

    def *(num)
      Unit.new(measure: @measure*num, unit: @unit, product: @product)
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
      @measure.to_s + ' ' + @unit + ' ' + @product.to_s
    end

  end
end

U = SimpleUnit::Unit

class ThingModel

  def initialize(product:, quantity:, unit:, subproducts:nil)
    @product = product
    @quantity = quantity
    @unit = unit
    @stock = U.new(measure: quantity, unit: unit, product: product)
    @subproducts = subproducts
  end

  def stock(subproduct=nil)
    if subproduct.nil?
      @stock
    else
      q, u = @subproducts[subproduct]
      U.new(measure: q, unit: u, product: subproduct)*@stock.measure
    end
  end

end

class Thing
  def initialize(code:, model:)
    @code = code
    @model = model

  end
end

subproducts = {'cuchilla-C10' => [5, 'unit'], 'desodorante-D3' => [1, 'unit']}

pack = ThingModel.new product: 'Pack cuchillas+desodorante', quantity: 1000, unit: 'unit', subproducts: subproducts

puts pack.stock 'cuchilla-C10'
puts pack.stock 'desodorante-D3'
puts pack.stock

