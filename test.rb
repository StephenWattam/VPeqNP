#!/usr/bin/env ruby

Dir.glob("./lib/*.rb").each{|x|
  require x
}




# output formatting
out = VPNP::SimpleOutputFormatter.new()

# Define the input source
brownsource = "resources/brown/c*"

# And make a tagger pattern/tokeniser for it
WORD_TAG_BROWN = /(?<start>)(?<word>\w+)\/(?<tag>[a-z\.,]+)(?<end>)/
tz = VPNP::RegexTokeniser.new(WORD_TAG_BROWN) # word tag word tag word tag

# -----------------------------------------------------------------------------
# Training
#Build a corpus from the training data and tokeniser.
ts = VPNP::DirTokenSource.new(brownsource, 11, 15, tz)
c = VPNP::Corpus.new
c.add_all(ts)

# Save or load the corpus for speed
c.save("./testing/test_corpus")
#c = VPNP::Corpus.load("./testing/test_corpus")

# -----------------------------------------------------------------------------
# Create a new model
simple        = VPNP::SimpleProbabalisticTagModel.new (c)
hmm           = VPNP::MarkovTagModel.new              (c)
morph         = VPNP::MorphologicalRuleTagModel.load('./testing/test_rules.yml')
# morph         = VPNP::MorphologicalRuleTagModel.new( { /.*ly$/ => 'adv',
#                                                        /.*ing$/ => 'vb',
#                                                        /a/ => 'at2',
#                                                        /^a[nt]$/ => 'at',
#                                                        /^th(e(re)?|a[nt])$/ => 'at'
#                                                       } )

rules         =   { /.*ly$/ => 'adv',
                   /.*ing$/ => 'vb',
                   /a/ => 'at2',
                   /^a[nt]$/ => 'at',
                   /^th(e(re)?|a[nt])$/ => 'at'
                  }
hybr          = VPNP::SimpleHybridModel.new(c,rules)
weighted      = VPNP::WeightedTagModel.new( simple => 1, morph => 2 )
grammar       = VPNP::GrammarRuleTagModel.load('./testing/grammar_rules.yml')
trained       = VPNP::TrainedWeightTagModel.new( simple, hmm, morph, grammar )

# -----------------------------------------------------------------------------
# Testing
# XXX: The input source gets 'used up' by the tokensource - I couldn't see what 
# caused this to add a 'reset' in the TokenSource. 
#  --- It's part of the IO system (file pointer).  Multiple files makes this hard.
#      I'll work on it later - SW 13-10-12

def summary(t, tm)
  t = t.next if t.is_a? VPNP::TokenSource

  # Keep count and progress through tokens.
  n, s, c = 0, 0, 0
  while(t) do

    # Make a note of, and wipe, the type assigmnent
    original = t.type
    t.type = nil

    # Estimate type
    tm.estimate_type(t)

    # Check and count
    s += 1 if t.type == original
    n += 1 if t.type 
    c += 1

    # Progress to next token
    t = t.next
  end

  puts "\nModel: #{tm.class}"
  puts "Tokens: #{n}/#{s}/#{c} (#{((n.to_f/c)*100).round(2)}/#{((s.to_f/c)*100).round(2)}%) [tagged/correct/total]"
end

ts = VPNP::DirTokenSource.new(brownsource, 0, 10, tz)
# Train the weights
# FIXME: this is using testing data.  Not entirely crucial but also not ideal for accuracy
while(x = ts.next)
  trained.train(x)
end
trained.models.each{|m, w|
  puts "Model: #{m} = #{w}"
}
ts.reset


summary(ts, grammar)
ts.reset
summary(ts, simple)
ts.reset
summary(ts, hmm)
ts.reset
summary(ts, morph)
ts.reset
summary(ts, weighted)
ts.reset
summary(ts, trained)
