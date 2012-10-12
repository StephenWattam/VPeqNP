require File.join(File.join(File.dirname(__FILE__), 'token.rb'))
require File.join(File.join(File.dirname(__FILE__), 'corpus.rb'))

module VPNP

  # class RuleSet

  #   def initialize
  #     @rulelist = []
  #   end

  #   #Adds a rule.
  #   def add_rule(method)
  #     @rulelist.push(method) 
  #   end

  #   #Weights all the passed types for the given token according to the 
  #   #stored ruleset.
  #   def weight_types(token, types)
  #     newprobs = types.map{ |type, p|
  #       apply_rules(token, type, p) 
  #     }
  #     return Hash[types.keys.zip(newprobs)]
  #   end

  #   #Apply all the rules to the probability of the token-type mapping
  #   #Return the new probability.
  #   def apply_rules(token, type, p)
  #     weighted_p = p
  #     @rulelist.each { |rule| 
  #         weighted_p = rule.call(token, type, weighted_p)
  #     }
  #     return weighted_p
  #   end
  # end


  class TagModel
    def initialize(corpus)
      @corpus   = corpus
      # @ruleset  = ruleset if ruleset && ruleset.is_a?(RuleSet)
    end

    # Output a {'type' => probability} hash
    def estimates(token)
      return {}
    end

    # Actually tag the token.
    def estimate_type(token)
      types = estimates(token)
      token.type = types.keys[types.values.index(types.values.max)]
      return token
    end
  end

  class SimpleProbabalisticTagModel < TagModel
    # Return the probability of observing the type that has actually been observed
    def p_observed_type(token)
      p_type(token, token.type)
    end

    # Return the probability of observing a given type for this word
    def p_type(token, type)
      observed_tokens = @corpus.get_word_freq(token)
      return 0 if observed_tokens == 0

      p = @corpus.get_type_count(token, type).to_f / observed_tokens
      return 0 if p.nan?
      return p
    end

    # Estimate type naively
    def estimates(token)
      types = @corpus.get_types(token)
      return {} if types.length == 0
      types.each{|type, count|
        count = p_type(token, type)
      }
      return types
    end

  end

  class MarkovTagModel < SimpleProbabalisticTagModel

    # Probability of seeing type x then type y
    def p_type_transition(from, to)
      # Number of times we have transitioned FROM this type
      observed_transitions = @corpus.get_type_trans_freq(from)  
      return 0 if observed_transitions == 0 # avoid div by zero errors

      # puts "observed #{from.type}->#{to}: #{observed_transitions}"

      p = @corpus.get_transition_count(from, to).to_f / observed_transitions
      return 0 if p.nan?
      return p
    end


    # Estimate type using token transitions
    def estimates(token)
      return {} if not (token.prev and token.prev.type)    # We require knowledge of the previous token's type.
      
      # For each of the possible transitions from the previous tag,
      # work out the probability that the transition was made
      # puts "Previous tag: #{token.prev.type}" 
      transition_probabilities = {}
      observed_transition_results   = @corpus.get_transitions(token.prev)
      observed_transition_results.map{|type, count|
        # puts "P(#{type}|#{token.prev.type}) == #{count}/marginal sum == #{p_type_transition(token.prev, type)}"
        transition_probabilities[type] = p_type_transition(token.prev, type)
      }
      # puts "--"

      # Now add what we have naively guessed.
      # If both agree, this should not be a problem, but occasionally
      # we will see words for which we have no transition, but for which
      # we do have prior knowledge.
      #
      # Technically, this is messing with the markov model,
      # for now it's commented because of that.  Note that changing
      # the constant will change the weight any 'non-transition' data gets
      #
      # XXX: this actually reduces result quality for now :-)
      #
      # @corpus.get_types(token).each{|type, count|
      #   transition_probabilities[type] = 1 if not transition_probabilities[type]
      # }


      # Now multiply each transition with the probability that the word
      # is natively of that type
      

      #type_probabilities = {}
      transition_probabilities.each{|type, p|
        transition_probabilities[type] *= p_type(token, type)
        # puts "P(#{type}|token.prev.type) *= #{p_type(token, type)} == #{transition_probabilities[type]}"
      }
# 
#       if @ruleset  
#         types = transition_probabilities
#         types = @ruleset.weight_types(token, types) 
#         token.type = types.keys[types.values.index(types.values.max)]          
#       end 
      return transition_probabilities

    end



  end


  # Combines, logically, the taggers above in order to work
  # for tagged and untagged text with the maximum intelligence.
  #
  # This is, in effect, a happy workaround for the fact that
  # transition-based models cannot work without some notion of
  # text ordering (.prev/.next) and pure observation models suck.
  class BestEffortTagModel < TagModel
    def initialize(corpus) 
      super(corpus)

      # Create one of each of the semi-decent models
      @prob   = SimpleProbabalisticTagModel.new(@corpus)
      @hmm    = MarkovTagModel.new(@corpus)
    end

    def estimates(token)
      if not token.prev or not token.prev.type then
        @prob.estimates(token)
      else
        @hmm.estimates(token)
      end
    end

  end

end
