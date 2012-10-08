
module VPNP
  class Token
    # Read-write type
    attr_accessor :type, :source
    # Read string
    attr_reader :string

    def initialize(string, word, type=nil)
      @word = word
      @string   = string
      @type     = type
    end

    def lemma
      # TODO Return @string.stem
      @string
    end

    # Write to disk as lemma:type
    def to_s
      "['#{@string}'(#{lemma}:#{@type})]"
    end
  end
end
