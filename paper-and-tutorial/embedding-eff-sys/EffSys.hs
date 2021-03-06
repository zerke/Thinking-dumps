{-# LANGUAGE
    DataKinds
  , NoMonomorphismRestriction
  , ScopedTypeVariables
  , RankNTypes
  , RebindableSyntax
  , FlexibleContexts
  , ConstraintKinds
  , MultiParamTypeClasses
  , FlexibleInstances
  , KindSignatures
  , TypeOperators
  , GADTs
  , TypeFamilies
  , PolyKinds
  , UndecidableInstances
  #-}
module EffSys where

import Prelude hiding (return, pure, (>>=), (>>))
import Data.Monoid (Sum(..))
import GHC.Exts
import GHC.TypeLits
import Data.Proxy

import TypeLevelSets

{-# ANN module "HLint: ignore Use const" #-}

class Effect (m :: k -> * -> *) where
    -- Unit together with Plus gives us a monoid that
    -- we have to define for each Effect instance.
    -- this basically specifies what to do on type level
    -- when we are composing effects together
    type Unit m :: k
    type Plus m (f :: k) (g :: k) :: k
    -- having this thing around makes it possible to add more constraints
    -- when we are composing effect together, the default definition is given
    -- by "Inv m f g = ()", which does not add any constraint at all.
    type Inv m (f :: k) (g :: k) :: Constraint
    type Inv m f g = ()
    pure :: a -> m (Unit m) a
    (>>=) :: Inv m f g => m f a -> (a -> m g b) -> m (Plus m f g) b

    (>>) :: Inv m f g => m f a -> m g b -> m (Plus m f g) b
    x >> y = x >>= (\_ -> y)

return :: Effect m => a -> m (Unit m) a
return = pure

class Subeffect (m :: k -> * -> *) f g where
    sub :: m f a -> m g a

data (v :: Symbol) :-> (t :: *) = (Var v) :-> t
infixl 2 :->
data Var (v :: Symbol) = Var

-- Writer monad by Effect typeclass
data Writer w a = Writer { runWriter :: (a, Set w) }

instance Effect Writer where
    -- constraint when composing two effects:
    -- both effects should contain a proper set
    type Inv Writer s t = (IsSet s, IsSet t, Unionable s t)
    type Unit Writer = '[]
    type Plus Writer s t = Union s t
    pure x = Writer (x, Empty)
    (Writer (a,w)) >>= k =
        let Writer (b,w') = k a
        in Writer (b, w `union` w')

-- compare type "a" and "b" (both are symbols)
-- and return "p" when "a" is not greater or "q" otherwise
type Select a b p q = Choose (CmpSymbol a b) p q

-- "Choose _ x y" is kind of like "if _ then x else y" on a type level
type family Choose (o :: Ordering) p q where
    Choose 'LT p q = p
    Choose 'EQ p q = p
    Choose 'GT p q = q

type instance Min (v :-> a) (w :-> b) =
    Select v w v w :-> Select v w a b
type instance Max (v :-> a) (w :-> b) =
    Select v w w v :-> Select v w b a

put :: Var v -> t -> Writer '[v :-> t] ()
-- it's "Writer ((), Ext v x Empty)" in the paper
-- and that doesn't type check and the arity doesn't make sense,
-- I guess this should be the original intention:
put v x = Writer ((), Ext (v :-> x) Empty)

instance (Monoid a, Nubable ((v :-> a) ': s)) =>
  Nubable ((v :-> a) ': (v :-> a) ': s) where
    nub (Ext (_ :-> a) (Ext (v :-> b) s)) =
      nub (Ext (v :-> (a `mappend` b)) s)
    nub _ = error "impossible"

select :: forall j k a b. (Chooser (CmpSymbol j k)) => Var j -> Var k -> a -> b -> Select j k a b
select _ _ = choose (Proxy :: Proxy (CmpSymbol j k))

class Chooser (o :: Ordering) where
    choose :: Proxy o -> p -> q -> Choose o p q
instance Chooser 'LT where choose _ p _ = p
instance Chooser 'EQ where choose _ p _ = p
instance Chooser 'GT where choose _ _ q = q

instance (Chooser (CmpSymbol u v)) => OrdH (u :-> a) (v :-> b) where
    minH (u :-> a) (v :-> b) = Var :-> select u v a b
    maxH (u :-> a) (v :-> b) = Var :-> select u v b a

-- TODO: we eventually will cleanup the code and separate them into
-- different module, when that's done, we can expose varX, varY whatever
-- in the testing module I guess
-- GHC should be able to infer type signature for this:
test :: Writer '["x" :-> Sum Int, "y" :-> String] ()
test = do
    put varX (Sum (42 :: Int))
    put varY "saluton"
    put varX (Sum (58 :: Int))
    put varY "_mondo"
  where
    varX = Var :: (Var "x")
    varY = Var :: (Var "y")

-- can be infered, but the type looks messy.
test2 :: (IsSet f, Unionable f '["y" :-> String])
    => (Int -> Writer f t) -> Writer (Union f '["y" :-> String]) ()
test2 f = do
    -- run an existing effect "f" with argument 3
    _ <- f 3
    -- having an effect "y" :-> String on its own
    put varY "world."
  where
    varY = Var :: (Var "y")

-- actually very similar to Subset we have defined above
class Superset s t where
    superset :: Set s -> Set t

instance Superset '[] '[] where
    superset _ = Empty

instance (Monoid a, Superset '[] s) =>
  Superset '[] ((v :-> a) ': s) where
    superset _ = Ext (Var :-> mempty) (superset Empty)

instance Superset s t =>
  Superset ((v :-> a) ': s) ((v :-> a) ': t) where
    superset (Ext x xs) = Ext x (superset xs)

instance Superset s t => Subeffect Writer s t where
    sub (Writer (a,w)) = Writer (a,superset w :: Set t)

test' :: Num a => a -> Writer '["x" :-> Sum a, "y" :-> String] ()
test' (n :: a) = do
    put varX (Sum (42 :: a))
    put varY "hello "
    put varX (Sum (n :: a))
  where
    varX = Var :: (Var "x")
    varY = Var :: (Var "y")

-- we are extending effect "x" and "y" with a "z" (with "z" having a monoid support)
test3 :: Writer '["x" :-> Sum Int, "y" :-> String, "z" :-> Sum Int] ()
test3 = sub (test2 test')

{-
  as a side note to 4.1: Data.Monoid.Last does some thing similar:
  it is a Monoid that always take the last non-empty value as its final result,
  it has the behavior we are expecting:

  - "mappend x (Last Nothing)" is always just "x"
  - "mappend _ (Last (Just v))" always ignores its first argument and
    return its second one

  so Writer alone can do the job well already with just the Last Monoid,
  but what's important about "Update" effect is that the cell doesn't
  have to hold the value of same type: you can put in a value of "Int"
  and later decide to replace it with something of type "String" instead.
-}

-- as a GADT, we get the freedom of storing value of
-- whatever type possible by making the type argument to (lifted) "Maybe" abstract
data Eff (w :: Maybe *) where
    Put :: a -> Eff ('Just a)
    NoPut :: Eff 'Nothing

data Update w a = U { runUpdate :: (a, Eff w) }

instance Effect Update where
    -- type level effect composition:
    -- the last non-Nothing value wins
    type Unit Update = 'Nothing
    type Plus Update s 'Nothing = s
    type Plus Update s ('Just t) = 'Just t

    pure x = U (x, NoPut)
    (U (a,w)) >>= k = U (update w (runUpdate $ k a))

-- composing two effects in order, passing along whatever value
-- the second has
update :: Eff s -> (b, Eff t) -> (b, Eff (Plus Update s t))
update w (b, NoPut) = (b,w)
update _ (b, Put w') = (b, Put w')

-- since we have defined another "put" in the same file
putUpd :: a -> Update ('Just a) ()
putUpd x = U ((), Put x)

foo :: Update ('Just String) ()
foo = putUpd (42 :: Int) >> putUpd "hello"

data Reader s a = R { runReader :: Set s -> a }

instance Effect Reader where
    -- the following won't work, so there is a subtle different between
    -- the implementation of Writer and that of Reader, see comments below

    -- type Inv Reader s t = (IsSet s, IsSet t, Unionable s t)

    type Inv Reader s t = (IsSet s, IsSet t, Split s t (Union s t))
    type Unit Reader = '[]
    type Plus Reader s t = Union s t

    pure x = R (\_ -> x)
    (R e) >>= k = R (\st ->
        let (s,t) = split st
        in (runReader $ k (e s)) t)

    -- the following won't type check, the problem is that:
    -- - as an input to run the effect, we expect a full list of things
    --   we might read during the execution of a Reader,
    -- - but now we are composing two Readers together and it's totally possible
    --   that two Readers are expecting different sets of values to be read
    -- - so despite that "st" has more than enough thing to feed both readers
    --   we'll have to just take apart "st" and offer two readers exactly what they want.
    -- - comparing this with that of Writer, we can see the difference is in the variance
    --   of info we are carrying along the computation:
    --   - Writer writes, and the info to be carried are some sort of *output* of the effect.
    --   - Reader reads, and the info to be carried are some sort of *input* of the effect.
    -- - also I'll prefer renaming "split" to "dispatch" instead, as "split" reminds me
    --   of spliting a set of things into *disjoint* set, which is not the case for
    --   our implementation of Reader: in our case we look at the "things to be read"
    --   one by one, and distribute then to two Readers as they demand.

    -- (R e) >>= k = R (\st -> (runReader $ k (e st)) st)

ask :: Var v -> Reader '[v :-> t] t
ask Var = R (\ (Ext (Var :-> x) Empty) -> x)

fooR :: Reader '["x" :-> a, "xs" :-> [a]] [a]
fooR = do
    x <- ask (Var :: Var "x")
    xs <- ask (Var :: Var "xs")
    x' <- ask (Var :: Var "x")
    pure (x:x':xs)

-- note that here we don't even need to specify the variable name explictly
-- while we are in this functon, Symbols still have universal quantifiers
init1 = Ext (Var :-> 1) (Ext (Var :-> [2,3]) Empty)

-- but as long as we want to type check the following term, GHC
-- tries to make type of init1 and fooR agree, thus leads to concrete symbols
runFoo = runReader fooR init1

instance Subset s t => Subeffect Reader s t where
    sub (R e) = R $ \st -> let s = subset st in e s

init2 :: Set '["x" :-> Int, "xs" :-> [Int], "z" :-> a]
init2 = Ext (Var :-> 1) (Ext (Var :-> [2,3]) (Ext (Var :-> undefined) Empty))
-- init2 is an "overapproximation" because it has more things than the computation
-- has expected.
