
# This is a really unwieldy way of doing things, probably should be changed in the future.

module VPNP
  class Corpus
    def initialize()
      @store = Hash.new

      # Set up defaults
      @store[:types]            = {}
      @store[:transitions]      = {}
      @store[:word_freq]        = {}
      @store[:type_trans_freq]  = {}
      @store[:n]                = 0
    end

    def self.load(filename)
      Marshal.load(File.open(filename))
    end
      
    def save(filename)
      File.write(filename, Marshal.dump(self))
    end

    # How many times have we seen this word?
    def get_word_freq(token)
      lemma = token.is_a?(Token)? token.lemma : token
      word_counts[lemma] || 0
    end

    # How many times has this type transitioned to another type,
    # rather than simply ending the sentence
    def get_type_trans_freq(token)
      type = token.is_a?(Token)? token.type : token
      type_trans_frequencies[type] || 0
    end

    def get_total
      n
    end

    # What have we seen this type transition to?
    def get_transitions(token)
      type = token.is_a?(Token)? token.type : token
      transitions[type] || {}
    end

    # A count of how many times this token has transitioned to the one
    # set in ".next"
    def get_transition_count(from, to)
      from = from.is_a?(Token)? from.type  : from
      to   = to.is_a?(Token)? to.type       : to

      return 0 if not transitions[from]
      transitions[from][to] || 0
    end

    # What types has this been?
    def get_types(token)
      lemma = token.is_a?(Token)? token.lemma : token
      word_types[lemma] ||  {}
    end

    # How many times has this token been this type?
    def get_type_count(token, type=nil)
      raise "Cannot predict with no type" if not (token.type or type)
      type = token.type if not type

      return 0 if not word_types[token.lemma]
      word_types[token.lemma][type] || 0
    end


    # Total words in corpus
    def n
      @store[:n]
    end

    # ------- end of querying api ------------------------
    
    
    def add_all(ts)
      while(x = ts.next) do
        add(x)
      end
    end

    # Add a token
    def add(token)
      @store[:n] += 1

      type = token.type
      word = token.lemma

      # TODO: make nicer 
      word_types[word]  ||= {}
      word_hash           = word_types[word]

      # Number of times this type has been seen for this word
      word_hash[type]   ||= 0
      word_hash[type]    += 1

      # Number of times this word has been seen
      word_counts[word]  ||= 0
      word_counts[word]   += 1

      # And first-order transitions
      if token.next then
        # Add to the count of times this word has been used in
        # a valid transition
        # Matt: How is 'this word' counted here? Surely it's
        # count regarding the type?
        type_trans_frequencies[type] ||= 0
        type_trans_frequencies[type]  += 1
        

        # Add to the transition matrix
        transitions[type]                   ||= {}
        transitions[type][token.next.type]  ||= 0
        transitions[type][token.next.type]   += 1
      end
    end

  private
  
    # Extract usef
    def word_types
      @store[:types]
    end

    def word_counts 
      @store[:word_freq]
    end

    def transitions
      @store[:transitions]
    end

    def type_trans_frequencies
      @store[:type_trans_freq]
    end
  end
end
