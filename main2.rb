require 'rspec'
require 'test/unit'
require 'test/unit/ui/console/testrunner'

module SimpleUnit
  class Unit
    @@units = {
        :caja => {
            'caja' => 1
        },
        :caja_ => {
            'caja*' => 1
        },
        :botella => {
            'botella' => 1
        },
        :palet =>{
            'palet' => 1
        },
        :palet_ =>{
            'palet*' => 1
        },
        :estante =>{
            'estante' => 1
        },
        :unit => {
            'unit' => 1
        },
        :distance => {
            'meter' => 1,
            'centimeter' => 0.01
        },
        :volume => {
            'liter' => 1,
            'mililiter' => 0.001
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
  end
end

U = SimpleUnit::Unit

module Thing
  class Thing
    attr_reader :unit, :code, :model, :size
    attr_accessor :product#, :size

    def initialize(unit: nil, code: nil, model: nil, size: nil)
      @aggregate = []
      @unit = unit
      @product = model||'_empty_'
      @code = code
      @size = size||'1 unit'
    end

    def create_fungible(quantity, unit, product)
     add_aggregate_line [quantity, unit, product]
    end

    def create_discrete(model, code, unit='unit')
      add_aggregate_line [1, 'unit', model]
      Thing.new unit: unit, code: code, model: model
    end

    def aggregate
      m = U.new(@size)
      ret = @aggregate.clone
      sufix = ''
      for r in ret
        if r[1] == m.unit and r[0] < m.measure or r[1].end_with? '*'
          sufix = '*'
          break
        end
      end
      ret.push [1, @unit+sufix, @product]
      ret
    end

    def add_aggregate(aggregate)
      old_product = @product
      for line in aggregate
        add_aggregate_line line
      end
      new_product = @product
      if new_product != old_product
        aggregate.push [-1, @unit, old_product]
        aggregate.push [1, @unit, new_product]
      end
      aggregate
    end

    def add_aggregate_line(line)
      to_delete = nil
      for aggr in @aggregate
        done = false
        q, u, p = aggr
        measure = U.new(q, u)
        if line[2] == p
          m = U.new(line[0], line[1])
          if m.unit == u
            new_measure = measure + m
            aggr[0] = new_measure.measure
            aggr[1] = new_measure.unit
            done = true
            if new_measure.measure == 0
              to_delete = aggr
            end
            break
          end
        end
      end
      if line[0] < 0
        if not done
          raise 'cannot subtract'
        end
        if to_delete
          @aggregate.delete to_delete
        end
        @product = '_empty_'
        for aggr in @aggregate
          q, u, p = aggr
          if @product == '_empty_'
            @product = p
          elsif @product != p and p != '_empty'
            @product = 'mixted'
          end
        end
      else
        if not done
          @aggregate.push line.clone
        end
        if @product == '_empty_'
          @product = line[2]
        elsif @product != line[2] and line[2] != '_empty_'
          @product = 'mixted'
        end
      end
    end
  end
end


############################## tests #############################

T = Thing::Thing

class TestAggregates < Test::Unit::TestCase

  def setup

  end

  def teardown

  end

  def test_empty
    palet = T.new(unit: 'palet')
    assert palet.aggregate == [[1, 'palet', '_empty_']]
  end

  def test_one_add
    palet = T.new(unit: 'palet')
    agg = palet.add_aggregate [[1, 'caja', 'manzana']]
    assert palet.aggregate == [[1, 'caja', 'manzana'], [1, 'palet', 'manzana']]
    assert agg == [[1, 'caja', 'manzana'], [-1, 'palet', '_empty_'], [1, 'palet', 'manzana']]
  end

  def test_2_aggregates_same_product
    caja = T.new(unit: 'caja')
    agg = caja.add_aggregate [[1, 'botella', 'manzana'], [2, 'botella', 'manzana']]
    assert caja.aggregate == [[3, 'botella', 'manzana'], [1, 'caja', 'manzana']]
    assert agg == [[1, 'botella', 'manzana'], [2, 'botella', 'manzana'], [-1, 'caja', '_empty_'], [1, 'caja', 'manzana']]
  end

  def test_2_aggregates_different_product
    caja = T.new(unit: 'caja')
    agg = caja.add_aggregate [[1, 'botella', 'pera'], [2, 'botella', 'manzana']]
    assert caja.aggregate == [[1, 'botella', 'pera'], [2, 'botella', 'manzana'], [1, 'caja', 'mixted']]
    assert agg == [[1, 'botella', 'pera'], [2, 'botella', 'manzana'], [-1, 'caja', '_empty_'], [1, 'caja', 'mixted']]
  end

  def test_negative
    caja = T.new(unit: 'caja')
    caja.add_aggregate [[1, 'botella', 'pera']]
    caja.add_aggregate [[-1, 'botella', 'pera']]
    assert caja.aggregate == [[1, 'caja', '_empty_']]
  end

  def test_unit_asterisk
    palet = T.new(unit: 'palet', size: '2 unit')
    palet.add_aggregate [[1, 'unit', 'televisor']]
    assert palet.aggregate == [[1, 'unit', 'televisor'], [1, 'palet*', 'televisor']]
    palet.add_aggregate [[1, 'unit', 'televisor']]
    assert palet.aggregate == [[2, 'unit', 'televisor'], [1, 'palet', 'televisor']]
    palet.add_aggregate [[-1, 'unit', 'televisor']]
    assert palet.aggregate == [[1, 'unit', 'televisor'], [1, 'palet*', 'televisor']]
    palet.add_aggregate [[-1, 'unit', 'televisor']]
    assert palet.aggregate == [[1, 'palet', '_empty_']]
  end
end

Test::Unit::UI::Console::TestRunner.run(TestAggregates)