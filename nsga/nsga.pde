import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Collections;
import java.util.Random;
import erne.MultiobjectiveAbstractFitnessResult;


// **********************************


final int population_size = 50;
final int max_gen = 500;
final int num_of_object = 2;     // The number of object;
final int mutation_prob = 5;     // 5/10
final int x_num = 1;
final double x_min = -1000.0d;          // Variable bounds
final double x_max = 1000.0d;

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

// Whether a dominates b.
boolean dominate(final List<Double> a, final List<Double> b){ 

  if((optimize_function(a, 1) > optimize_function(b, 1)) || (optimize_function(a, 2) > optimize_function(b, 2)))
    return false;
  
  return true;
}

// ******************************************



// Function to carry out NSGA-II's fast non dominated sort
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
        if(!S.get(p).contains(q)) { S.get(p).add(q); }
      }else if(dominate(P.get(q), P.get(p)) && (p != q)){
        n[p]++;
      }
    }
    
    if(n[p] == 0){
      rank[p] = 0;
      if(!front.get(0).contains(p)){ front.get(0).add(p); }
    }  
  }
  
  int i = 0;
  while(front.get(i).size() > 0) {
    List<Integer> Q = new ArrayList<Integer>();
    for(int p : front.get(i)) {
      for(int q : S.get(p)) {
        n[q] = n[q] - 1;
        if(n[q] == 0){      // p belongs to the first front
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
          


// Function to sort by values
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


// Function to calculate crowding distance
Double[] crowding_distance_assignment(List<List<Double>> front){
  Double[] distance = new Double[front.size()];
  List<Integer> sorted_list;
  Arrays.fill(distance, 0.0d);
  
  for(int i = 0; i < num_of_object; i++) {
    // Function number start from 1, so I add 1 below.
    sorted_list = sort_by_values(front, i + 1);
    assert sorted_list.size() ==  front.size(): "crowding_distance_assignment() : Size of list is different";

    double f_max = optimize_function(front.get(sorted_list.get(0)), i);
    double f_min = optimize_function(front.get(sorted_list.get(sorted_list.size() - 1)), i);
  
    distance[sorted_list.get(0)] = 88888888.0d;
    distance[sorted_list.get(sorted_list.size() - 1)] = 88888888.0d;
    
    for(int j = 1; j < sorted_list.size() - 1; j++) {
      if(f_max - f_min > 0 ){
        double after_val = optimize_function(front.get(sorted_list.get(j + 1)), i);
        double befour_val = optimize_function(front.get(sorted_list.get(j - 1)), i);
        distance[j] = distance[j] + (after_val - befour_val)/ (f_max - f_min);
      }
    }
  }
  
  return distance;
}

// Function to carry out the mutation operator
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
    
    
// Function to carry out the crossover
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

List<List<Double>> make_new_pop(List<List<Double>> pop){
  List<List<Double>> ret = new ArrayList<List<Double>>();
  Random rnd = new Random();
  
  for(int i = 0; i < pop.size()-i; i++){
    ret.add(crossover(pop.get(i), pop.get(pop.size()-i - 1)));
  }
  while(ret.size() < pop.size()){
    ret.add(mutation(pop.get(rnd.nextInt(pop.size()))));
  }
  
  return ret;
}


void draw_graph(){
  final int padding = 50;
  final int axis_x = height - padding;
  final int axis_y = padding;
  final int zoom = 50;
  
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

// TODO
void new_dominate(final List<List<Double>> list, Double[] val){
  
}

// Main part ******************************

void setup(){
  size(500, 500);
  noStroke();
  fill(0, 102, 153, 204);
  frameRate(1);
  
  // Initialization
  Random rnd = new Random();
  for(int i = 0; i < population_size; i++){
    List<Double> indivisual = new ArrayList<Double>();
    for(int j = 0; j < x_num; j++) {
      double val = rnd.nextDouble()*(x_max - x_min) + x_min;
      indivisual.add(val);
    }
    population.add(indivisual);
  }
  
  population_offspring = make_new_pop(population);
  
  assert population.get(0).size() ==  x_num: "setup() : Size of Indivisual is different.";
  assert population.size() == population_size : "setup() : Size of population is different.";
  assert population_offspring.size() == population_size : "setup() : Size of population_offspring is different.";
  
  draw_graph();
}

void draw(){
  background(255);
  List<List<Double>> next_p = new ArrayList<List<Double>>();
  
  population.addAll(population_offspring);
  assert population.size() == population_size * 2 : "draw() : Size of population + population_offspring is different.";
  List<List<Integer>> front = fast_non_dominated_sort(population);
  
  int i = 0;
  while(next_p.size() + front.get(i).size() <= population_size){
    List<List<Double>> tmp = new ArrayList<List<Double>>();
    for(int index : front.get(i)){
      tmp.add(population.get(index));
    }
    
    next_p.addAll(tmp);
    i++;
  }
  
  // TODO : It should depend on crowding_distance_sort().
  List<List<Double>> tmp = new ArrayList<List<Double>>();
  for(int index : front.get(i)){
    tmp.add(population.get(index));
  }
  
  Double[] val = crowding_distance_assignment(tmp);

  new_dominate(tmp, val);
  next_p.addAll(tmp.subList(0, population_size - next_p.size()));
  population_offspring = make_new_pop(next_p);
  population = next_p;
  
  assert population.size() == population_size : "draw() : Size of population is different.";
  assert population_offspring.size() == population_size : "draw() : Size of population_offspring is different.";
  // System.out.println("population: " + population);
  // System.out.println("offspring: " + population_offspring + "¥n");
    
  // Show
  draw_graph();
  
}