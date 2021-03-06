{-# LANGUAGE
    KindSignatures
  , NoMonomorphismRestriction
  , UndecidableInstances
  , ConstraintKinds
  , FlexibleContexts
  , FlexibleInstances
  , MultiParamTypeClasses
  , DataKinds
  , TypeOperators
  , TypeFamilies
  , RebindableSyntax
  , ScopedTypeVariables
    -- hm, this one looks evil
  , IncoherentInstances
  #-}
module State where

import Prelude hiding (return, pure, (>>), (>>=))
import TypeLevelSets hiding (Nub, nub, Unionable, Nubable, union, AsSet)
import EffSys hiding (Effect, Eff, R, Update, update, put)
import qualified EffSys (Effect)
import Data.Monoid ((<>))

data Eff = R | W | RW

data Effect (s :: Eff) = Eff

data (:!) (a :: *) (s :: Eff) = a :! (Effect s)
infixl 3 :!
-- note that ":!" binds tighter than ":->"
-- so "v :-> a :! f" means "v :-> (a :! f)"
-- reads "variable v has type a and effect action f"

type family Reads t where
  Reads '[] = '[]
  Reads ((v :-> a :! 'R) ': s) = (v :-> a :! 'R) ': (Reads s)
  Reads ((v :-> a :! 'RW) ': s) = (v :-> a :! 'R) ': (Reads s)
  Reads ((v :-> a :! 'W) ': s) = Reads s

type family Writes t where
  Writes '[] = '[]
  Writes ((v :-> a :! 'W) ': s) = (v :-> a :! 'W) ': (Writes s)
  Writes ((v :-> a :! 'RW) ': s) = (v :-> a :! 'W) ': (Writes s)
  Writes ((v :-> a :! 'R) ': s) = Writes s

type family Nub t where
  Nub '[] = '[]
  Nub '[e] = '[e]
  Nub (e ': e ': s) = Nub (e ': s)
  Nub ((v :-> a :! f) ': (v :-> a :! g) ': s) =
      -- it is usually not making sense that you have two abstract types
      -- like "f" and "g" and you end up with a concrete one "RW"
      -- but think: if "f" and "g" are the same, it would have been
      -- captures by the previous pattern matching,
      -- so here it is safe to assume that "f" and "g" are different
      -- with this idea in mind, it's not hard to see the result of "f" + "g"
      -- must be RW
      Nub ((v :-> a :! 'RW) ': s)
  Nub (e ': f ': s) = e ': (Nub (f ': s))

class Nubable t v where
    nub :: Set t -> Set v

instance Nubable '[] '[] where
    nub Empty = Empty

instance Nubable '[e] '[e] where
    nub (Ext e Empty) = Ext e Empty
    nub _ = error "impossible"

instance Nubable ((k :-> b :! s) ': as) as' =>
    Nubable ((k :-> a :! s) ': (k :-> b :! s) ': as) as' where
    nub (Ext _ (Ext x xs)) = nub (Ext x xs)
    nub _ = error "impossible"

instance Nubable ((k :-> a :! 'RW) ': as) as' =>
    Nubable ((k :-> a :! s) ': (k :-> a :! t) ': as) as' where
    nub (Ext _ (Ext (k :-> (a :! _)) xs)) = nub (Ext (k :-> (a :! (Eff:: Effect 'RW))) xs)
    nub _ = error "impossible"

instance Nubable ((j :-> b :! t) ': as) as' =>
    Nubable ((k :-> a :! s) ': (j :-> b :! t) ': as) ((k :-> a :! s) ': as') where
    nub (Ext (k :-> (a :! s)) (Ext (j :-> (b :! t)) xs)) =
        Ext (k :-> (a :! s)) (nub (Ext (j :-> (b :! t)) xs))
    nub _ = error "impossible"

type UnionS s t = Nub (Sort (Append s t))
type Unionable s t =
    ( Sortable (Append s t)
    , Nubable (Sort (Append s t)) (Nub (Sort (Append s t)))
    , Split s t (Union s t))

class Update s t where
    update :: Set s -> Set t

instance Update xs '[] where
    update _ = Empty

instance Update '[e] '[e] where
    update s = s

{-
  this State monad is more flexible than the State monad we usually see
  because it allows storing value of different types under the same "var" label
  but this is at the cost of code complexity:
  personally I think the implementation of Update is messy and
  it's hard to just look at the code and tell what's going on
-}

{-
  note that "update" function has only one use site in "intersectR"
  in which we have "update :: Set (Sort (Append s t)) -> Set t"
  and additionally "Writes s ~ s" and "Reads t ~ t".

  asuming "Sort" is stable, we will be only dealing with either "W" or "R"
  under same "Var". and "W" always appears before "R" (again under same "Var")

  let's denote Update like an arrow: "~~>"

  if [v :-> a :! R, ...] ~~> as'
  then [v :-> a :! W, v :-> b :! R, ...] ~~> as'
  (net effect: changing "[v :-> a :! W, v :-> b :! R]" to "[v :-> a :! R]")

  interpretation: if the previous computation writes to v (i.e. "v :-> a :! W")
  and the next computation reads from v (i.e. "v :-> b :! R")
  then for the next computation, it should read from v (expecting type "a")
  (I think, in other words, a ~ b)
-}
instance Update ((v :-> a :! 'R) ': as) as' =>
  Update (  (v :-> a :! 'W)
         ': (v :-> b :! 'R)
         ': as) as' where
    -- for all wildcards, we've already know what it must be
    -- so there's no point to check them again
    update (Ext (v :-> (a :! _)) (Ext _ xs)) =
        update (Ext (v :-> (a :! (Eff :: Effect 'R))) xs)
    update _ = error "impossible"
{-
  if [u :-> b :! s, ...] ~~> as'
  then [v :-> a :! W, u :-> b :! s, ...] ~~> as'
  (net effect: removing "v :-> a :! W" in front)

  interpretation: note that "u" is not unifiable with "v" (otherwise the previous instance
  would have captured it), and therefore "v :-> a :! W" is without a corresponding
  read effect. in this case simply removing it from the list will do.
-}
instance Update ((u :-> b :! s) ': as) as' =>
  Update ((v :-> a :! 'W) ': (u :-> b :! s) ': as) as' where
    update (Ext _ (Ext e xs)) = update (Ext e xs)
    update _ = error "impossible"

{-
  if [u :-> b :! s, ...] ~~> as'
  then [v :-> a :! R, u :-> b :! s, ...] ~~> (v :-> a :! R) : as'
  (net effect: "v :-> a :! R" is kept and we will recurse on rest of the list)

  interpretation: similarly, "v :-> a :! R" does not have a corresponding write effect
  and we keep it.
-}
instance Update ((u :-> b :! s) ': as) as' =>
  Update ((v :-> a :! 'R) ': (u :-> b :! s) ': as)
         ((v :-> a :! 'R) ': as') where
    update (Ext e (Ext e' xs)) = Ext e (update (Ext e' xs))
    update _ = error "impossible"

-- a bit more complicated than what's written in the paper
type IntersectR s t = (Sortable (Append s t), Update (Sort (Append s t)) t)

intersectR :: forall s t.
              ( Writes s ~ s, Reads t ~ t
              , IsSet s, IsSet t, IntersectR s t) =>
              Set s -> Set t -> Set t
intersectR s t =
    -- "update"'s type does not have to be explicit,
    -- here I just think it's helpful to write it out
    (update :: Set (Sort (Append s t)) -> Set t)
      (bsort (append s t))

-- "s" is a list of things that the computation can read and write
-- and "Reads s" and "Writes s" break the list into two
data State s a = State
  { runState :: Set (Reads s) -> (a, Set (Writes s)) }

-- this looks exactly the same, but recall that we have defined our own "nub"
-- so this function has to be rewritten.
union :: (Unionable s t) => Set s -> Set t -> Set (UnionS s t)
union s t = nub (bsort (append s t))

instance EffSys.Effect State where
    type Inv State s t =
        ( IsSet s, IsSet (Reads s), IsSet (Writes s)
        , IsSet t, IsSet (Reads t), IsSet (Writes t)
        , Reads (Reads t) ~ Reads t
        , Writes (Writes s) ~ Writes s
        , Split (Reads s) (Reads t) (Reads (UnionS s t))
        , Unionable (Writes s) (Writes t)
        , IntersectR (Writes s) (Reads t)
        , Writes (UnionS s t) ~ UnionS (Writes s) (Writes t))

    type Unit State = '[]
    type Plus State s t = UnionS s t
    pure x = State (\Empty -> (x, Empty))
    (State e) >>= k = State (\st ->
        -- the computation consists of two parts:
        -- (1) first we need to execute "e"
        -- (2) then "k" is executed with the result
        --     we got from running "e".
        let -- 2 computations to run, so "st" is splitted into 2
            (sR,tR) = split st
            -- run first one, get result "a" and resulting state "sW"
            (a,sW) = e sR
            -- then we want to continue by running "k a", but note that
            -- the resulting state "sW" should not be dropped, and we also need to
            -- use "tR" somehow.

            -- if we write "(b,tW) = runState (k a) tR"
            -- instead of the following line, it also typechecks.
            -- but I think doing so will cause the effect of running the first computation
            -- be totally dropped..
            -- maybe we have lost some safty that the type system can offer...
            (b,tW) = runState (k a) (sW `intersectR` tR)
        in
        -- after all the computations are done, we wish to combine two resulting states
        -- so that's what "union" does
        (b,sW `union` tW))

get :: Var v -> State '[v :-> a :! 'R] a
get _ = State $ \ (Ext (_ :-> a :! _) xs) -> (a, xs)

put :: Var v -> a -> State '[v :-> a :! 'W] ()
put _ a = State $ \xs -> ((), Ext (Var :-> a :! Eff) xs)

-- there is a subtle different between this one and regular "modify":
-- the effect "RW" will be enforced even if the modifier function is just a "id"
-- so actually the type signature would sometimes overestimate the actual effect.
modify :: Var v -> (a -> a) -> State '[v :-> a :! 'RW] a
modify var f = get var >>= \oldV -> put var (f oldV) >> pure oldV

state :: Var v -> (s -> (a,s)) -> State '[v :-> s :! 'RW] a
state var sf = get var >>= \oldS ->
    let (v, newS) = sf oldS in put var newS >> pure v

varC = Var :: Var "count"
varS = Var :: Var "out"

incC :: State '["count" :-> Int :! 'RW] ()
incC = modify varC succ >>= \_ -> pure ()

-- seems a mixture of varC and varS doesn't work?
test1 :: State '["count" :-> Int :! 'RW, "out" :-> String :! 'W] Int
test1 = do
    put varC (10 :: Int)
    -- the following line looks good but it actually isn't
    -- even after changing the "out" variable with "RW" effect,
    -- this won't type check
    -- (the following line doesn't work with effect-monad-0.7.0.0)
    -- modify varC id
    put varS "String"
    get varC

writeS :: [a] -> State '["out" :-> [a] :! 'RW] ()
writeS y = do
    x <- get varS
    put varS (x <> y)

-- the following line won't work:
-- write :: [a] -> State '["out" :-> [a] :! 'RW, "count" :-> Int :! 'RW] ()
-- but if we explicitly sort the it, then it will:
-- write :: [a] -> State (Sort '["out" :-> [a] :! 'RW, "count" :-> Int :! 'RW]) ()

write :: [a] -> State '["count" :-> Int :! 'RW, "out" :-> [a] :! 'RW] ()
write x = writeS x >> incC
