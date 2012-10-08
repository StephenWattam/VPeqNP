#!/usr/bin/env ruby

Dir.glob("./lib/*.rb").each{|x|
  require x
}


out = VPNP::SimpleOutputFormatter.new()

brown = Dir.glob("./resources/brown/c*")
brown.map!{|x| File.open(x)}
brown_testing = brown[0..10]
brown_training = brown[11..-1]

WORD_TAG_BROWN = /(?<start>)(?<word>\w+)\/(?<tag>[a-z\.,]+)(?<end>)/


# -----------------------------------------------------------------------------
# Training
tz = VPNP::RegexTokeniser.new(WORD_TAG_BROWN) # word tag word tag word tag

# ts = VPNP::TokenSource.new(File.open('./resources/pos.train.txt'), tz)

ts = VPNP::TokenSource.new(brown_training, tz)

# x = ts.next
# while(x = ts.next)
#   # out.output(x)
# end

c = VPNP::Corpus.new
c.add_all(ts)



# -----------------------------------------------------------------------------
# Testing
# tz = VPNP::RegexTokeniser.new(VPNP::RegexTokeniser::WORD_RX)  # Word regex, no tags
# ts = VPNP::TokenSource.new(File.open('./resources/pos.test.txt'), tz)
ts = VPNP::TokenSource.new(brown_testing, tz)

# Create a new model
model = VPNP::SimpleProbabalisticTagModel.new(c)

success = 0
count = 0

last = nil
while(x = ts.next)
  puts "\nINPUT: #{x.word}/#{x.string.gsub("\n",'')}/#{x.lemma}"
  puts "  | Times seen: #{c.get_word_freq(x)} / #{c.get_total}, #{c.get_type_count(x)} seen as type #{x.type}"
  puts "  | Tags seen: #{c.get_types(x)}"
  puts "  | P(this type) = #{model.p_observed_type(x)}"
  puts "  | My naive estimate: #{model.naive_estimate_type(x)}"
  success += 1 if model.context_estimate_type(x) == x.type
  puts "  | My contextual estimate: #{model.context_estimate_type(x)}"
  puts "  | P(x.type | x.prev.type): #{model.p_type_transition(x.prev, x)}"
  count += 1
end


puts "SUCCESS: #{success}/#{count} (#{((success.to_f/count)*100).round(2)}%)"
