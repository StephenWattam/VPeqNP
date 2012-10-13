require File.join(File.join(File.dirname(__FILE__), 'token.rb'))
require File.join(File.join(File.dirname(__FILE__), 'corpus.rb'))

module VPNP

  class TagModel
    def initialize(corpus)
      @corpus   = corpus
    end

    # Output a {'type' => probability} hash
    def estimates(token)
      return {}
    end

    #Evaluate the model against a 
    def estimate_chain(token)
      # Whilst token.next, continue.
      while(token)
        estimate_type(token)
        token = token.next
      end

      # return the last token in the chain.
      return token
    end

    # Actually tag the token.
    def estimate_type(token)
      types       = estimates(token)
      return token if types.length == 0
      token.type  = types.keys[types.values.index(types.values.max)]
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
        types[type] = p_type(token, type)
      }
      return types
    end

  end


  class MarkovTagModel < SimpleProbabalisticTagModel

    # this is a fairly ugly workaround for calling
    # a superclass' method named differently to the
    # callee's.
    #
    # See http://stackoverflow.com/questions/1251178/calling-another-method-in-super-class-in-ruby
    # for more info.
    alias :bootstrap_simple_prob :estimates

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

      # If this is the first token, fall back to 
      # SimpleProbabalisticTagModel
      if not token.prev then
        return super(token)
      end

      # If the previous token is untyped then first
      # tag it with SimpleProbabalisticTagModel
      if not token.prev.type then
        prob_types = bootstrap_simple_prob(token.prev)
        if prob_types.length > 0 then
          # Assign maximally likely tag from simple probability checker
          token.prev.type = prob_types.keys[ prob_types.values.index( prob_types.values.max ) ]
        else
          # Give up
          return {}
        end
      end
      
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
      

      types = {}
      transition_probabilities.each{|type, p|
        p = p_type(token, type)
        # puts "P[#{type}] = #{p}"
        if p > 0 then
          types[type] = transition_probabilities[type] * p
        end
      }

      # return types
      return types
    end
  end



  class MorphologicalRuleTagModel < TagModel
    # Rules should be of the form /regex/ => 'type'
    def initialize(rules = {})
      @rules = rules
    end

    # Load rules from a file of the format
    #
    # ---
    # key:value
    # key:value
    #
    # i.e. normal YAML
    def self.load(filename)
      require 'yaml'
      rules = {}
      YAML.load(File.read(filename)).map{|k, v|
        rules[Regexp.new(k)] = v
      }
      return self.new(rules)
    end

    def estimates(token)
      # Keep track of number of RXs that fit
      fits  = 0
      types = {}

      @rules.each{|rx, type|
        if token.word =~ rx then
          types[type] ||= 0
          types[type]  += 1 
          fits         += 1
        end
      }

      # Don't div by zero
      return {} if fits == 0

      # And return the list of types.
      types.each{|type, score|
        types[type] = (score.to_f / fits)
      }

      return types
    end
  end


  class SimpleHybridModel < TagModel
    def initialize(corpus, rules)
      super(corpus)

      @prob   = SimpleProbabalisticTagModel.new(@corpus)
      @morph  = MorphologicalRuleTagModel.new(rules)
    end

    def estimates(token)
      p_est = @prob.estimates(token)
      m_est = @morph.estimates(token)
      if p_est.length == 0 #|| p_est.values.inject(:+) == 0
        return m_est
      else
      #elsif p_est.length != m_est.length
        return p_est
      #else
       # ps = p_est.values.zip(m_est.values)
        #ps = ps.each{|p, m| p*m}
        #return Hash.new(p_est.keys.zip(ps))
      end
    end
  end





  class WeightedCombinationTagModel < TagModel

    # Models:
    #  {model => weight,
    #   model => weight, ...}
    def initialize(model_weights)
      # Load models
      @models = model_weights
      
      # Normalise weights to sum to 1
      max = @models.values.max
      @models.each{ |m, w| @models[m] = w.to_f/max }
    end

    # Compute estimates
    def estimates(token)
      types = {}

      # Loop through models
      @models.each{|model, weight|

        # Each type for each model, 
        # add its weighted proportion to the list.
        model.estimates(token).each{ |type, p|
          types[type] ||= 0 
          types[type]  += ((p * weight) / @models.length)
        }

      }

      return types
    end
  end
end
