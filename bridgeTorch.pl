:- dynamic(crossTime/2).
:- dynamic(maxTime/1).
:- dynamic(maxTorch/1).
:- dynamic(fst/1).
:- dynamic(snd/1).

% Temporary Settings
maxTorch(2).
maxTime(42).
crossTime(alberto,1).
crossTime(beatriz,2).
crossTime(carlos,5).
crossTime(dora,10).
crossTime(emilio,15).
crossTime(julio,20).

/*
*  INSTRUCTIONS:
*  If temporary settings are active:
*      run any of: solveDepthFirst., solveHillClimb., solveBestFirst.
*  Else:
*      run setup. then any of: solveDepthFirst., solveHillClimb., solveBestFirst.
*      to change the setup run reset. then setup.
*/

% Insert settings
setup :- 
    insertPerson("Y"),
    insertTimeLimit,
    insertTorchLimit.

insertPerson("Y") :-
    write("Ingrese el nombre de una persona: "),
    read(Name),
    atom(Name),
    write("Ingrese el tiempo que tarda en cruzar el puente: "),
    read(Time),
    rational(Time),
    assert(crossTime(Name, Time)),
    write("Desea ingresar otra persona? (Y/N): "),
    read(X),
    insertPerson(X).

insertPerson("N").

insertTimeLimit :-
    write("Ingrese el limite de tiempo para cruzar el puente: "),
    read(Time),
    rational(Time),
    assert(maxTime(Time)).

insertTorchLimit :-
    write("Ingrese la cantidad de personas que puede iluminar la antorcha: "),
    read(Torch),
    integer(Torch),
    assert(maxTorch(Torch)).

setFastest :-
    retractall(fst(_)),
    retractall(snd(_)),
    findall(Time, crossTime(_, Time), Times),
    minList(Times, X),
    crossTime(NameFst, X),!,
    assert(fst(NameFst)),
    select(X, Times, NewTimes),!,
    minList(NewTimes, Y),
    crossTime(NameSnd, Y),
    NameFst \= NameSnd,!,
    assert(snd(NameSnd)).

% Solve and print
solveDepthFirst :-
    initial(InitState),
    statistics(walltime, [TimeSinceStart | [TimeSinceLastCall]]),
    solveDF(InitState, [], Sol),
    statistics(walltime, [NewTimeSinceStart | [ExecutionTime]]),
    forall(member(X, Sol), (write(X), nl)),
    write('Execution took '), write(ExecutionTime), write(' ms.'), nl.

solveHillClimb :-
    initial(InitState),
    setFastest,
    statistics(walltime, [TimeSinceStart | [TimeSinceLastCall]]),
    solveHC(InitState, [], Sol),
    statistics(walltime, [NewTimeSinceStart | [ExecutionTime]]),
    forall(member(X, Sol), (write(X), nl)),
    write('Execution took '), write(ExecutionTime), write(' ms.'), nl.

solveBestFirst :-
    initial(InitState),
    setFastest,
    statistics(walltime, [TimeSinceStart | [TimeSinceLastCall]]),
    solveBF([point(InitState, [InitState], 0)], [], Sol),
    statistics(walltime, [NewTimeSinceStart | [ExecutionTime]]),
    forall(member(X, Sol), (write(X), nl)),
    write('Execution took '), write(ExecutionTime), write(' ms.'), nl.

% Remove all settings
reset :-
    retractall(crossTime(_,_)),
    retractall(maxTime(_)),
    retractall(maxTorch(_)).

% Start and end states
initial([0, l, Names, []]) :-
    findall(Name, crossTime(Name, _), Names).
    
final([_, r, [], _]).

/*
*  DEPTH FIRST SEARCH
*/

% Recursively checks if a path can be made through all node combinations
solveDF(Node, Path, [Node|Path]) :- 
    final(Node).
solveDF(Node, Path, Sol) :- 
    move(Node, Movement),
    update(Node, Movement, NewNode),
    legal(NewNode),
    not(member(NewNode, Path)),
    solveDF(NewNode, [Node|Path], Sol).

% Calculate the max amount of crossers permitted and generate all combs for that amount
move([_, l, Left, _], Movement) :-
    crossers(Left, N),

    % This method generates all combs for the max amount permitted up to the least 
%    inverseBetween(1, N, X),
%    comb(X, Left, Movement).

    % This method cuts the posibility tree by never crossing less than the max amount permitted
    comb(N, Left, Movement).
move([_, r, _, Right], Movement) :-
    
    % This method generates all combs for the least amount permitted up to the max 
%    crossers(Right, N),
%    between(1, N, X),
%    comb(X, Right, Movement).

    % This method cuts the posibility tree by never crossing more than 1
    comb(1, Right, Movement).

% Moves people from one side to another and updates the total time based on the slowest
update([Time1, l, Left1, Right1], Movement, [Time2, r, Left2, Right2]) :-
    take(Movement, Left1, Left2),
    append(Movement, Right1, Right2),
    findTimes(Movement, Times),
    maxList(Times, MaxTime),
    Time2 is Time1 + MaxTime.
update([Time1, r, Left1, Right1], Movement, [Time2, l, Left2, Right2]) :-
    take(Movement, Right1, Right2),
    append(Movement, Left1, Left2),
    findTimes(Movement, Times),
    maxList(Times, MaxTime),
    Time2 is Time1 + MaxTime.

% Checks if the total time is less than the max time
legal([Time, _, _, _]) :-
    maxTime(X),
    Time =< X.

% If there are more people than the max capacity, cross the max
% If there are less people than the max capacity, cross them all
crossers(Group, X) :-
    maxTorch(N),
    length(Group, Len),
    Len >= N,
    X is N.
crossers(Group, X) :-
    maxTorch(N),
    length(Group, Len),
    Len < N,
    X is Len.

% Generates an array with the times of a group of people
findTimes([], []).
findTimes([Name|People], [Time|CrsTimes]) :- 
    crossTime(Name, Time),
    findTimes(People, CrsTimes).

% Generates all combinations of N elements in a list
comb(N, List, X) :-
    length(X, N),
    mem1(X, List).

mem1([], Y).
mem1([H|T], Y) :- 
    member(H, Y),
    rest(H, Y, New),
    mem1(T, New).

rest(A, List, R) :- 
    append(_, [A|R], List), !.

% Removes the given elements from a list
take(Elem, List, X) :- 
    findall(Z, (member(Z, List), not(member(Z, Elem))), X).

% Obtains the max number from a list
maxList(List, M):- 
    member(M, List), 
    findall(X, (member(X, List), X > M), New),
    length(New, 0).

% Obtains the min number from a list
minList(List, M):- 
    member(M, List), 
    findall(X, (member(X, List), X < M), New),
    length(New, 0).

% Obtains all numbers in an inclusive range ordered from largest to smallest
inverseBetween(L, H, H) :- 
    H >= L.
inverseBetween(L, H, X) :- 
    H1 is H - 1, 
    H1 >= L, 
    inverseBetween(L, H1, X).

/*
*  HILL CLIMBING
*/

% Recursively checks if a path can be made through all node combinations in order according to the best value of the next moves
solveHC(Node, Path, [Node|Path]) :- 
    final(Node).
solveHC(Node, Path, Sol) :- 
    hillClimb(Node, Movement),
    update(Node, Movement, NewNode),
    legal(NewNode),
    not(member(NewNode, Path)),
    solveHC(NewNode, [Node|Path], Sol).

% Generates all node combinations from a node and orders them according to value
hillClimb(Node, Movement) :-
    findall(X, move(Node, X), Moves),
    evaluateOrder(Node, Moves, [], OrderedMoves),
    member((Movement, _), OrderedMoves).

% Recursively evaluates all moves and orders the list by highest value
evaluateOrder(_, [], Accumulated, Accumulated).
evaluateOrder(Node, [Movement|Moves], Accumulated, OrderedMoves) :-
    update(Node, Movement, NewNode),        
    value(Node, NewNode, Value),               
    insertPair((Movement, Value), Accumulated, Z), 
    evaluateOrder(Node, Moves, Z, OrderedMoves).

% Inserts a tuple in an ordered list based on the second element
insertPair(MV, [], [MV]).
insertPair((M, V), [(M1, V1)|MVs], [(M, V), (M1, V1)|MVs]) :-
    V >= V1.
insertPair((M, V), [(M1, V1)|MVs], [(M1, V1)|MVs1]) :-
    V < V1,
    insertPair((M, V), MVs, MVs1).

% When the torch is on the right
% Pick the fastest group that leaves the most people on the right
value([_, _, _, _], [Time, l, _, Right], Value) :-
    length(Right, Len),
    Value is 0 - Time + (Len * 100).

% When the torch is on the left and the first and second fastest are on the same side
% Pick the group that leaves the slowest people on the left and adds the most to the right
value([_, _, CurrentLeft, CurrentRight], [_, r, Left, Right], Value) :-
    snd(B),
    fst(A),
    (
        (member(B, CurrentLeft),
        member(A, CurrentLeft));
        (member(B, CurrentRight),
        member(A, CurrentRight))
    ),
    length(Right, Len),
    findTimes(Left, Times),
    sumList(Times, SumOfTimes),
    Value is SumOfTimes + (Len * 100).

% When the torch is on the left and the first and second fastest are on opposite sides
% Pick the group that leaves the fastest people on the left and adds the most to the right
value([_, _, CurrentLeft, CurrentRight], [_, r, Left, Right], Value) :-
    snd(B),
    fst(A),
    (
        (member(B, CurrentRight),
        member(A, CurrentLeft));
        (member(B, CurrentLeft),
        member(A, CurrentRight))
    ),
    length(Right, Len),
    findTimes(Left, Times),
    sumList(Times, SumOfTimes),
    Value is 0 - SumOfTimes + (Len * 100).

% Generates the sum of all elements in a list
sumList([], 0).
sumList([H|T], Sum) :-
    sumList(T, Rest),
    Sum is H + Rest.

/*
*  BEST FIRST SEARCH
*/

% Recursively checks if a path can be made through all node combinations in order according to the best value of all
solveBF([point(Node, Path, _)|_], _, Path) :- 
    final(Node).
solveBF([point(Node, Path, _)|Frontier], History, Sol) :- 
    findall(X, move(Node, X), Moves),     
    updates(Moves, Path, Node, NewNodes),   
    legals(NewNodes, ValidNodes),             
    news(ValidNodes, History, NewValidNodes),                            
    evaluates(Node, NewValidNodes, Points, Max, Min),
    rescale(Max, Min, Points, NewPoints),     
    inserts(NewPoints, Frontier, NewFrontier), 
    solveBF(NewFrontier, [Node|History], Sol). 

% Recursively updates all movements and adds them to the path
updates([], _, _, []).
updates([Movement|Moves], Path, Node, [(NewNode, [NewNode|Path])|NewNodes]) :-
    update(Node, Movement, NewNode),         
    updates(Moves, Path, Node, NewNodes). 

% Recursively removes ilegal nodes
legals([], []).  
legals([(Node, Path)|Nodes], [(Node, Path)|ValidNodes]) :-
    legal(Node),
    legals(Nodes, ValidNodes).
legals([(Node, _)|Nodes], ValidNodes) :-
    not(legal(Node)),
    legals(Nodes, ValidNodes).

% Recursively removes repeated nodes
news([], _, []).
news([(Node, _)|Nodes], History, NewNodes) :-
    member(Node, History),
    news(Nodes, History, NewNodes).
news([(Node, Path)|Nodes], History, [(Node, Path)|NewNodes]) :-
    not(member(Node, History)),
    news(Nodes, History, NewNodes).
    
% Recusively generates the value of each node and the max and min from the list
evaluates(_, [], [], 0, X) :-
    X is inf.
evaluates(CurrentNode, [(Node, Path)|Nodes], [point(Node, Path, Value)|Points], MaxValue, MinValue) :-
    value(CurrentNode, Node, Value),                
    evaluates(CurrentNode, Nodes, Points, OldMaxValue, OldMinValue),
    MaxValue is max(Value, OldMaxValue),
    MinValue is min(Value, OldMinValue).

% Rescales all values into 1-10, based on the best and worst move made
rescale(_, _, [], []).
rescale(Max, Min, [point(Node, Path, Value)|Points], [point(Node, Path, ScaledValue)|T]) :-
    ScaledValue is (10 / (Max - (Min - 1))) * (Value - Max) + 10,
    rescale(Max, Min, Points, T).
    
% Inserts orderly into the frontier according to value
inserts([], Frontier, Frontier).
inserts([Point|Points], Frontier, NewFrontier) :-
    insertPoint(Point, Frontier, Accumulated),  
    inserts(Points, Accumulated, NewFrontier).    

% Insert a point in an ordered list according to value
insertPoint(Point, [], [Point]).
insertPoint(Point, [H|Points], [Point, H|Points]) :-
    lessThan(H, Point).
insertPoint(Point, [H|Points], [H|T]) :-
    lessThan(Point, H),
    insertPoint(Point, Points, T).
insertPoint(Point, [H|Points], [Point, H|Points]) :-
    equal(H, Point).
insertPoint(Point, [H|Points], [H|Points]) :-
    identical(Point, H).

% Compares two points
lessThan(point(N1, _, V1), point(N2, _, V2)) :- 
    N1 \= N2, 
    V1 < V2.
equal(point(N1, _, V1), point(N2, _, V2)) :- 
    N1 \= N2, 
    V1 =:= V2.
identical(point(N, _, V), point(N, _, V)).


    


