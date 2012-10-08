

class BrownDataset 

  def initialize(dirpath)
    @files = Dir.glob(dirpath)  
    loadfile
  end

  def read
    if @curfile.length == 0
      return false if !loadfile 
    end
    line = @curfile.first
    @curfile = @curfile[1..@curfile.length]
    return line.gsub(/[\t\n\r]/, '')
  end
  
  private 
  def loadfile
    if @files.length > 0
      @counter ? @counter += 1 : @counter = 0
      puts "FILE #{@counter} #{@files.first}"
      #sleep 1
      @curfile = IO.readlines(@files.first, sep=' ')
      @curfile.map!{|str|
        (str.include? "\t") ? str.lines("\t").select{|x| x == String} : str
      }
      @curfile.select!{|str|
        str.include? "/"
      }
      @curfile.flatten!
      @files = @files - [@files.first]
      return true
    else
      puts "FILE #{@counter}"
      return false
    end
  end

end



#tr = BrownDataset.new('resources/brown/ca*')

#Train model on training set.
#train = File.open('resources/pos.train.txt', 'r')
train = BrownDataset.new('resources/brown/cg*')

#assoc = The word-bag
assoc = Hash.new

while (line = train.read)
  example, tag = line.split('/')

  if example != nil
    # If we've not seen this example before, create the appropriate structure.
    data = assoc[example] || data = Hash.new

    # Increment the example's count for this tag.
    (data[tag])  ? (data[tag] += 1) :  (data[tag] = 1)
    assoc[example] = data
  end
end

#train.close

#Test model against test set.
#test = File.open('resources/pos.test.txt', 'r')
test = BrownDataset.new('resources/brown/ch0*')

totalcount, correctcount = 0, 0

while (line = test.read)
  totalcount += 1
  example, tag = line.split('/')
  data = assoc[example]
  type = "Unknown"

  #If we've seen this word before, use most common tag.
  if data
    type = data.keys.max_by{|k,v| v}
    reason = "#{100*data.values.max/(data.values.inject(:+))}% of Training"
  #Else, if the word is capitalised, it's probably a proper noun.
  elsif example[0] == example[0].upcase
    reason = "Capitalised"
    type = "nnp"
  #Else, guess from the most common case for words with the same last trigram.
  else
    reason = "End 3 letters"
    similar_ends = assoc.keys.select{|x| x && x[-3,3] == example[-3,3]}
    if similar_ends.length > 0
      similar_ends = similar_ends.map{ |se|
       assoc[se].keys.max_by{|k,v| v}
      }  
      type = similar_ends.group_by { |n| n }.values.max_by(&:size).first
    end
  end

  #Check against markup.
  correctcount += 1 if type == tag
end

#test.close
puts "#{100*correctcount/totalcount}% correct"
