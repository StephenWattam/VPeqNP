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
#ts = VPNP::DirTokenSource.new(brownsource, 11, -1, tz)
#c = VPNP::Corpus.new
#c.add_all(ts)

# Save or load the corpus for speed
#c.save("./testing/test_corpus")
c = VPNP::Corpus.load("./testing/test_corpus")

# -----------------------------------------------------------------------------
# Create a new model
simple        = VPNP::SimpleProbabalisticTagModel.new (c)
hmm           = VPNP::MarkovTagModel.new              (c)
beff          = VPNP::BestEffortTagModel.new          (c)
morph         = VPNP::MorphologicalRuleTagModel.new( { /.*ly$/ => 'adv',
                                                       /.*ing$/ => 'vb',
                                                       /a/ => 'at2',
                                                       /^a[nt]$/ => 'at',
                                                       /^th(e(re)?|a[nt])$/ => 'at'
                                                      } )

# -----------------------------------------------------------------------------
# Testing
# XXX: The input source gets 'used up' by the tokensource - I couldn't see what 
# caused this to add a 'reset' in the TokenSource.
ts = VPNP::DirTokenSource.new(brownsource, 0, 10, tz)
puts "BEFF: #{beff.evaluate(ts).round(2)}%"
ts = VPNP::DirTokenSource.new(brownsource, 0, 10, tz)
puts "Simple: #{simple.evaluate(ts).round(2)}%"
ts = VPNP::DirTokenSource.new(brownsource, 0, 10, tz)
puts "Morph: #{morph.evaluate(ts).round(2)}%"
