#!/usr/bin/env ruby -wKU

require "funnel/iosystem"

module Funnel
  class Fio < IOSystem
    include IPAppletAdapter if defined? IRP

    ALL = IOSystem::ALL

    @@FIRMATA = Configuration.new(Configuration::FIO)
    
    def self.FIRMATA
      return @@FIRMATA
    end

    def initialize(arguments)
      # default values
      nodes = nil
      host = '127.0.0.1'
      port = 9000
      interval = 33
      autoregister = false
      @config = @@FIRMATA

      if arguments != nil then
        nodes = arguments[:nodes] unless arguments[:nodes] == nil
        host = arguments[:host] unless arguments[:host] == nil
        port = arguments[:port] unless arguments[:port] == nil
        interval = arguments[:interval] unless arguments[:interval] == nil
        autoregister = arguments[:autoregister] unless arguments[:autoregister] == nil
        @config = arguments[:config] unless arguments[:config] == nil
        applet = arguments[:applet]
      end

      super(nil, host, port, interval, applet)
      @autoregister = autoregister
      @broadcast = IOModule.new(self, ALL, @config, "broadcast", true)
      nodes = [] if nodes == nil
      nodes.each do |id|
        register_node(id, "")
      end
    end
    
    def register_node(id, ni = "")
      add_io_module(id, @config, ni, false)
    end
    
    def wait_for_nodes(number)
      50.times do
        break if @modules.length >= number
        sleep(0.1)
      end

      all_io_modules.each do |io|
        puts "fio: id: #{io.id}, name: #{io.name}"
      end
    end
  end
end