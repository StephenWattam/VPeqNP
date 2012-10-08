require 'pstore'

module VPNP
  class Corpus
    def initialize(file)
      # @pstore = PStore.new(file) 
      @store                = {}
      @store[:finalised]    = false
      @store[:types]        = {}
      @store[:transitions]  = {}
      @store[:marginals]    = {}
    end

    def word_types
      @store[:types]
    end

    def inc_word_type(word, type=nil)
      if word.is_a? Token
        type = word.type 
        word = word.word
      end
      
      # TODO: make nicer 
      word_types[word] ||= {}
      word_hash = word_types[word]
      word_hash[type] ||= 0
      word_hash[type] += 1
    end

    def compute_marginals
      # TODO
      $stderr.puts "STUB: Compute Marginals"
    end

    # def type_trans
    #   (@store[:type_trans] ||= {})
    # end
  end
end
