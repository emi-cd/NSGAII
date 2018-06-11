import java.util.ArrayList;
import java.util.List;
import java.util.Collections;
import java.util.Random;


// **********************************


final int population_size = 50;
final int max_gen = 500;
final int num_of_object = 2;     // The number of object;
final int mutation_prob = 3;     // 3/10
final int x_min = -100;          // Variable bounds
final int x_max = 100;

List<List<Integer>> population = new ArrayList<List<Integer>>();
List<List<Integer>> population_offspring = new ArrayList<List<Integer>>();

// Function to optimize (SCH)
int function1(final List<Integer>x){
  return x.get(0) * x.get(0);
}

int function2(final List<Integer> x){
  return (x.get(0) - 2) * (x.get(0) - 2);
}

int optimize_function(final List<Integer> x, final int i){
  int ret = 0;
  if(i == 1)
    ret =  function1(x);
  else if(i == 2)
    ret =  function2(x);
    
  return ret;
}

// Whether a dominates b.
boolean dominate(final List<Integer> a, final List<Integer> b){ 

  if((optimize_function(a, 1) < optimize_function(b, 1)) || (optimize_function(a, 2) < optimize_function(b, 2)))
    return false;
  
  return true;
}

// ******************************************



// Function to carry out NSGA-II's fast non dominated sort
List<List<Integer>> fast_non_dominated_sort(final List<List<Integer>> P){
  List<List<Integer>> S = new ArrayList<List<Integer>>();
  List<List<Integer>> front = new ArrayList<List<Integer>>();
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
List<Integer> sort_by_values(final List<List<Integer>> front, final int i){
  List<Integer> sorted_list = new ArrayList<Integer>();
  List<Integer> value_list = new ArrayList<Integer>();
  List<Integer> tmp_list = new ArrayList<Integer>();
  int val = 0;
  
  for(List<Integer> arg : front) {
    val = optimize_function(arg, i);
    value_list.add(val);
    tmp_list.add(val);
  }
  Collections.sort(tmp_list);
  
  for(int t : tmp_list){
    sorted_list.add(value_list.indexOf(t));
  }
  
  return sorted_list;
}


// Function to calculate crowding distance
float[] crowding_distance_assignment(List<List<Integer>> front){
  float[] distance = new float[front.size()];
  List<Integer> sorted_list;
  
  for(int i = 0; i < num_of_object; i++) {
    // Function number start from 1, so I add 1 below.
    sorted_list = sort_by_values(front, i + 1);

    int f_min = front.get(sorted_list.get(0)).get(i);
    int f_max = front.get(sorted_list.get(sorted_list.size()) - 1).get(i);
  
    distance[sorted_list.get(0)] = 888888888;
    distance[sorted_list.get(sorted_list.size()) - 1] = 88888888;
    
    for(int j = 1; j < sorted_list.size() - 1; j++) {
      distance[j] = distance[j] + (sorted_list.get(j - 1) - sorted_list.get(j + 1))/ (f_max - f_min);
    }
  }
  
  return distance;
}

// Function to carry out the mutation operator
List<Integer> mutation(List<Integer> a){
  List<Integer> ret = new ArrayList<Integer>();
  Random rnd = new Random();
  
  for(int i = 0; i < num_of_object; i++) {
    if(rnd.nextInt(10) < mutation_prob)
      ret.add(rnd.nextInt(x_max - x_min) - x_min);
    else
      ret.add(a.get(i));
  }
  
  return ret;
}
    
    
// Function to carry out the crossover
List<Integer> crossover(List<Integer> a, List<Integer> b){
  Random rnd = new Random();
  int index = rnd.nextInt(num_of_object * 2);
  List<Integer> ret = new ArrayList<Integer>();
  
  if(index < num_of_object){
    for(int i = 0; i< num_of_object; i++) {
      if(i == index)
        ret.add(b.get(i));
      else
        ret.add(a.get(i));
    }
  }
  
  return ret;
}

// Main part ******************************

void setup(){
  size(200, 200);
  noStroke();
  fill(0, 102, 153, 204);
  frameRate(1);
  
  // Initialization
  Random rnd = new Random();
  for(int i = 0; i < population_size; i++){
    List<Integer> indivisual = new ArrayList<Integer>();
    for(int j = 0; j < num_of_object; j++) {
      int val = rnd.nextInt(x_max - x_min) - x_min;
      indivisual.add(val);
    }
    population.add(indivisual);
  }
}

void draw(){
  background(255);
  
  List<List<Integer>> next_p = new ArrayList<List<Integer>>();
  List<List<Integer>> next_offspring = new ArrayList<List<Integer>>();
  
  population.addAll(population_offspring);
  List<List<Integer>> front = fast_non_dominated_sort(population);
  
  int i = 0;
  while(next_p.size() + front.get(i).size() <= population_size){
    List<List<Integer>> tmp = new ArrayList<List<Integer>>();
    for(int index : front.get(i))
      tmp.add(population.get(index));
      
    crowding_distance_assignment(tmp);
    next_p.addAll(tmp);
    i++;
  }
  // TODO
  next_p.addAll(front.get(i).sublist())
}