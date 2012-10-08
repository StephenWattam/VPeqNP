require File.join(File.join(File.dirname(__FILE__), 'token.rb'))
require File.join(File.join(File.dirname(__FILE__), 'corpus.rb'))

module VPNP
  class TagModel
    def initialize(corpus)
      @corpus = corpus
    end

    def estimate_type(token)
      $stderr.puts "STUB: Override me: VPNP::TagModel::estimate_type"
    end
  end

  class SimpleProbabalisticTagModel < TagModel
    # Return the probability of observing the type that has actually been observed
    def p_observed_type(token)
      p_type(token, token.type)
    end

    # Return the probability of observing a given type for this word
    def p_type(token, type)
      p = @corpus.get_type_count(token, type).to_f / @corpus.get_word_freq(token)
      return 0 if p.nan?
      return p
    end

    # Estimate type naively
    def naive_estimate_type(token)
      types = @corpus.get_types(token)
      return nil if types.length == 0
      return types.keys[types.values.index(types.values.max)]
    end

    # Estimate type using token transitions
    def context_estimate_type(token)
      # TODO
    end
  end
end
