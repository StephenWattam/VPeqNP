#!/usr/bin/env ruby

Dir.glob("./lib/*.rb").each{|x|
  require x
}



# -----------------------------------------------------------------------------
tz = VPNP::RegexTokeniser.new() # default options for now
ts = VPNP::TokenSource.new(File.open('./resources/pos.train.txt'), tz)
out = VPNP::SimpleOutputFormatter.new()

# x = ts.next
# while(x = x.next)
#   out.output(x)
# end


# -----------------------------------------------------------------------------

c = VPNP::Corpus.new("/tmp/wotever")

while(x = ts.next)
  c.inc_word_type(x)
  
  #   out.output(x)
end



