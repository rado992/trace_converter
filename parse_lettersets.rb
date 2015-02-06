# require_relative "parse_letter"

def find_txts
  txts = Dir["traces/*.txt"]#.map { |txt| txt.sub(/^traces\//, '') }
  p txts
  txts.each do |txt|
    system("ruby parse_letter.rb " + txt)
  end
  # system("ruby parse_letter.rb " + txts[0])
end

find_txts