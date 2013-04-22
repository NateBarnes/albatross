require "redis"

# id 	limit
# 1 	1000
# 2 	10000
# 3 	100000
# 4 	1000000
# 5 	10000000
# 6 	100000000
# 7 	1000000000

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
