class WordNetMap

  # Maps wordnet entries to the apropriate dbpedia ressorce
  def self.map  
  { 
    'song' => 'dbpedia-owl:anthem',               # works well
    
    'seat'=> 'dbpedia-owl:capital',               # works well
     
    'extent' => 'dbpprop:areaKm',                 # works
    'size' => 'dbpprop:areaKm',

    'monetary system' => 'dbpedia-owl:currency',  # works remove '_sign'
    'currency' => 'dbpedia-owl:currency', 
    
    'government' => 'dbpedia-owl:governmentType', # works
    
    'name' => 'dbpedia-owl:longName',             # works
    
    'saying' => 'dbpedia-owl:motto',              # works 
    
    'density' => 'dbpedia-owl:populationDensity', # works 

    'people' => 'dbpprop:populationEstimate',     # works
    'inhabitant' => 'dbpprop:populationEstimate',
    'citizen' => 'dbpprop:populationEstimate',
    
    'city' => 'dbpprop:largestCity',              # works
        
    'language' => 'dbpedia-owl:language',         # language TODO: remove '_language'
     
    # consider that date sometimes not exists
    #['termination', 'ending', 'conclusion'] => 'dbpedia-owl:dissolutionDate',
    #['termination', 'ending', 'conclusion'] => 'dbpedia-owl:dissolutionYear',
    #['beginning', 'start', 'commencement'] => 'dbpedia-owl:foundingDate',
    #['beginning', 'start', 'commencement'] => 'dbpedia-owl:foundingYear,
    
    #'dbpedia-owl:leaderName'    Control, command/leader + Who or name
    #'dbpedia-owl:leaderTitle'   Control, command/leader + How/what

    ## VERBS

    'pay' => 'dbpedia-owl:currency', 
    
    'communicate' => 'dbpedia-owl:language',
    
    #['initiate', 'create' ] => 'dbpedia-owl:foundingDate',
    # 'defeat' => 'dbpedia-owl:dissolutionDate',
    
    # 'command' => 'dbpedia-owl:leaderName'    
    # 'command' => 'dbpedia-owl:leaderTitle' 
  }
  end
  
end