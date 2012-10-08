#!/usr/bin/env ruby

Dir.glob("./lib/*.rb").each{|x|
  require x
}


out = VPNP::SimpleOutputFormatter.new()

# -----------------------------------------------------------------------------
# Training
tz = VPNP::RegexTokeniser.new(VPNP::RegexTokeniser::WORD_TAG_RX) # word tag word tag word tag
ts = VPNP::TokenSource.new(File.open('./resources/pos.train.txt'), tz)

# x = ts.next
# while(x = x.next)
#   out.output(x)
# end

c = VPNP::Corpus.new
c.add_all(ts)



# -----------------------------------------------------------------------------
# Testing
# tz = VPNP::RegexTokeniser.new(VPNP::RegexTokeniser::WORD_RX)  # Word regex, no tags
tz = VPNP::RegexTokeniser.new(VPNP::RegexTokeniser::WORD_TAG_RX)  # with tags 
ts = VPNP::TokenSource.new(File.open('./resources/pos.test.txt'), tz)

# Create a new model
model = VPNP::SimpleProbabalisticTagModel.new(c)

success = 0
count = 0
while(x = ts.next)
  puts "INPUT: #{x.word}"
  puts "Times seen: #{c.get_word_freq(x)} / #{c.get_total}, #{c.get_type_count(x)} seen as type #{x.type}"
  puts "Tags seen: #{c.get_types(x)}"
  puts "P(this type) = #{model.p_observed_type(x)}"
  puts "My naive estimate: #{model.naive_estimate_type(x)}"
  success += 1 if model.naive_estimate_type(x) == x.type
  puts "My contextual estimate: #{model.context_estimate_type(x)}"
  out.output(x)
  count += 1
end


puts "SUCCESS: #{success}/#{count} (#{((success.to_f/count)*100).round(2)}%)"
