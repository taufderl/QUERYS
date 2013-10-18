require 'wordnet'
require_relative 'WordNetMap'
require 'set'

lexicon = WordNet::Lexicon.new


synsets = lexicon.lookup_synsets('lead', WordNet::Noun)

hypernyms = Set.new

synsets.each  { |ss|
  ss.traverse(:hypernyms).each { |synset|
    synset.words.each { |word|
      hypernyms << word.lemma
    }
  }
}
puts hypernyms.to_a.inspect
