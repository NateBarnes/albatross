require 'bundler/setup'
Bundler.require

EventMachine.set_max_timers 1_250_000
EventMachine.threadpool_size = 50_000

DB = Redis.new
DB.set :connections, 0

module FormatHelper
  def humanize_number n
    n.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, '\\1,')
  end
  module_function :humanize_number
end

class Reservation
  include EM::Deferrable
  attr_accessor :opts

  def initialize opts
    @opts = opts
  end

  def get_reg
    puts "in worker"
    reg_num = 1
    event_num = 0
    while event_num == 0
      registrations_left = DB.decr "event:#{reg_num}:limit"
      if registrations_left < 0
        DB.incr "event:#{reg_num}:limit"
        reg_num +=1
        reg_num = 0 and break if reg_num > 7
      else
        event_num = reg_num
      end
    end
    @opts[:stream] << "event:\"#{reg_num}\""
    @opts[:reg_num] = reg_num
    set_deferred_status :failed if reg_num > 7
    succeed(@opts)
  end
end

class PostReservation
  include EM::Deferrable
  attr_accessor :opts

  def initialize opts
    @opts = opts
  end

  def get_reg_callback
    EM.defer do
      price = DB.get "event:#{@opts[:reg_num]}:price"
      @opts[:stream] << ", price:\"#{price}\""
    end

    EM.defer do
      desc = DB.get "event:#{@opts[:reg_num]}:desc"
      @opts[:stream] << ", desc:\"#{desc}\""
    end
  end
end

class App < E
  map '/'

  # index and status_watcher actions should return event-stream content type
  before :event, :status_watcher do
    content_type 'text/event-stream'
  end

  def index
    stream :keep_open do |stream|

      stream.errback do      # when connection closed/errored:
        DB.decr :connections # 1. decrement connections amount by 1
      end
      
      # increment connections amount by 1
      DB.incr :connections
      puts "setting up worker"
      worker = Reservation.new(:stream => stream)
      puts "setting callbacks"
      worker.callback { |opts| PostReservation.new(opts).get_reg_callback }
      puts "starting reg"
      worker.get_reg
    end
  end

  # frontend for status watchers - http://localhost:5252/status
  def status
    render
  end

  # backend for status watchers
  def status_watcher
    stream :keep_open do |stream|
      # adding a timer that will update status watchers every second
      timer = EM.add_periodic_timer(1) do
        connections = FormatHelper.humanize_number(DB.get :connections)
        stream << "data: %s\n\n" % connections
      end
      stream.errback { timer.cancel } # cancel timer if connection closed/errored
    end
  end

  def get_ping
  end
end
