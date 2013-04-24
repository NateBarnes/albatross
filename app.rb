require 'bundler/setup'
require "em-synchrony"
require "em-http-request"
Bundler.require

EventMachine.set_max_timers 1_250_000

DB = Redis.new
DB.set :connections, 0

module FormatHelper
  def humanize_number n
    n.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, '\\1,')
  end
  module_function :humanize_number
end

class App < E
  map '/'

  before :index, :status_watcher do
    content_type 'text/event-stream'
  end

  def index
    stream :keep_open do |stream|

      stream.errback do
        DB.decr :connections
      end

      DB.incr :connections

      EM.add_timer(1) do
        reg_num = 1
        event_num = 0
        while event_num == 0
          registrations_left = DB.decr "event:#{reg_num}:limit"
          if registrations_left < 0
            DB.incr "event:#{reg_num}:limit"
            reg_num +=1
          else
            event_num = reg_num
            DB.incr "event:#{reg_num}:issued"
            reservation_num = DB.incr(:reservations)
            DB.set("reservation:#{reservation_num}", event_num)
            DB.expire("reservation:#{reservation_num}", 600)
          end
        end

        stream << "event:\"#{reg_num}\""

        price_call = EM::HttpRequest.new("http://www.example.com").get
        price_call.callback { stream << ", price:\"#{DB.get("event:#{reg_num}:price")}\"" }

        desc_call = EM::HttpRequest.new("http://www.example.com").get
        desc_call.callback { stream << ", desc:\"#{DB.get("event:#{reg_num}:desc")}\"" }
      end
    end
  end

  def register reservation_num, aus_id
    stream :keep_open do |stream|

      stream.errback do
        DB.decr :connections
      end

      DB.incr :connections

      EM.add_timer(1) do
        event_num = DB.get("reservation:#{reservation_num}")
        if event_num
          DB.lpush "event:#{event_num}:registrations", aus_id
          stream << "event_num: #{event_num}"
        end
      end
    end
  end

  def status
    render
  end

  def status_watcher
    stream :keep_open do |stream|
      timer = EM.add_periodic_timer(1) do
        connections = FormatHelper.humanize_number(DB.get :connections)
        stream << "data: %s\n\n" % connections
      end
      stream.errback { timer.cancel }
    end
  end

  def get_ping
  end
end
