class Relations

  # Maps wordnet entries to the apropriate dbpedia ressorce
  def self.map  
  { 
    'song' => 'dbpedia-owl:anthem',               # works
    
    'seat'=> 'dbpedia-owl:capital',               # works
     
    'extent' => 'dbpprop:areaKm',                 # works
    'size' => 'dbpprop:areaKm',

    'monetary system' => 'dbpedia-owl:currency',  # works
    'currency' => 'dbpedia-owl:currency', 
    
    'government' => 'dbpedia-owl:governmentType', # works
    
    'name' => 'dbpedia-owl:longName',             # works
    
    'saying' => 'dbpedia-owl:motto',              # works 
    
    'density' => 'dbpedia-owl:populationDensity', # works 

    'people' => 'dbpprop:populationEstimate',     # works
    'inhabitant' => 'dbpprop:populationEstimate',
    'citizen' => 'dbpprop:populationEstimate',
    
    'city' => 'dbpprop:largestCity',              # works
        
    'language' => 'dbpedia-owl:language',         # works 
      
    'termination' => 'dbpedia-owl:dissolutionDate', # otherwise check dbpedia-owl:dissolutionYear
    'defeat' =>  'dbpedia-owl:dissolutionDate',
    
    'beginning' => 'dbpedia-owl:foundingDate', # otherwise check dbpedia-owl:foundingYear
   
    'person' => 'dbpedia-owl:leaderTitle',
    
    ## VERBS

    'pay' => 'dbpedia-owl:currency', 
    
    'communicate' => 'dbpedia-owl:language',
    
    'initiate' => 'dbpedia-owl:foundingDate',
    'create' => 'dbpedia-owl:foundingDate',
    
    'command' => 'dbpedia-owl:leaderTitle',
    'direct' => 'dbpedia-owl:leaderTitle',
     
  }
  end
  
end