
require File.join(File.join(File.dirname(__FILE__), 'token.rb'))
require File.join(File.join(File.dirname(__FILE__), 'corpus.rb'))
require File.join(File.join(File.dirname(__FILE__), 'tokeniser.rb'))
require File.join(File.join(File.dirname(__FILE__), 'token_source.rb'))
require File.join(File.join(File.dirname(__FILE__), 'output_formatter.rb'))

# Add to the String class with nice options.
class String
  def tag(corpus, output_formatter)
    pt = VPNP::POSTagger.new(:corpus => corpus)
    ts = SimpleTokenSource.new(self)
    of = SimpleOutputFormatter.new(self)
    pt.tag(ts, of)
  end
end




module VPNP
  class POSTagger
    def initialize(opts = {})
    end

    def train(input_source)
    end

    def tag(token_source, output_formatter)
    end
  end
end
