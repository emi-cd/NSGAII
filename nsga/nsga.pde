import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Collections;
import java.util.Random;
//import erne.MultiobjectiveAbstractFitnessResult;


/********************************************
  Please modify these parameter.
*/

final int population_size = 100;
final int num_of_object = 2;     // The number of object;
final int mutation_prob = 8;     // 8/10
final int x_num = 1;
final double x_min = -1000.0d;          // Variable bounds
final double x_max = 1000.0d;

final int zoom = 50;

// ******************************************

int generation_num = 0;

List<Individual> population = new ArrayList<Individual>();
List<Individual> population_offspring = new ArrayList<Individual>();

// This function is for debug.
boolean checkFull(Individual[] ind){
  for(Individual arg : ind){
    if(arg == null)
      return false;
  }
  return true;
}

int count_front_size(List<List<Integer>> front){
  int counter = 0;
  for(List<Integer> f : front){
      counter+=f.size();
  }

  return counter;
}

// fast non dominated sort
List<List<Integer>> fast_non_dominated_sort(List<Individual> P){
  List<List<Integer>> S = new ArrayList<List<Integer>>();
  List<List<Integer>> front = new ArrayList<List<Integer>>();
  front.add(new ArrayList<Integer>());
  int[] n = new int[P.size()];
  
  for(int p = 0; p < P.size(); p++){
    S.add(new ArrayList<Integer>());
    n[p] = 0;
 
    for(int q = 0; q < P.size(); q++){
      if (P.get(p).do_dominate(P.get(q)) && (p != q)){         // If p dominates q
        S.get(p).add(q);                                       // Add q to the set of solutions dominated by p.
      }else if(P.get(q).do_dominate(P.get(p)) && (p != q)){
        n[p]++;                                              // Increment the domination counter of p.
      }
    }
    
    if(n[p] == 0){                                           // if p belongs to the first front.
      P.get(p).set_rank(0);
      front.get(0).add(p);
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
          Q.add(q);
        }
      }
    }
    i = i + 1;
    front.add(Q);
  }
  
  return front;
}
          


//Sort by values of ith optimize function.
Individual[] sort_by_values(final List<Individual> front, final int i){
  Individual sorted_list[] = new Individual[front.size()];
  List<Double> value_list = new ArrayList<Double>();
  
  for(Individual ind : front) {
    value_list.add(ind.get_mth_function_value(i));
  }
  
  Collections.sort(value_list);
  
  for(Individual ind : front){
    int index = value_list.indexOf(ind.get_mth_function_value(i));
    for(;index < front.size(); index++){
      if(sorted_list[index] == null){
        sorted_list[index] = ind;
        break;
      }
    } //<>//
  }
  
  assert checkFull(sorted_list) : "sort is not good";

  return sorted_list;
}


// calculate crowding distance
void crowding_distance_assignment(List<Individual> front){
  Individual[] sorted_list;
  
  for(Individual ind : front){
    ind.set_distance(0.0d);                                                                     // initialize distance.
  }
  
  for(int i = 0; i < num_of_object; i++) {
    sorted_list = sort_by_values(front, i);       // sort using each objective value.
    assert sorted_list.length ==  front.size(): "crowding_distance_assignment() : Size of list is different";

    //printIndividual(sorted_list, i);
    double f_min = sorted_list[0].get_mth_function_value(i);
    double f_max = sorted_list[sorted_list.length - 1].get_mth_function_value(i);
    
    sorted_list[0].set_distance(Double.POSITIVE_INFINITY);                                    // so that boundary points are always selected.
    sorted_list[sorted_list.length - 1].set_distance(Double.POSITIVE_INFINITY);
    
    for(int j = 1; j < sorted_list.length - 1; j++) {         // for all other points.
      if(f_max - f_min != 0){
        double after_val = sorted_list[j + 1].get_mth_function_value(i);
        double befour_val = sorted_list[j - 1].get_mth_function_value(i);
        sorted_list[j].set_distance( sorted_list[j].get_distance() + (after_val - befour_val) / (f_max - f_min));
      }
    }
  }
}

Individual tournament(Individual a, Individual b) {
  Random rnd = new Random();
  int flag = 0;
  
  if(a.do_new_dominate(b))
    flag = 1;
  else if(b.do_new_dominate(a))
    flag =  0;
  else if(rnd.nextInt(10) < 5)
    flag =  1;
    
  List<Double> ret = new ArrayList<Double>();
  if(flag == 1){
    for(int i = 0; i < x_num; i++)
      ret.add(a.get_ith_arg(i));
  }else{
    for(int i = 0; i < x_num; i++)
      ret.add(b.get_ith_arg(i));
  }

  return new Individual(ret);
}


// Mutation
Individual mutation(final Individual a){
  List<Double> ret = new ArrayList<Double>();
  Random rnd = new Random();

  for(int i = 0; i < x_num; i++) {
    if(i == rnd.nextInt(x_num))
      ret.add(rnd.nextDouble()*(x_max - x_min) + x_min);
    else
      ret.add(a.get_ith_arg(i));
  }
  
  return new Individual(ret);
}
    
    
// Crossover
Individual crossover(Individual a, Individual b){
  Random rnd = new Random();
  int index = rnd.nextInt(x_num*2);
  List<Double> ret = new ArrayList<Double>();
  
  for(int i = 0; i< x_num; i++) {
    if(i == index)
      ret.add(b.get_ith_arg(i));
    else
      ret.add(a.get_ith_arg(i));
  }
  
  return new Individual(ret);
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

// Sort by crowding distance. 
List<Individual> new_dominate_sort(final List<Individual> list){
  List<Individual> ret = new ArrayList<Individual>();
  double val[] = new double[list.size()];
  
  for(int i = 0; i < list.size(); i++)
    val[i] = list.get(i).get_distance();
  
  for(int i = 0; i < list.size(); i++){
    int index = max(val);
    val[index] = Double.NEGATIVE_INFINITY;
    ret.add(list.get(index));
  }
  
  assert list.size() == ret.size() : "new_dominate_sort() : Size of ret list is different.";
  return ret;
}

// Execute crossover and mutation. Make offspring from pop.
List<Individual> selection(final List<Individual> pop){
  List<Individual> ret = new ArrayList<Individual>();
  
  List<Individual> pop_tmp1 = pop;
  List<Individual> pop_tmp2 = pop;
  Individual parent1, parent2;
  Random rnd = new Random();
  
  for(int i = 0; i < pop.size(); i++){
    int r = rnd.nextInt(pop.size()- i) + i;
    Individual tmp = pop_tmp1.get(r);
    pop_tmp1.set(r, pop_tmp1.get(i));
    pop_tmp1.set(i, tmp);
    
    r = rnd.nextInt(pop.size()- i) + i;
    tmp = pop_tmp2.get(r);
    pop_tmp2.set(r, pop_tmp2.get(i));
    pop_tmp2.set(i, tmp);
    
  }
  
  for(int i = 0; i < pop.size(); i+=4){
    parent1 = tournament(pop_tmp1.get(i), pop_tmp1.get(i+1));
    parent2 = tournament(pop_tmp1.get(i+2), pop_tmp1.get(i+3));
    ret.add(tournament(parent1, parent2));
    ret.add(crossover(parent1, parent2));
    
    parent1 = tournament(pop_tmp2.get(i), pop_tmp2.get(i+1));
    parent2 = tournament(pop_tmp2.get(i+2), pop_tmp2.get(i+3));
    ret.add(tournament(parent1, parent2));
    ret.add(crossover(parent1, parent2));
  }
  
  for(int i = 0; i < pop.size(); i++) {
    if(rnd.nextInt(10) < mutation_prob)
      ret.set(i, mutation(ret.get(i)));
  }
  
  assert ret.size() == population_size : "make_new_pop() : Size of ret list is different.";
  
  return ret;
}

// Draw graph.
void draw_graph(){
  final int padding = 50;
  final int axis_x = height - padding;
  final int axis_y = padding;
  
  stroke(0, 0, 0);
  strokeWeight(1);
  line(0, axis_x, width, axis_x);
  line(axis_y, 0, axis_y, height);
  
  textSize(12);
  text("Generation: " + generation_num, width - padding*2.5, padding/2); 
  generation_num++;
  
  strokeWeight(0.1);
  for(int i = 0; i < height; i+=zoom){
    line(0, i, width, i);
  }
  for(int i = 0; i < width; i+=zoom){
    line(i, 0, i, height);
  }
  
  strokeWeight(5);
  for(Individual ind : population)
    point((float)(ind.get_mth_function_value(0)*zoom + axis_y), (float)(axis_x - ind.get_mth_function_value(1)*zoom));  
}

// Main part ******************************

void setup(){
  size(500, 500);
  noStroke();
  fill(0, 102, 153, 204);
  //frameRate(1);
  
  // Initialization of population.
  Random rnd = new Random();
  for(int i = 0; i < population_size; i++){
    List<Double> tmp = new ArrayList<Double>();
    for(int j = 0; j < x_num; j++){
      tmp.add(rnd.nextDouble()*(x_max - x_min) + x_min);
    }
    population.add(new Individual(tmp));
  }
  
  // Make offspring population.
  population_offspring = selection(population);
  population.addAll(population_offspring);                                   // combine parent and offspring population.
  
  assert population.size() == population_size * 2 : "setup() : Size of population is different.";
}



void draw(){
  background(255);
  List<Individual> next_p = new ArrayList<Individual>();                 // Individual = [1.1d, 3.8d, ...], population = [Individual1, Individual2, ...]
  
  assert population.size() == population_size * 2 : "draw() : Size of population + population_offspring is different.";
  List<List<Integer>> front = fast_non_dominated_sort(population);           // front = (f_0, f_1, ...). f_0 = [index_number_of_population, ...]
  assert count_front_size(front) == population_size*2 : "fast_non_dominated_sort have some problem";
  
  int i = 0;
  while(next_p.size() + front.get(i).size() <= population_size){             // until the parent population is filled.
    List<Individual> tmp = new ArrayList<Individual>();
    for(int index : front.get(i)){
      tmp.add(population.get(index));
    }
    
    crowding_distance_assignment(tmp);
    next_p.addAll(tmp);                                                      // include ith nondominated front in the parent pop.
    i++;                                                                     // check the next front for inclusion.
  }
  
  List<Individual> tmp = new ArrayList<Individual>();
  for(int index : front.get(i)){
    tmp.add(population.get(index));
  }
  
  crowding_distance_assignment(tmp);
  tmp = new_dominate_sort(tmp);
  next_p.addAll(tmp.subList(0, population_size - next_p.size()));
  
  population_offspring = selection(next_p);
  population = next_p;
  population.addAll(population_offspring);                                   // combine parent and offspring population.
  
  assert population.size() == population_size * 2 : "draw() : Size of population is different.";
    
  draw_graph();     // show results.
  saveFrame("frames/####.tif");
}