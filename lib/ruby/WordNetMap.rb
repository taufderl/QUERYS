class WordNetMap

  # Maps wordnet entries to the apropriate dbpedia ressorce
  def self.map  
  { 
    'song' => 'dbpedia-owl:anthem',
    
    'seat'=> 'dbpedia-owl:capital',
      
    'extent' => 'dbpedia-owl:areaTotal',
    'size' => 'dbpedia-owl:areaTotal',

    'monetary system' => 'dbpedia-owl:currency',
    'currency' => 'dbpedia-owl:currency',
    
    'government' => 'dbpedia-owl:governmentType',
    
    'name' => 'dbpedia-owl:longName',
    
    'saying' => 'dbpedia-owl:motto',
    
    'density' => 'dbpedia-owl:populationDensity',

    'people' => 'dbpprop:estimatePopulation',
    'inhabitant' => 'dbpprop:estimatePopulation',
    'citizen' => 'dbpprop:estimatePopulation',
    
    'city' => 'dbpedia-owl:largestCity', # SuperlativeAdjective + City
        
    'language' => 'dbpedia-owl:officialLanguage',
     
    # consider that date sometimes not exists
    #['termination', 'ending', 'conclusion'] => 'dbpedia-owl:dissolutionDate',
    #['termination', 'ending', 'conclusion'] => 'dbpedia-owl:dissolutionYear',
    #['beginning', 'start', 'commencement'] => 'dbpedia-owl:foundingDate',
    #['beginning', 'start', 'commencement'] => 'dbpedia-owl:foundingYear,
    
    #'dbpedia-owl:leaderName'    Control, command/leader + Who or name
    #'dbpedia-owl:leaderTitle'   Control, command/leader + How/what

  }  
  end
  
end