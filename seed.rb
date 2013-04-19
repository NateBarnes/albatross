require "redis"

events = []

7.times do |i|
	i+=1
	limit = 100 * 10**i
	events << {id:i, limit: limit, desc:"event #{i} with limit of #{limit}", price:limit/100 }
end

DB = Redis.new
events.each do |event|
	id = event.delete :id
	event.each do |key, value|
		DB.set "event:#{id}:#{key}", "#{value}"
	end
end
