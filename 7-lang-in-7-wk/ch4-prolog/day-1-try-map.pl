% init
:- initialization(['common.pl']).
:- initialization(run).

different(red  , green).
different(red  , blue ).
different(green, red  ).
different(green, blue ).
different(blue , red  ).
different(blue , green).

coloring(Alabama, Mississippi, Georgia, Tennessee, Florida) :-
	different(Mississippi, Tennessee  ),
	different(Mississippi, Alabama    ),

	different(Alabama    , Tennessee  ),
	different(Alabama    , Mississippi),
	different(Alabama    , Georgia    ),
	different(Alabama    , Florida    ),
	
	different(Georgia    , Florida    ),
	different(Georgia    , Tennessee  ).


query(findall(
	(Alabama, Mississippi, Georgia, Tennessee, Florida),
	coloring(Alabama, Mississippi, Georgia, Tennessee, Florida),
	X)).

query_u( 'coloring(Alabama, Mississippi, Georgia, Tennessee, Florida).' ).
