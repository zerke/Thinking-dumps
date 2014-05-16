:- initialization(['4_4_1_a_sample_database.pl']).
:- initialization(run).

% two people live near each other
lives-near(Person1,Person2) :-
    address(Person1,Town,_),
    address(Person2,Town,_),
    \+(Person1 = Person2).

% a "wheel" in an organization
%   if he supervises someone who is in turn a supervisor
wheel(P) :-
    supervisor(Mid,P),
    supervisor(_,Mid).

% a staff person is outranked by a boss
%   in the organization if:
% - the boss is the person's supervisor
% - or if the person's supervisor is
%   outranked by the boss
outranked-by(StaffPerson,Boss) :-
    supervisor(StaffPerson,Boss);
    (supervisor(StaffPerson,Mid),
     outranked-by(Mid,Boss)).

% query all possible combinations
query(findall([P1,P2], lives-near(P1,P2), _)).
query(findall(P, wheel(P), _)).
query(findall([S,B], outranked-by(S,B), _)).

% query just for some cases
query(findall(X, lives-near(X,bitdiddleBen), _)).
query(findall(P, (job(P,[computer,programmer]), lives-near(P,bitdiddleBen)), _)).
