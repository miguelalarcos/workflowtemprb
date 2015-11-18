require 'time'
require 'ruby-measurement'

Measurement.define(:botella) do |unit|
  unit.alias :botellas
end

Measurement.define(:estante) do |unit|
  unit.alias :estantes
end

Measurement.define(:caja) do |unit|
  unit.alias :cajas
end

$botella = Measurement.parse('1 botella')
$liter = Measurement.parse('1 liter')
$estante =  Measurement.parse('1 estante')
$caja =  Measurement.parse('1 caja')

class Model

end

class AbstractThing < Model
  attr_reader :code

  def initialize(code)
    super()
    @code = code
  end
end

def is_contained_in(b) # server side
  rel = ContainsRelationCollection.where(klass_b: b.class.to_s, b_id: b.object_id, end_: nil)
  cls = rel.klass_a
  return Object.const_get(cls+'Collection').where(_id: rel.a_id)
end

def containers b # server side
  a = is_contained_in b
  ret = []
  while not a.nil?
    ret.push(a)
    a = is_contained_in a
  end
  ret
end


class AbstractContainerThing < AbstractThing
  attr_accessor :quantity, :quantity_unit

  def initialize(code, quantity_unit, quantity=0)
    super code

    @quantity_unit = quantity_unit
    if quantity == 0
      @quantity = quantity_unit * quantity
    else
      @quantity = quantity
    end
  end

  # when contains normal things
  def contains(b, ini=nil)
    ContainsRelation.new(self.class.to_s, self.object_id, b.class.to_s, b.object_id, ini)
    # falta finalizar relacion anterior si la hay
  end
end

def contains item  # task server side
  rels = ContainsRelationCollection.where(klass_a: item.class.to_s, a_id: item.object_id, end_: nil)
  if rels
    ret = []
    for rel in rels
      cls = rel.klass_b
      obj = Object.const_get(cls+'Collection').where(_id: rel.b_id)
      ret.append(obj)
    end
    ret
  else
    nil
  end
end

def items_contained a # task server side
  ret = []
  lista = [a]
  unit = a.quantity_unit
  suma = unit*0
  while not lista.empty?
    item = lista.pop()
    items = contains item
    if items
      lista += items
    end
    unit_ = item.quantity_unit
    if unit_ != unit
      ret.push suma
      suma = item.quantity
      unit = unit_
    else
      suma += item.quantity
    end
  end
  ret.push suma
  ret
end


class FungibleContainer < AbstractContainerThing
  def initialize(code, quantity_unit, quantity=0)
    super code, quantity_unit=quantity_unit
  end
end


class Container < AbstractContainerThing
  def initialize(code, quantity_unit)
    super code, quantity_unit=quantity_unit
  end

  def quantity
    @quantity_unit * ContainsRelationCollection.where({klass_a: self.class.to_s, a_id: self.object_id, end_: nil}).size()
  end
end

class Thing < AbstractThing
  def initialize(code)
    super code=code
  end
end


class ContainsRelation < Model
  def initialize(klass_a, a_id, klass_b, b_id, ini=Time.now, end_=nil)
    super()
    @a = nil
    @b = nil
    @klass_a = klass_a
    @a_id = a_id
    @klass_b = klass_b
    @b_id = b_id
    @ini  = ini
    @end = end_
  end

  def resolve
    collection = Object.const_get(@klass_a+'Collection')
    collection.where({_id: @a_id}).then do |x|
      @a = x
    end
    collection = Object.const_get(@klass_b+'Collection')
    collection.where({_id: @b_id}).then do |x|
      @b = x
      puts '>>', @klass_a, 'contains', @klass_b
    end
  end

  def finish(end_=Time.now)
    @end = end_
    puts '>> finish', @klass_a, 'contains', @klass_b
  end

end

#######################################################


class Zona < FixedContainer
  def initialize(code)
    super(code, quantity_unit=$estante)
  end
end


class Estante < FixedContainer
  def initialize(code)
    super(code, quantity_unit=$caja)
  end
end


class Caja <MobileContainer
  def initialize(code)
    super(code, quantity_unit=$botella)
  end
end

class Botella < MobileContainer
  def initialize(code)
    super code, @quantity_unit=$liter, @quantity=Measurement.parse('0.5 l')
  end
end

zona_a = Zona.new('Z-A')
zona_b = Zona.new('Z-B')

estante_1 = Estante.new('E-1')
caja1 = Caja.new('C-1')
caja2 = Caja.new 'C-2'
botella1 = Botella.new('B-3')
zona_a.contains(estante_1)
estante_1.contains(caja1)
estante_1.contains(caja2)
caja1.contains(botella1)


puts 'containers:', botella1.containers
puts 'items:', zona_a.items_contained

caja2.contains(botella1)

txt = caja1.class.to_s
c = Object.const_get(txt).new 'C-111'
puts c