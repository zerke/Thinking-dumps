module StreamProcessor where

import qualified Control.Category as Cat
import Control.Arrow

{-
  a stream processor maps a stream of input messages
  into a stream of output messages, but is represented
  by an abstract data type.
-}
data SP a b
  = Put b (SP a b)
  | Get (a -> SP a b)

put :: b -> SP a b -> SP a b
put = Put

get :: (a -> SP a b) -> SP a b
get = Get

spArr :: (a -> b) -> SP a b
spArr f = sp'
  where
    -- get one value, apply "f", put it back, and repeat
    sp' = Get (\x -> Put (f x) sp')

-- I think the idea is we want to execute "Put" commands eagerly
-- so that the stream doesn't get stuck
-- also for a stream processor "SP a b",
-- it accepts "a"s on input channel and outputs "b"s on output channel.
-- they doesn't interleave in general, so there is no risk
-- taking "Put x (Get f)" apart and perform actions separately.
spCompose :: SP a b -> SP b c -> SP a c
spCompose sp1 sp2 = case sp2 of
    Put c sp2' ->
        -- sp1 >>> put c >>> sp2'
        -- is the same as:
        -- put c >>> (sp1 >>> sp2')
        -- "c" is put to the final output stream,
        -- so the order is always first "c" and then whatever "sp2" produces.
        Put c (sp1 `spCompose` sp2')
    Get f2 -> case sp1 of
        Put b sp1' ->
            -- pair of Get and Put
            sp1' `spCompose` f2 b
        Get f1 ->
            -- the original impl was:
            -- "Get (\a -> f1 a `spCompose` Get f2)"
            -- but note that "Get f2" is just "sp2" .. so let's do sharing
            -- also note that this is a case where the structure is not getting "smaller"
            Get (\a -> f1 a `spCompose` sp2)

-- TODO: again we need explanation ...
bypass :: [d] -> SP a b -> SP (a,d) (b,d)
bypass ds (Get f) = Get (\(b,d) -> bypass (ds ++ [d]) (f b))
bypass (d:ds) (Put c sp) = Put (c,d) (bypass ds sp)
bypass [] (Put c sp) = Get (\(_,d) -> Put (c,d) (bypass [] sp))

spFirst :: SP a b -> SP (a,d) (b,d)
spFirst = bypass []

instance Cat.Category SP where
    id = spArr id
    (.) = flip spCompose

instance Arrow SP where
    arr = spArr
    first = spFirst
