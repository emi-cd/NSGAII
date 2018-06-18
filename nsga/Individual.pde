class Individual{

  Individual(final List<Double> num){
    _ind = new ArrayList<Double>();
    for(double arg : num)
      _ind.add(arg);
    
    _crowding_distance = 0.0d;
    _rank = -1;
    
    _val1 = function1(num);
    _val2 = function2(num); 
  }
  
  public double get_mth_function_value(final int index){
    assert index == 0 || index == 1 : "Now, function number should be 0 or 1...";
    if(index == 0)
      return _val1;
    else if(index == 1)
      return _val2;
    
    return 0.0d;
  }
  
  public void set_rank(final int rank){
    _rank = rank;
  }
  public void set_distance(final double distance){
    _crowding_distance = distance;
  }
  public double set_ith_arg(final int index, final double num){
    return _ind.set(index, num);
  }
  public int get_rank(){
    return _rank;
  }
  public double get_distance(){
    return _crowding_distance;
  }
  public double get_ith_arg(final int i){
    return _ind.get(i);
  }
  
  public boolean do_dominate(final Individual ind2){
    if((_val1 < ind2.get_mth_function_value(0)) && (_val2 < ind2.get_mth_function_value(1)))
      return true;
      
    return false;
  }
  
  public boolean do_new_dominate(final Individual ind2){
    if(_rank < ind2.get_rank())
      return true;
    else if((_rank == ind2.get_rank()) && (ind2.get_distance() < _crowding_distance))
      return true;
      
    return false;
  }
  
  @Override
  public String toString() {
    String ret = "(";
    
    //if(_ind.size() != 0)
    //  ret += _ind.get(0);
    
    //for(int i = 1; i < _ind.size(); i++)
    //  ret += "," + _ind.get(i);
    ret += "x: " + _ind;
    ret += ", crowding_distance: " + _crowding_distance;


    ret += ")";
    
    return ret;
  }
  
  
  // Function to optimize (SCH)
  private double function1(final List<Double> x){
    return x.get(0) * x.get(0);
  }
  private double function2(final List<Double> x){
    return (x.get(0) - 2) * (x.get(0) - 2);
  }
  
  private List<Double> _ind;
  private double _val1;
  private double _val2;
  
  private double _crowding_distance;
  private int _rank;

}