require 'time'

module WorkFlow

  class Model

  end

  class AbstractThing < Model
    attr_reader :code

    def initialize(code)
      super()
      @code = code
    end
  end

  class AbstractContainerThing < AbstractThing
    def initialize(code, quantity_unit, quantity=0)
      super code

      @full_quantity = []
      @quantity_unit = quantity_unit
      if quantity == 0
        @quantity = quantity_unit * quantity
      else
        @quantity = quantity
      end
    end
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
  end

  class Thing < AbstractThing
  end

  class ContainsRelation < Model
    def initialize(thing_cls, thing_code, container_cls, container_code, ini=Time.now, end_=nil)
      super()
      @thing_cls = thing_cls
      @thing_code = thing_code
      @container_cls = container_cls
      @container_code = container_code
      @ini  = ini
      @end = end_
    end
  end

  # server side
  def is_contained_in thing_cls, thing_code
    ret = []
    rel = ContainsRelationCollection.where(thing_cls: thing_cls, thing_code: thing_code, end_: nil)
    while rel
      thing = Object.const_get(rel.thing_cls+'Collection').where(_id: rel.thing_code)
      ret.push(thing)
      rel = is_contained_in rel.container_cls, rel.container_code
    end
    ret
  end

  # server side
  def contains container
    ret = []
    rels = ContainsRelationCollection.where(container_cls: container.class.to_s, container_code: container_code, end_: nil)
    for rel in rels:
      thing = Object.const_get(rel.thing_cls+'Collection').where(_id: rel.thing_code)
      ret.push(thing)
    end
    ret
  end

  # server side
  def compute_items_contained container
    container.full_quantity = []
    lista = [container]
    unit = container.quantity_unit
    suma = unit*0
    while not lista.empty?
      item = lista.pop()
      items = contains item
      if items
        lista += items
      end
      unit_ = item.quantity_unit
      if unit_ != unit
        container.full_quantity.push suma
        suma = item.quantity
        unit = unit_
      else
        suma += item.quantity
      end
    end
    container.full_quantity.push suma
    container.save
  end



  #task
  def movement(thing_cls, thing_code, container_cls, container_code, ini=Time.now)
    rel = ContainsRelationCollection.where({thing_cls: thing_cls, thing_code: thing_code, end_: nil})
    rel.end_ = ini
    rel.save
    old_container_cls = rel.container_cls
    old_container_code = rel.container_code
    rel = ContainsRelation.new(thing_cls=thing_cls, thing_code=thing_code, container_cls=container_cls,
                               container_code=container_code, ini=ini)
    rel.save
    old_path = is_contained_in old_container_cls, old_container_code
    new_path = is_contained_in container_cls, container_code
    done = []
    for container in old_path + new_path
      if done.include? container
        next
      end
      done.push container
      compute_items_contained container
    end
    nil
  end
end

