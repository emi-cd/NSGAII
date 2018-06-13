import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Collections;
import java.util.Random;
//import erne.MultiobjectiveAbstractFitnessResult;


/********************************************
  Please modify these parameter.
*/


final int population_size = 10;
final int num_of_object = 2;     // The number of object;
final int mutation_prob = 5;     // 5/10
final int x_num = 1;
final double x_min = -100.0d;          // Variable bounds
final double x_max = 100.0d;

int generation_num = 0;


List<List<Double>> population = new ArrayList<List<Double>>();
List<List<Double>> population_offspring = new ArrayList<List<Double>>();

// Function to optimize (SCH)
double function1(final List<Double>x){
  return x.get(0) * x.get(0);
}

double function2(final List<Double> x){
  return (x.get(0) - 2) * (x.get(0) - 2);
}

double optimize_function(final List<Double> x, final int i){
  double ret = 0;
  if(i == 1)
    ret =  function1(x);
  else if(i == 2)
    ret =  function2(x);
    
  return ret;
}

// Whether a dominates b. Return true when a dominates b.
boolean dominate(final List<Double> a, final List<Double> b){ 

  if((optimize_function(a, 1) > optimize_function(b, 1)) || (optimize_function(a, 2) > optimize_function(b, 2)))
    return false;
  
  return true;
}

// ******************************************

// for debug
void print_array(final Double[] array){
  System.out.print("Array : ");
  for(Double arg : array){
    System.out.print("[" + arg + "] ");
  }
  System.out.println();
}




// fast non dominated sort
List<List<Integer>> fast_non_dominated_sort(final List<List<Double>> P){
  List<List<Integer>> S = new ArrayList<List<Integer>>();
  List<List<Integer>> front = new ArrayList<List<Integer>>();
  front.add(new ArrayList<Integer>());
  int[] n = new int[P.size()];
  int[] rank = new int[P.size()];
  
  for(int p = 0; p < P.size(); p++){
    S.add(new ArrayList<Integer>());
    n[p] = 0;
 
    for(int q = 0; q < P.size(); q++){
      if (dominate(P.get(p), P.get(q)) && (p != q)){         // If p dominates q
        if(!S.get(p).contains(q)) { S.get(p).add(q); }       // Add q to the set of solutions dominated by p.
      }else if(dominate(P.get(q), P.get(p)) && (p != q)){
        n[p]++;                                              // Increment the domination counter of p.
      }
    }
    
    if(n[p] == 0){                                           // if p belongs to the first front.
      rank[p] = 0;
      if(!front.get(0).contains(p)){ front.get(0).add(p); }
    }  
  }
  
  int i = 0;                                                 // Initialize the front counter.
  while(front.get(i).size() > 0) {
    List<Integer> Q = new ArrayList<Integer>();              // Used to store the members of the next front.
    for(int p : front.get(i)) {
      for(int q : S.get(p)) {
        n[q] = n[q] - 1;
        if(n[q] == 0){                                       // q belongs to the first front.
          rank[q] = i + 1;
          if(!Q.contains(q)) { Q.add(q); }
        }
      }
    }
    i = i + 1;
    front.add(Q);
  }
  
  return front;
}
          


//Sort by values of ith optimize function.
List<Integer> sort_by_values(final List<List<Double>> front, final int i){
  List<Integer> sorted_list = new ArrayList<Integer>();
  List<Double> value_list = new ArrayList<Double>();
  List<Double> tmp_list = new ArrayList<Double>();
  double val = 0;
  
  for(List<Double> arg : front) {
    val = optimize_function(arg, i);
    value_list.add(val);
    tmp_list.add(val);
  }
  Collections.sort(tmp_list);
  
  for(double t : tmp_list){
    sorted_list.add(value_list.indexOf(t));
  }
  
  return sorted_list;
}


// calculate crowding distance
Double[] crowding_distance_assignment(List<List<Double>> front){
  Double[] distance = new Double[front.size()];
  List<Integer> sorted_list;
  Arrays.fill(distance, 0.0d);                                                                  // initialize distance.
  
  for(int i = 0; i < num_of_object; i++) {
    // Function number start from 1, so I add 1 below.
    sorted_list = sort_by_values(front, i + 1);                                                 // sort using each objective value.
    assert sorted_list.size() ==  front.size(): "crowding_distance_assignment() : Size of list is different";

    double f_min = optimize_function(front.get(sorted_list.get(0)), i+1);
    double f_max = optimize_function(front.get(sorted_list.get(sorted_list.size() - 1)), i+1);
    System.out.println("front: " + front);
    System.out.println("f_min: " + f_min + ", f_max: " + f_max);
    
    distance[sorted_list.get(0)] = Double.POSITIVE_INFINITY;                                    // so that boundary points are always selected.
    distance[sorted_list.get(sorted_list.size() - 1)] = Double.POSITIVE_INFINITY;
    
    for(int j = 1; j < sorted_list.size() - 1; j++) {                                           // for all other points.
      if(f_max - f_min != 0 ){
        double after_val = optimize_function(front.get(sorted_list.get(j + 1)), i+1);
        double befour_val = optimize_function(front.get(sorted_list.get(j - 1)), i+1);
        distance[j] = distance[j] + (after_val - befour_val) / (f_max - f_min);
        System.out.print((after_val - befour_val) + " ");
      }
    }
  }
  
  print_array(distance);
  return distance;
}

// Mutation
List<Double> mutation(List<Double> a){
  List<Double> ret = new ArrayList<Double>();
  Random rnd = new Random();
  
  for(int i = 0; i < x_num; i++) {
    if(rnd.nextInt(10) < mutation_prob)
      ret.add(rnd.nextDouble()*(x_max - x_min) + x_min);
    else
      ret.add(a.get(i));
  }
  
  return ret;
}
    
    
// Crossover
List<Double> crossover(List<Double> a, List<Double> b){
  Random rnd = new Random();
  int index = rnd.nextInt(x_num * 2);
  List<Double> ret = new ArrayList<Double>();
  
  if(index < x_num){
    for(int i = 0; i< x_num; i++) {
      if(i == index)
        ret.add(b.get(i));
      else
        ret.add(a.get(i));
    }
  }else{
    for(int i = 0; i< x_num; i++) {
      ret.add(a.get(i));
    }
  }
  
  return ret;
}

// Return index of mininum value in argument array.
int max(final Double[] val){
  int ret = 0;
  
  for(int i = 1; i < val.length; i++){
    if(val[ret] < val[i])
      ret = i;
  }
  return ret;
}

// Sort by crowding distance. CAUTION : val is modified in this function!!
List<List<Double>> new_dominate_sort(final List<List<Double>> list, Double[] val){
  List<List<Double>> ret = new ArrayList<List<Double>>();
  
  for(int i = 0; i < val.length; i++){
    int index = max(val);
    val[index] = -1.0d;
    ret.add(list.get(index));
  }
  
  assert list.size() == ret.size() : "new_dominate_sort() : Size of ret list is different.";
  return ret;
}

// Execute crossover and mutation. Make offspring from pop.
List<List<Double>> make_new_pop(final List<List<Double>> pop){
  List<List<Double>> ret = new ArrayList<List<Double>>();
  Random rnd = new Random();
  
  Double[] val = crowding_distance_assignment(pop);
  List<List<Double>> tmp = new_dominate_sort(pop, val);
  ret.addAll(tmp.subList(0, population_size/3));
  
  for(int i = 0; i < pop.size()-i; i++){
    ret.add(crossover(pop.get(i), pop.get(pop.size()-i - 1)));
  }
  while(ret.size() < pop.size()){
    ret.add(mutation(pop.get(rnd.nextInt(pop.size()))));
  }
  
  assert ret.size() == population_size : "make_new_pop() : Size of ret list is different.";
  
  return ret;
}

// Draw graph.
void draw_graph(){
  final int padding = 50;
  final int axis_x = height - padding;
  final int axis_y = padding;
  final int zoom = 5;
  
  stroke(0, 0, 0);
  strokeWeight(1);
  line(0, axis_x, width, axis_x);
  line(axis_y, 0, axis_y, height);
  
  textSize(12);
  text("Generation: " + generation_num, width - padding*2, padding/2); 
  generation_num++;
  
  strokeWeight(0.1);
  for(int i = 0; i < height; i+=zoom){
    line(0, i, width, i);
  }
  for(int i = 0; i < width; i+=zoom){
    line(i, 0, i, height);
  }
  
  strokeWeight(5);
  for(List<Double> arg : population)
    point((float)(optimize_function(arg, 1)*zoom + axis_y), (float)(axis_x - optimize_function(arg, 2)*zoom));  
}

// Main part ******************************

void setup(){
  size(500, 500);
  noStroke();
  fill(0, 102, 153, 204);
  frameRate(2);
  
  // Initialization of population.
  Random rnd = new Random();
  for(int i = 0; i < population_size; i++){
    List<Double> indivisual = new ArrayList<Double>();
    for(int j = 0; j < x_num; j++) {
      double val = rnd.nextDouble()*(x_max - x_min) + x_min;
      indivisual.add(val);
    }
    population.add(indivisual);
  }
  
  // Make offspring population.
  population_offspring = make_new_pop(population);
  
  assert population.get(0).size() ==  x_num: "setup() : Size of Indivisual is different.";
  assert population.size() == population_size : "setup() : Size of population is different.";
  assert population_offspring.size() == population_size : "setup() : Size of population_offspring is different.";

}



void draw(){
  background(255);
  List<List<Double>> next_p = new ArrayList<List<Double>>();                 // indivisual = [1.1d, 3.8d, ...], population = [indivisual1, indivisual2, ...]
  
  population.addAll(population_offspring);                                   // combine parent and offspring population.
  assert population.size() == population_size * 2 : "draw() : Size of population + population_offspring is different.";
  List<List<Integer>> front = fast_non_dominated_sort(population);           // front = (f_0, f_1, ...). f_0 = [index_number_of_population, ...]
  
  int i = 0;
  while(next_p.size() + front.get(i).size() <= population_size){             // until the parent population is filled.
    List<List<Double>> tmp = new ArrayList<List<Double>>();
    for(int index : front.get(i)){
      tmp.add(population.get(index));
    }
    
    next_p.addAll(tmp);                                                      // include ith nondominated front in the parent pop.
    i++;                                                                     // check the next front for inclusion.
  }
  
  List<List<Double>> tmp = new ArrayList<List<Double>>();
  for(int index : front.get(i)){
    tmp.add(population.get(index));
  }
  
  Double[] val = crowding_distance_assignment(tmp);
  tmp = new_dominate_sort(tmp, val);
  next_p.addAll(tmp.subList(0, population_size - next_p.size()));
  
  population_offspring = make_new_pop(next_p);
  population = next_p;
  
  
  assert population.size() == population_size : "draw() : Size of population is different.";
  assert population_offspring.size() == population_size : "draw() : Size of population_offspring is different.";
  //System.out.println("population: " + population);
  //System.out.println("offspring: " + population_offspring + "¥n");
    
  draw_graph();                                                              // show results.
  
}