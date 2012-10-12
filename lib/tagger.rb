
require File.join(File.join(File.dirname(__FILE__), 'token.rb'))
require File.join(File.join(File.dirname(__FILE__), 'corpus.rb'))
require File.join(File.join(File.dirname(__FILE__), 'tokeniser.rb'))
require File.join(File.join(File.dirname(__FILE__), 'token_source.rb'))
require File.join(File.join(File.dirname(__FILE__), 'output_formatter.rb'))

# Add to the String class with nice options.
class String
  def tag(model, output_formatter, tokeniser = VPNP::RegexTokeniser.new())
    ts = VPNP::SimpleTokenSource.new(self, tokeniser)
    of = VPNP::SimpleOutputFormatter.new()
   
    str = ""
    while(x = ts.next)
      model.estimate_type(x)
      str += of.output( x )
    end
    return str 
  end
end




module VPNP
  class POSTagger
    def initialize(corpus)
    end

    def train(input_source)
    end

    def tag(token_source, output_formatter)
    end
  end
end
