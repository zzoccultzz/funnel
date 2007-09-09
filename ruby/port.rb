require 'funneldefs'

module Funnel
  class Port
    attr_reader :direction
    attr_reader :type
    attr_reader :maximum
    attr_reader :minimum
    attr_reader :average

    def initialize(id, type)
      @from_id = id

      case type
      when PORT_AIN
        @direction = PortDirection::INPUT
        @type = PortType::ANALOG
      when PORT_DIN
        @direction = PortDirection::INPUT
        @type = PortType::DIGITAL
      when PORT_AOUT
        @direction = PortDirection::OUTPUT
        @type = PortType::ANALOG
      when PORT_DOUT
        @direction = PortDirection::OUTPUT
        @type = PortType::DIGITAL
      else
        raise ArgumentError, "unknown type: #{type}"
      end
      
      @value = 0.0
      @filters = []
      @maximum = 0.0
      @minimum = 1.0
      @average = 0.0
      @sum = 0.0
      @samples = 0
      @on_change_listeners = []
      @on_rising_edge_listeners = []
      @on_falling_edge_listeners = []
    end

    def value
      return @value
    end

    def value=(new_value)
      update(new_value)
    end

    def update(new_value)
      last_value = @value
      @value = apply_filters(new_value)
      @maximum = @value if @value > @maximum
      @minimum = @value if @value < @minimum
      @sum = @sum + @value
      @samples = @samples + 1
      @average = @sum / @samples.to_f
      detect_edge(last_value, @value)
    end

    def clear
      @maximum = @minimum = @sum = @value
      @samples = 1
    end

    def filters
      return @filters
    end

    def filters=(filters)
      @filters.each do |filter|
        filter.set_listener nil if filter.is_a? Generator
      end

      if filters.is_a? Array then
        filters.each do |filter|
          filter.set_listener { |val| self.value=(val) } if filter.is_a? Generator
          @filters << filter
        end
      elsif filters.is_a? Filter then
        filters.set_listener { |val| self.value=(val) } if filters.is_a? Generator
        @filters << [filters]
      else
        raise ArgumentError, "wrong argument for filters ="
      end
    end

    def detect_edge(last_value, current_value)
      return if last_value == current_value

      @on_change_listeners.each do |proc|
        proc.call(Event.new(Event::CHANGE, @from_id, last_value, current_value))
      end

      if (last_value == 0) and (current_value != 0) then
        @on_rising_edge_listeners.each do |proc|
          proc.call(Event.new(Event::RISING_EDGE, @from_id, last_value, current_value))
        end
      elsif (last_value != 0) and (current_value == 0) then
        @on_falling_edge_listeners.each do |proc|
          proc.call(Event.new(Event::FALLING_EDGE, @from_id, last_value, current_value))
        end
      end
    end

    def apply_filters(value)
      result = value
      return result if (@filters == nil) or (@filters.size == 0)

      @filters.each do |filter|
        if filter.is_a? Generator then
          filter.update() if not filter.auto_update
          result = filter.value
        elsif filter.is_a? Filter then
          result = filter.process_sample(result)
        end
      end
      return result
    end

    def add_event_listener(type, &proc)
      case type
      when Event::CHANGE
        @on_change_listeners << proc
      when Event::RISING_EDGE
        @on_rising_edge_listeners << proc
      when Event::FALLING_EDGE
        @on_falling_edge_listeners << proc
      else
        raise ArgumentError, "unknown event type: #{type}"
      end
    end
  end
end
