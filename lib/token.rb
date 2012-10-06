
class Token
  # Read-write type
  attr_accessor :type
  # Read string
  attr_reader :string

  def initialize(string, type=nil)
    @string = string
    @type = type
  end

  def lemma
    # Return @string.stem
  end

  # Write to disk as lemma:type
  def to_s
    "[#{lemma}:#{@type}]"
  end
end
