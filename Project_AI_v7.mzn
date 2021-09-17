include "globals.mzn";
% Constants

int: room_cost = 200;
int: n_interviews = 3;
int: total_Slots =20;
set of int: Preference = 1..5;
set of int: Slot = 1..20;


% Parameters

int: n_students;
int: n_companies;
set of int: Student = 1..n_students;
set of int: Company = 1..n_companies;
set of int: Interview = 1..n_interviews;

array[Student, Company] of Preference: preferences;
array[Student] of int: best_expectations;
array[Company] of int: min_capacities;
array[Company] of int: max_capacities;
array[Company] of int: attendance_costs;
array[Company] of int: parallel_limits;
array[Student] of set of Slot: slots;

% Go crazy here

% Variables


array[Student, Interview] of var Company: companies;
array[Student, Interview] of var Slot: timeslots;

%----------Constraints----------

%Constraint that for every student, for each interview, company is different and timeslot is different
constraint forall(i in Student)(
    	            alldifferent(companies[i,..])
);
constraint forall(i in Student)(
    	            alldifferent(timeslots[i,..])
);

%Constraint slots of students match timeslots
constraint forall(i in Student, j in Interview)(
                timeslots[i,j] in slots[i]
                );

                                
%global_cardinality_low_up_closed for for maximum and minimum capacities
constraint global_cardinality_low_up_closed(array1d(companies), Company, min_capacities, max_capacities);


%Constraint for parallel limit  
constraint forall(k in Company, s in Slot)(
              sum([companies[i, j] = k /\ timeslots[i,j] = s|i in Student, j in Interview])<=parallel_limits[k]
);

%constraint to keep array sorted to break symmetry
constraint forall(i in Student)(
              increasing(companies[i,..])
              );


%---------Room Cost-----------
var int: total_used_rooms;
constraint cumulative(array1d(timeslots), [1| i in 1..n_students*n_interviews], [1| i in 1..n_students*n_interviews], total_used_rooms);
var int: total_room_cost = total_used_rooms *room_cost;

%---------Disappointment Value-------
array[Student] of var 3..15 : preference_sums;
constraint forall(i in Student)(
          sum(j in Interview)(preferences[i, companies[i,j]]) = preference_sums[i]
);

var int: total_disappointment_value =sum(preference_sums) - sum(best_expectations);

%--------Attendance Cost--------
array[Company] of var Slot: first_interview;
array[Company] of var Slot: last_interview;

constraint forall(k in Company)(
              min([if companies[i, j] == k then timeslots[i,j] else total_Slots endif|i in Student, j in Interview]) = first_interview[k]
);

constraint forall(k in Company)(
              max([if companies[i, j] == k then timeslots[i,j] else 0 endif|i in Student, j in Interview]) = last_interview[k]
);

var int: total_attendance_cost = sum(j in Company)(((last_interview[j] -1) div 4 
                                             - (first_interview[j]-1) div 4 + 1)  
                                            * attendance_costs[j]);


% ------ Objective --------   
var int : obj = total_room_cost + total_attendance_cost + total_disappointment_value;
                                                                                                    
solve minimize obj;
                    
%Output
output ["Companies  - "] ++ [show(companies)] ++
           ["\n"] ++ ["Slots -      "]++[show(timeslots)] ++ ["\n" ++ show(obj)];