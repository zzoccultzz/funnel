#!/usr/bin/env ruby

require 'socket'
require 'timeout'
require 'yaml'
require 'rbconfig'

require 'osc'
require 'gainer_io'

class FunnelServer

  PORT_DIRECTION_I = 0
  PORT_DIRECTION_O = 1
  PORT_TYPE_A = 0
  PORT_TYPE_D = 1

  PORT_AIN = 0
  PORT_DIN = 1
  PORT_AOUT = 2
  PORT_DOUT = 3

  QUIT_SERVER       = '/quit'
  RESET             = '/reset'
  POLLING           = '/polling'
#  QUERY            = '/query'
  CONFIGURE         = '/configure'
  SAMPLING_INTERVAL = '/samplingInterval'
  SET_OUTPUTS       = '/out'
  GET_INPUTS        = '/in'

  NO_ERROR            = 0
  ERROR               = 1
  REBOOT_ERROR        = 2
  CONFIGURATION_ERROR = 3

  def initialize(port, com)
    @server = TCPServer.open(port)
    puts "server: #{@server.addr.at(2)}, #{@server.addr.at(1)}"
    @notifier = TCPServer.open(port + 1)
    puts "notifier: #{@notifier.addr.at(2)}, #{@notifier.addr.at(1)}"

    @queue = Queue.new
    @clients = []
    @ain = [0, 0, 0, 0]
    @button = 0

    devices = []

    if com == nil then
      case Config::CONFIG["target_os"].downcase
      when 'darwin8.0'
        # i.e. Mac OS X
        Dir.foreach('/dev') do | deviceName |
          devices.push('/dev/' + deviceName) if (deviceName.index("cu.usbserial") == 0)
        end

        if (devices.size < 1) then
          raise "Can't find any I/O modules..."
        end
      else
        # i.e. Windows: Should be replaced this section with more better implementation...
        puts "please enter COM port number (e.g. '4' for 'COM4')"
        STDOUT.flush
        port_number = gets
        port_number.chomp!
        devices = ["COM#{port_number.to_i}"]
      end
    end

    @configuration = [
        [PORT_DIRECTION_I, PORT_TYPE_A],
        [PORT_DIRECTION_I, PORT_TYPE_A],
        [PORT_DIRECTION_I, PORT_TYPE_A],
        [PORT_DIRECTION_I, PORT_TYPE_A],
        [PORT_DIRECTION_I, PORT_TYPE_D],
        [PORT_DIRECTION_I, PORT_TYPE_D],
        [PORT_DIRECTION_I, PORT_TYPE_D],
        [PORT_DIRECTION_I, PORT_TYPE_D],
        [PORT_DIRECTION_O, PORT_TYPE_A],
        [PORT_DIRECTION_O, PORT_TYPE_A],
        [PORT_DIRECTION_O, PORT_TYPE_A],
        [PORT_DIRECTION_O, PORT_TYPE_A],
        [PORT_DIRECTION_O, PORT_TYPE_D],
        [PORT_DIRECTION_O, PORT_TYPE_D],
        [PORT_DIRECTION_O, PORT_TYPE_D],
        [PORT_DIRECTION_O, PORT_TYPE_D],
        [PORT_DIRECTION_O, PORT_TYPE_D],  # LED
        [PORT_DIRECTION_I, PORT_TYPE_D],  # Button
      ]

    @gio = GainerIO.new(devices.at(0), 38400)
    @gio.onEvent = method(:event_handler)
    reboot_io_module
    STDOUT.flush
  end

  def event_handler(type, values)
    if (type == GainerIO::AIN_EVENT) then
      i = 0
      values.each do |value|
        @ain[i] = value / 255.0
        i += 1
      end
      @queue.push([0, @ain])
    elsif (type == GainerIO::BUTTON_EVENT) then
      puts "button: #{values}"
      STDOUT.flush
      @button = values.at(0)
      @queue.push([17, [@button]])      
    else
      puts "#{type}: #{value}"
      STDOUT.flush
    end
  end
  
  def reboot_io_module
    puts @gio.reboot
    puts @gio.getVersion
    puts @gio.setConfiguration(1)
  end

def send_notify(message)
  return
  @clients.each do |client|
    result = client.send(message.encode, 0)
  end
end

def add_method(callbacks, pat, obj=nil, &proc)
  case pat
  when NIL; re = pat
  when Regexp; re = pat
  when String
    pat = pat.dup
    pat.gsub!(/[.^(|)]/, '\\1')
    pat.gsub!(/\?/, '[^/]')
    pat.gsub!(/\*/, '[^/]*')
    pat.gsub!(/\[!/, '[^')
    pat.gsub!(/\{/, '(')
    pat.gsub!(/,/, '|')
    pat.gsub!(/\}/, ')')
    pat.gsub!(/\A/, '\A')
    pat.gsub!(/\z/, '\z')
    re = Regexp.new(pat)
  else
    raise ArgumentError, 'invalid pattern'
  end

  unless ( obj && !proc) ||
    (!obj &&  proc)
    raise ArgumentError, 'wrong number of arguments'
  end
  callbacks << [re, (obj || proc)]
end

def handle_message(callbacks, message)
  callbacks.each do |re, obj|
    if re.nil? || re =~ message.address
      obj.send(if Proc === obj then :call else :accept end, message)
    end
  end
end

def client_watcher
  loop do
    Thread.start(@server.accept) do |client|
      puts "server: connected: #{client}"
      STDOUT.flush

      callbacks = []

      add_method(callbacks, QUIT_SERVER) do |message|
        puts "quit requested"
        STDOUT.flush
        @gio.endAnalogInput
        reply = OSC::Message.new(QUIT_SERVER, 'i', NO_ERROR)
        client.send(reply.encode, 0)
        exit
      end

      add_method(callbacks, RESET) do |message|
        puts "reset requested"
        STDOUT.flush
        reboot_io_module
        reply = OSC::Message.new(RESET, 'i', NO_ERROR)
        client.send(reply.encode, 0)
      end

      add_method(callbacks, POLLING) do |message|
        if message.to_a.at(0) == 1 then
          puts "begin polling requested"
          STDOUT.flush
          @gio.beginAnalogInput
          @gio.startPolling
        elsif message.to_a.at(0) == 0 then
          puts "end polling requested"
          STDOUT.flush
          @gio.finishPolling
          @gio.endAnalogInput
        else
          puts "invalid value: #{message.to_a.at(0)}"
          STDOUT.flush
          reply = OSC::Message.new(POLLING, 'i', ERROR)
          client.send(reply.encode, 0)
          return
        end
        reply = OSC::Message.new(POLLING, 'i', NO_ERROR)
        client.send(reply.encode, 0)
      end

#      add_method(callbacks, QUERY) do |message|
#        oscMessages = []
#        @configuration.size.times do |i|
#          oscMessages[i] = OSC::Message.new('/query/' + i.to_s, 'ii', *@configuration.at(i))
#        end
#
#        reply = OSC::Bundle.new(nil, *oscMessages)
#        client.send(reply.encode, 0)
#      end

      add_method(callbacks, CONFIGURE) do |message|
        puts "configuration requestd"
        i = 0
        message.to_a.each do |porttype|
          puts "port #{i}: #{porttype}"
          i += 1
        end
        STDOUT.flush
        reply = OSC::Message.new(CONFIGURE, 'i', NO_ERROR)
        client.send(reply.encode, 0)
      end

      add_method(callbacks, SAMPLING_INTERVAL) do |message|
        puts "sampling interval: #{message.to_a} ms"
        STDOUT.flush
        reply = OSC::Message.new(SAMPLING_INTERVAL, 'i', NO_ERROR)
        client.send(reply.encode, 0)
      end

      add_method(callbacks, SET_OUTPUTS) do |message|
        @gio.setOutputs(message.to_a)
        reply = OSC::Message.new(SET_OUTPUTS, 'i', NO_ERROR)
        client.send(reply.encode, 0)
      end

      add_method(callbacks, GET_INPUTS) do |message|
        from = message.to_a.at(0)
        ports = message.to_a.at(1)
        if (0 <= from and from < 4) then
          values = @ain[from, ports]
          return if values == nil
          reply = OSC::Message.new(GET_INPUTS, 'i' + 'f' * values.size, 0, *values)
          client.send(reply.encode, 0)
        elsif (from == 17 and ports == 1) then
          reply = OSC::Message.new(GET_INPUTS, 'if', 17, @button)
          client.send(reply.encode, 0)
        end
      end

      while true
        packet = client.recv(16384)   # blocking read
        break if packet == ""         # "" means EOF for TCP connection

        begin
          OSC::Packet.decode(packet).each do |time, message|
            handle_message(callbacks, message)
          end
        rescue EOFError
        end
      end

      puts "server: disconnected: #{client}"
      STDOUT.flush
      client.close
    end
  end
end

def notify_service
  socks = [@notifier]

  Thread.new do
    loop do
      from, inputs = @queue.pop
      for s in socks
        if s != @notifier then
          message = OSC::Message.new('/in', 'i' + 'f' * inputs.size, from, *inputs)
          s.send(message.encode, 0)
        end
      end
    end
  end

  Thread.new do
    loop do
      nsock = select(socks)
      next if nsock == nil
      for s in nsock[0]
        if s == @notifier
          client = s.accept
          socks.push(client)
          puts "notifier: connected: #{client}"
          STDOUT.flush
        elsif s.eof?
          puts "notifier: disconnected: #{client}"
          STDOUT.flush
          s.close
          socks.delete(s)
        end
      end
    end
  end
end

def run
  begin
    notify_service
  rescue
    Thread.main.raise $!
  end

  begin
    client_watcher
  rescue
    Thread.main.raise $!
  end
end

end


# load setting from the setting file
settings = YAML.load_file('settings.yaml')
p settings
port = settings["port"]
com = settings["com"]
port = 9000 if port == nil

# instantiate the FunnelServer and set to run
server = FunnelServer.new(port, com)
server.run
