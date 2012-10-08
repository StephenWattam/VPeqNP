#!/usr/bin/env ruby

Dir.glob("./lib/*.rb").each{|x|
  require x
}



tz = VPNP::RegexTokeniser.new() # default options for now
ts = VPNP::TokenSource.new(File.open('./resources/pos.train.txt'), tz)

while(x = ts.next)
  x = ts.next
  puts "#{x}"
end
