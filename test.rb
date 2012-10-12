#!/usr/bin/env ruby

Dir.glob("./lib/*.rb").each{|x|
  require x
}

# output formatting
out = VPNP::SimpleOutputFormatter.new()

# Partition brown into testing/training sets
brown = Dir.glob("./resources/brown/c*")
brown.map!{|x| File.open(x)}
brown_testing = brown[0..10]
brown_training = brown[11..-1]

# And make a tagger pattern/tokeniser for it
WORD_TAG_BROWN = /(?<start>)(?<word>\w+)\/(?<tag>[a-z\.,]+)(?<end>)/
tz = VPNP::RegexTokeniser.new(WORD_TAG_BROWN) # word tag word tag word tag


# -----------------------------------------------------------------------------
# Training
#ts = VPNP::TokenSource.new(File.open('./resources/pos.train.txt'), tz)
#ts = VPNP::TokenSource.new(brown_training, tz)

# x = ts.next
# while(x = ts.next)
#   # out.output(x)
# end

#c = VPNP::Corpus.new
#c.add_all(ts)

# -----------------------------------------------------------------------------
# Save and load the corpus
#c.save("./testing/test_corpus")
c = VPNP::Corpus.load("./testing/test_corpus")

# -----------------------------------------------------------------------------
# Testing
#tz = VPNP::RegexTokeniser.new(VPNP::RegexTokeniser::WORD_RX)  # Word regex, no tags
#ts = VPNP::TokenSource.new(File.open('./resources/pos.test.txt'), tz)
ts = VPNP::TokenSource.new(brown_testing, tz)

# dumbrules = VPNP::RuleSet.new
# dumbrules.add_rule(lambda {|token, type, p| 
# #                puts "Word: #{token.string} Type: #{type} Prob: #{p}"
#                 if token.string[0] == token.string.upcase[0]
#                     if type == "np"
#                       return p*5
#                     else
#                       return p*0.1
#                     end
#                 else
#                   return p
#                 end
#               })

# Create a new model
simple        = VPNP::SimpleProbabalisticTagModel.new (c)
simpleruled   = VPNP::SimpleProbabalisticTagModel.new (c)
hmm           = VPNP::MarkovTagModel.new              (c)
beff          = VPNP::BestEffortTagModel.new          (c)


def test_model(c, tm, ts)
  # quick counts
  success = 0
  count = 0
  while(x = ts.next)
    original_type = x.type

    tm.estimate_type(x)
    # overly verbose debug info
    puts "\nINPUT: #{x.word} || #{x.string.gsub("\n",'')} || #{x.lemma}"
    puts "  | Times seen: #{c.get_word_freq(x)} / #{c.get_total}, #{c.get_type_count(x)} seen as type #{x.type}"
    puts "  | Tags seen: #{c.get_types(x)}"
    # puts "  | P(this type) = #{tm.p_observed_type(x)}"
    puts "  | Weights: #{tm.estimates(x)}"
    puts "  | My estimate: #{tm.estimate_type(x)}"
    # puts "  | P(x.type | x.prev.type) = P(#{x.type}|#{(x.prev)? x.prev.type : '?'}): #{tm.p_type_transition(x.prev, x)}"
   
    # Accounting
    count += 1
    success += 1 if original_type == x.type
  end


  puts "#{tm.class}: #{success}/#{count} (#{((success.to_f/count)*100).round(2)}%)"
end

test_model(c, beff, ts)

msg = "This is a green sample message that remains untagged and enjoys eating horse flesh out of an elevator."
puts msg
puts msg.tag( beff, out )
