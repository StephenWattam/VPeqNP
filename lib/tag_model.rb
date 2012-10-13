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
        prob_types = super(token.prev)
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
      @corpus.get_transitions(token.prev).map{|type, count|
        transition_probabilities[type] = p_type_transition(token.prev, type) 
      }

      # Now multiply each transition with the probability that the word
      # is natively of that type
      types = {}
      transition_probabilities.each{|type, p|
        p = p_type(token, type)
        # puts "P[#{type}] = #{p}"
        types[type] = transition_probabilities[type] * p if p > 0 
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


  class GrammarRuleTagModel < TagModel
    SEPARATOR = '.'

    def initialize(rules = [])
      @rules = rules
    end

    # Load rules from a file
    #
    # Rules should be of the form:
    #
    # ---
    #  - rule one
    #  - rule two
    #  etc...
    #
    # i.e. stadard YML list.
    def self.load(filename)
      require 'yaml'
      rules = YAML.load(File.read(filename)).map{|str|
        parse_rule(str)
      }
      return GrammarRuleTagModel.new(rules)
    end

    # Applies rules to a given token
    def estimates(token)
      # Store types and a sum
      types = {}
      sum = 0

      # Add one to the type the rule advocates
      # if the rule matches.
      @rules.each{|r|
        type = apply_rule(r, token)
        if type then
          types[type] ||= 0
          types[type]  += 1
          sum          += 1
        end
      }

      # Normalise
      types.each{|t, w|
        types[t] = types[t].to_f / sum
      }

      # return
      return types
    end


    private

    def apply_rule(rule, token)
      # Offset, i.e. what position is the current token?
      offset = rule[:placeholder].to_i

      # Holds tokens around the area
      context = []

      # go through rules, applying offset and finding tokens
      rule[:parts].each_index{ |i|
        # puts "Looking up token: #{i}, 
        #       #{rule[:parts][i]} = get_token_by_offset(#{i-offset}) = 
        #       #{get_token_by_offset(token, i-offset)}"
        t = get_token_by_offset(token, i-offset)
        return nil if not t
        context << t
      }

      # Iterate through the rule, comparing it.
      rule[:parts].each_index{ |i|
        # Load the token to compare and the rule to
        # compare it against
        cont = context[i]
        part = rule[:parts][i]

        # Unless this is the placeholder, match items
        if i != rule[:placeholder] then
          return nil if part[:word] and cont.word != part[:word]
          return nil if part[:type] and cont.type != part[:type] 
        end

      }

      # If we get here, the rule matches
      # This means we can take the type out of the place-
      # holder rule and send it back up to be weighted
      return rule[:parts][rule[:placeholder]][:type] 
    end

    # FIXME: this is very ugly.
    def get_token_by_offset(token, offset)
      # offset = 0 means the token passed in
      return token if offset == 0

      # If greater than 0 go forwards
      if offset > 0 then
        while(offset > 0)
          token = token.next
          return nil if not token
          offset -= 1
        end

      # else go backwards
      else
        while(offset < 0)
          token = token.prev
          return nil if not token
          offset += 1
        end
      end

      # return el token
      return token
    end

    # 
    def self.parse_rule(str)

      # Array to hold the rule
      rule = {:placeholder => nil, :parts => []}

      # Parse each chunk
      chunks = str.split
      chunks.each{|c|
        if c.count(SEPARATOR) > 2 then
          raise "Invalid format: chunk '#{c}' has too many separators."
        elsif c =~ /^#{Regexp.escape(SEPARATOR)}.+#{Regexp.escape(SEPARATOR)}$/ then
          # placeholder (
          raise "Invalid expression format: two placeholders in expression '#{str}'" if rule[:placeholder]
          rule[:placeholder] = rule[:parts].length
          rule[:parts] << {:type => c[1..-2]}
        else

          # Split around a dot.
          parts = c.split(SEPARATOR)
          matcher = {:word => (parts[0] == '') ? nil : parts[0],
                     :type => parts[1] }

          # And write the rule
          rule[:parts] << matcher
        end
      }
     
      # Check one placeholder exists
      raise "Invalid expression format: no placeholder in expression '#{str}'" if not rule[:placeholder]

      # Return the rule
      return rule
    end
  end


  class WeightedTagModel < TagModel
    attr_reader :models

    # Models:
    #  {model => weight,
    #   model => weight, ...}
    def initialize(model_weights)
      # Load models
      @models = model_weights
          
      # Normalise weights to sum to 1
      max = @models.values.max
      @models.each{ |m, w|
        @models[m] = w.to_f/max 
      }
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



  class TrainedWeightTagModel < WeightedTagModel

    def initialize(*models)

      # Load the models into a hash with dummy weights
      m = {}
      models.each{|k, v| m[k] = 1.0 } 

      # Pass to super
      super(m)

      # Seed a hash of accuracies to whittle down in
      # training (=number correct)
      @fits = {}
      @models.each_key{|m|
        @fits[m] = 0
      }
      @trained = 0
    end

    # Train the weights for a single token
    #
    # NB!: may be destructive to the token source
    def train(token)
      # Need an authoritative ground truth
      raise "Cannot train on an untyped token" if not token.type

      # Read the truth for later checks
      truth = token.type

      # For each model, run it and see if it was correct
      @models.each_key{|m|
        token.type = nil
        m.estimate_type(token)
        @fits[m] += 1 if token.type == truth
      }

      # Increment n
      @trained += 1

      # restore and return token
      token.type = truth
      return token
    end

    # Returns the list of models
    # with adjusted weights
    def models
      recompute_weights
      @models
    end

    # 
    def estimates(token)
      # TODO: make an option to 'finalise' the weights and
      # precompute this.
      recompute_weights

      # once weights are set, allow the super to do its thing
      super(token)
    end

    private

    def recompute_weights
      # compute weights from the training data
      @fits.each{|m, success|
        @models[m] = success.to_f / @trained 
      }
    end
  end



end
