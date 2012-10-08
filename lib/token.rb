
module VPNP
  class Token
    # Read-write type
    attr_accessor :type, :source, :prev
    # Read string
    attr_reader :string, :word
    attr_writer :next

    def initialize(string, word, type=nil)
      @word = word
      @string   = string
      @type     = type
    end

    def next
      if @next.is_a? TokenSource
        @next = @next.next
        return @next 
      end
      @next
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
