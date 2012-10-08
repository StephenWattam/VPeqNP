
module VPNP
  class Token
    # Read-write type
    attr_accessor :type, :source
    # Read string
    attr_reader :string, :word

    def initialize(string, word, type=nil)
      @word = word
      @string   = string
      @type     = type
    end

    def lemma
      # TODO Return @string.stem
      @word.downcase
    end

    # Write to disk as lemma:type
    def to_s
      "[(#{@word}:#{@type})]"
    end
  end
end
