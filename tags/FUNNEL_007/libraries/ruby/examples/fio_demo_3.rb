#!/usr/bin/env ruby
$: << '..'

require 'funnel'

# wait for multiple nodes to get sensor values and control outputs
module Funnel
  fio = Fio.new(nil, 'localhost', 9000, 50, true)
  fio.wait_for_nodes(2)

  modules = []
  fio.all_io_modules.each_index do |i|
    modules[i] = fio.all_io_modules[i].id
  end

  raise "can't find two or more nodes" if modules.length < 2

  # go round all nodes 5 times
  (modules.length * 5).times do |i|
    5.times do
      fio.all_io_modules.each do |io|
        current = i % modules.length
        io.port(10).value = (io.id == modules[current]) ? 1.0 : 0.0
      end
      sleep(0.1)
    end
  end
end