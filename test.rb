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

# =============================================================================
# Training
#Build a training corpus from the training data and tokeniser.
puts "Building training corpus..."
ts = VPNP::DirTokenSource.new(brownsource, 11, 25, tz)
c = VPNP::Corpus.new
c.add_all(ts)

# Save or load the corpus for speed
c.save("./testing/test_corpus")
#c = VPNP::Corpus.load("./testing/test_corpus")

# -----------------------------------------------------------------------------
# Create a new model
puts "Creating tag models..."
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

# =============================================================================
# Testing

puts "Building test corpus..."
# build testing corpus from the first 10 files
ts = VPNP::DirTokenSource.new(brownsource, 0, 10, tz)

def summary(t, tms)
  tms = [tms] if tms.is_a? VPNP::TagModel
  t = t.next if t.is_a? VPNP::TokenSource

  # Keep track of original type,
  # and of passes.
  start_token     = t
  original        = [] 
  pass            = 0
  last_n, last_s  = 0, 0

  puts "Summary of #{tms.length} pass run..."
  tms.each{|tm|
    # Keep count and progress through tokens.
    n, s, c = 0, 0, 0 
    t = start_token
    
    while(t) do

      # If this is the first pass,
      # note down the ground truth,
      # and wipe the token to simulate utter
      # ignorance.
      #
      # If this is pass 2+ then the whole point
      # is to build upon the previous passes.
      if pass == 0 then
        # Make a note of, and wipe, the type assigmnent
        original << t.type
        t.type = nil
      end

      # Estimate type
      tm.estimate_type(t)

      # Check and count
      s += 1 if t.type == original[c]
      n += 1 if t.type 
      c += 1

      # Progress to next token
      t = t.next
    end


    puts "  Pass #{pass+1}: #{tm}, #{c} tokens."
    puts "   #{(tms.length==1)?'total:':'      '} #{s - last_s}/#{n - last_n} (#{(((s - last_s).to_f/c)*100).round(2)}%/#{(((n - last_n).to_f/c)*100).round(2)}%) tag acc: #{(((s - last_s).to_f / (n - last_n).to_f)*100).round(2)}%"
    puts "   total: #{s}/#{n} (#{((s.to_f/c)*100).round(2)}%/#{((n.to_f/c)*100).round(2)}%) tag acc: #{((s.to_f / n.to_f)*100).round(2)}%" if pass != 0

    # Keep track of this phase's results for doing diffs next time
    last_n = n
    last_s = s

    # inc pass
    pass += 1
  }

  puts "          [correct/tagged] w.r.t. all tokens\n\n"
end



summary(ts, [simple, 
        # VPNP::TypePreservingPassthroughModel.new(morph),
        VPNP::TypePreservingPassthroughModel.new(grammar) 
])
ts.reset
summary(ts, simple)
ts.reset
summary(ts, hmm)
ts.reset
summary(ts, morph)
ts.reset
summary(ts, weighted)
ts.reset



puts "Training trained model..."
# Train the weights
# FIXME: this is using testing data.  Not entirely crucial but also not ideal for accuracy
while(x = ts.next)
  trained.train(x)
end
puts "Model weightings: "
trained.models.each{|m, w|
  puts "  Model: #{m} = #{w}"
}
ts.reset
puts "Done."

summary(ts, trained)
