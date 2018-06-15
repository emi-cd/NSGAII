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

List<Indivisual> population = new ArrayList<Indivisual>();
List<Indivisual> population_offspring = new ArrayList<Indivisual>();

// ******************************************


// fast non dominated sort
List<List<Integer>> fast_non_dominated_sort(List<Indivisual> P){
  List<List<Integer>> S = new ArrayList<List<Integer>>();
  List<List<Integer>> front = new ArrayList<List<Integer>>();
  front.add(new ArrayList<Integer>());
  int[] n = new int[P.size()];
  
  for(int p = 0; p < P.size(); p++){
    S.add(new ArrayList<Integer>());
    n[p] = 0;
 
    for(int q = 0; q < P.size(); q++){
      if (P.get(p).do_dominate(P.get(q)) && (p != q)){         // If p dominates q
        if(!S.get(p).contains(q)) { S.get(p).add(q); }         // Add q to the set of solutions dominated by p.
      }else if(P.get(q).do_dominate(P.get(p)) && (p != q)){
        n[p]++;                                              // Increment the domination counter of p.
      }
    }
    
    if(n[p] == 0){                                           // if p belongs to the first front.
      P.get(p).set_rank(0);
      if(!front.get(0).contains(p)){ front.get(0).add(p); }
    }  
  }
  
  int i = 0;                                                 // Initialize the front counter.
  while(front.get(i).size() > 0) {
    List<Integer> Q = new ArrayList<Integer>();              // Used to store the members of the next front.
    for(int p : front.get(i)) {
      for(int q : S.get(p)) {
        n[q] = n[q] - 1;
        if(n[q] == 0){           // q belongs to the first front.
          P.get(q).set_rank(i + 1);
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
Indivisual[] sort_by_values(final List<Indivisual> front, final int i){
  Indivisual sorted_list[] = new Indivisual[front.size()];
  List<Double> value_list = new ArrayList<Double>();
  
  for(Indivisual ind : front) {
    value_list.add(ind.get_mth_function_value(i));
  }
  Collections.sort(value_list);
  
  for(Indivisual ind : front){
    sorted_list[value_list.indexOf(ind.get_mth_function_value(i)))] = ind;
  }
  
  return sorted_list;
}


// calculate crowding distance
void crowding_distance_assignment(List<Indivisual> front){
  Double[] distance = new Double[front.size()];
  Indivisual[] sorted_list;
  
  for(Indivisual ind : front){
    ind.set_distance(0.0d);                                                                     // initialize distance.
  }
  
  for(int i = 0; i < num_of_object; i++) {
    // Function number start from 1, so I add 1 below.
    sorted_list = sort_by_values(front, i);                                                 // sort using each objective value.
    assert sorted_list.length ==  front.size(): "crowding_distance_assignment() : Size of list is different";

    double f_min = sorted_list[0].get_mth_function_value(i);
    double f_max = sorted_list[sorted_list.length - 1].get_mth_function_value(i);
    //System.out.println("front: " + front);
    //System.out.println("f_min: " + f_min + ", f_max: " + f_max);
    
    sorted_list[0].set_distance(Double.POSITIVE_INFINITY);                                    // so that boundary points are always selected.
    sorted_list[sorted_list.length - 1].set_distance(Double.POSITIVE_INFINITY);
    
    for(int j = 1; j < sorted_list.length - 1; j++) {                                           // for all other points.
      if(f_max - f_min != 0 ){
        double after_val = sorted_list[j + 1].get_mth_function_value(i);
        double befour_val = sorted_list[j - 1].get_mth_function_value(i);
        sorted_list[j].set_distance( sorted_list[j].get_distance() + (after_val - befour_val) / (f_max - f_min));
        System.out.print((after_val - befour_val) + " ");
      }
    }
  }
}

// Mutation
Indivisual mutation(Indivisual a){
  List<Double> ret = new ArrayList<Double>();
  Random rnd = new Random();
  
  for(int i = 0; i < x_num; i++) {
    if(rnd.nextInt(10) < mutation_prob)
      ret.add(rnd.nextDouble()*(x_max - x_min) + x_min);
    else
      ret.add(a.get_ith_arg(i));
  }
  
  return new Indivisual(ret);
}
    
    
// Crossover
Indivisual crossover(Indivisual a, Indivisual b){
  Random rnd = new Random();
  int index = rnd.nextInt(x_num);
  List<double> ret = new ArrayList<double>();
  
  for(int i = 0; i< x_num; i++) {
    if(i == index)
      ret.add(b.get_ith_arg(i));
    else
      ret.add(a.get_ith_arg(i));
    }
  }
  
  return new Indivisual(ret);
}

// Return index of mininum value in argument array.
int max(final double[] val){
  int ret = 0;
  
  for(int i = 1; i < val.length; i++){
    if(val[ret] < val[i])
      ret = i;
  }
  return ret;
}

// Sort by crowding distance. CAUTION : val is modified in this function!!
List<Indivisual> new_dominate_sort(final List<Indivisual> list){
  List<Indivisual> ret = new ArrayList<Indivisual>();
  double val[] = new double[list.size()];
  
  for(int i = 0; i < val.length; i++){
    int index = max(val);
    val[index] = Double.NEGATIVE_INFINITY;
    ret.add(list.get(index));
  }
  
  assert list.size() == ret.size() : "new_dominate_sort() : Size of ret list is different.";
  return ret;
}

// Execute crossover and mutation. Make offspring from pop.
List<Indivisual> make_new_pop(final List<Indivisual> pop){
  List<Indivisual> ret = new ArrayList<Indivisual>();
  Random rnd = new Random();
  
  crowding_distance_assignment(pop);
  List<Indivisual> tmp = new_dominate_sort(pop);
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
  for(Indivisual ind : population)
    point((float)(ind.get_mth_function_value(0)*zoom + axis_y), (float)(axis_x - ind.get_mth_function_value(1)*zoom));  
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
    List<double> tmp = new ArrayList<double>();
    for(in j = 0; j < x_num; j++){
      tmp.add(rnd.nextDouble()*(x_max - x_min) + x_min);
    }
    population.add(new Indivisual(tmp));
  }
  
  // Make offspring population.
  population_offspring = make_new_pop(population);
  
  assert population.size() == population_size : "setup() : Size of population is different.";
  assert population_offspring.size() == population_size : "setup() : Size of population_offspring is different.";

}



void draw(){
  background(255);
  List<Indivisual> next_p = new ArrayList<Indivisual>();                 // indivisual = [1.1d, 3.8d, ...], population = [indivisual1, indivisual2, ...]
  
  population.addAll(population_offspring);                                   // combine parent and offspring population.
  assert population.size() == population_size * 2 : "draw() : Size of population + population_offspring is different.";
  List<List<Integer>> front = fast_non_dominated_sort(population);           // front = (f_0, f_1, ...). f_0 = [index_number_of_population, ...]
  
  int i = 0;
  while(next_p.size() + front.get(i).size() <= population_size){             // until the parent population is filled.
    List<Indivisual> tmp = new ArrayList<Indivisual>();
    for(int index : front.get(i)){
      tmp.add(population.get(index));
    }
    
    crowding_distance_assignment(tmp);
    next_p.addAll(tmp);                                                      // include ith nondominated front in the parent pop.
    i++;                                                                     // check the next front for inclusion.
  }
  
  List<Indivisual> tmp = new ArrayList<Indivisual>();
  for(int index : front.get(i)){
    tmp.add(population.get(index));
  }
  
  crowding_distance_assignment(tmp);
  tmp = new_dominate_sort(tmp);
  next_p.addAll(tmp.subList(0, population_size - next_p.size()));
  
  population_offspring = make_new_pop(next_p);
  population = next_p;
  
  
  assert population.size() == population_size : "draw() : Size of population is different.";
  assert population_offspring.size() == population_size : "draw() : Size of population_offspring is different.";
  //System.out.println("population: " + population);
  //System.out.println("offspring: " + population_offspring + "¥n");
    
  draw_graph();                                                              // show results.
  
}