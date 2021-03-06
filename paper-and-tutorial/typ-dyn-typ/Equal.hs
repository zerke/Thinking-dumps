{-# LANGUAGE RankNTypes, PolyKinds, ExistentialQuantification, ScopedTypeVariables #-}
module Equal where

import Data.Functor.Identity
import Data.Maybe

{-# ANN module "HLint: ignore Eta reduce" #-}

{-
   Leibnitz's law, saying if a, b are identical,
   then they should have identical properties as well.
   the original claim should be "forall f. f a <-> f b",
   but it's proven to be equivalent to "forall f. f a -> f b"

   notes:
   * not sure how this works exactly for now, but without bottoms
     id :: forall a. a -> a seems to be the only type that fits
   * the only thing we know is that "f" is a valid type constructor
     and nothing more. without knowing the structure of "f", we cannot
     construct something funny to fit the type
-}
newtype Equal (a :: k) (b :: k) = Equal (forall f. f a -> f b)

-- polymorphic kind allows us to construct proofs of various kinds
eqInt :: Equal Int Int
eqInt = Equal id

eqList :: Equal [] []
eqList = Equal id

eqFunc :: Equal (->) (->)
eqFunc = Equal id

-- "reflex" generalizes everything above.
reflex :: Equal a a
reflex = Equal id

trans :: Equal a b -> Equal b c -> Equal a c
trans ab bc = case (ab,bc) of
  (Equal f, Equal g) -> Equal (g . f)

{-
   motivation: when given "Equal a b", for a type "t" we should be able to substitite
   every occurrence of "a" in it by "b".
   - now let "c a" be the input type "t"
     (here we call it "ta" to distinguish from "tb", the resulting type)
     here we are using some "newtype" definitions to rewrite "t" so that
     it end up being a "function application" on type level.
   - notice that Equal a b provides us with a function: "forall f. f a -> f b",
     so with "c a", we should get "c b" by using this function.
   - for the "c b -> tb" part, we are just unwrapping whatever "newtype" we have
     just defined to end up with the intended resulting type.
-}
subst :: (ta -> c a) -> (c b -> tb) -> Equal a b -> ta -> tb
subst from to (Equal ab) = to . ab . from


{- example about how to convert from (a,a) to (b,b) knowing Equal a b,
   basically we will need a lambda abstraction on type level to make the type
   a "type function application" by type "a", then we'll have the chance to replace it
   by "b"
-}
newtype Pair x = Pair { unPair :: (x,x) }

substPair :: Equal a b -> (a,a) -> (b,b)
substPair = subst Pair unPair

-- "FlipEqual y _" is just "Equal _ y" and the hole is where
-- we are going to play with
newtype FlipEqual y x = Flip { unFlip :: Equal x y }

-- notice that "symm" shows us why passing a function of type "forall f. f a -> f b"
-- is enough for a type equality proof: now we can construct "forall f. f b -> f a"
-- out from it!
symm :: Equal a b -> Equal b a
symm ab = subst Flip unFlip ab reflex

-- "g (f _)" is all what we need,
newtype Comp g f x = Comp { unComp :: g (f x) }

arg :: Equal a b -> Equal (f a) (f b)
arg ab = Equal (subst Comp unComp ab)

-- apply a substitution to the argument of a type constructor
rewrite :: Equal a b -> Equal c (f a) -> Equal c (f b)
rewrite eqAB eqCFa = trans eqCFa eqFaFb
  where
    eqFaFb = arg eqAB

-- we need "h (_ a)" in order to replace the hole with something else
newtype Haf h a f = Haf { unHaf :: h (f a) }

-- like "arg" but acts on the function part
func :: Equal f g -> Equal (f a) (g a)
func eqFG = Equal (subst Haf unHaf eqFG)

rewrite' :: Equal a b -> Equal c (f a d) -> Equal c (f b d)
rewrite' eqAB eqCFad = trans eqCFad (func (arg eqAB))

-- TODO: now that Haskell does has Kind polymorphism, but I'm not sure
-- of this part. skipping it for now.

congruence :: Equal a b -> Equal c d -> Equal (f a c) (f b d)
congruence eqAB eqCD = rewrite eqCD (rewrite' eqAB reflex)

-- now that "~" is taken, so we have to use "~~" instead
class TypeRep tpr where
    -- TODO: for now I'm not sure what this is doing ...
    (~~) :: tpr a -> tpr b -> Maybe (Equal a b)

-- using "Identity" so that we could have "forall f. f a -> f b" become
-- "Identity a -> Identity b", and which is exactly just the "a -> b" function
-- we are looking for, again most stuff about "Equal _ _" are just identity functions
-- on value level.
{-# ANN coerce "HLint: ignore Redundant bracket" #-}
{-# ANN coerce "HLint: ignore Eta reduce" #-}
coerce :: Equal a b -> (a -> b)
coerce eqAB = subst Identity runIdentity eqAB

data Dynamic typeRep = forall a. a ::: typeRep a

fromDyn :: TypeRep tpr => tpr a -> Dynamic tpr -> Maybe a
fromDyn et (x ::: t) = case t ~~ et of
    Just eq -> Just (coerce eq x)
    Nothing -> Nothing

-- this looks a bit confusing, but we are defining "Int" as a value constructor
-- so it does not conflict with the type that we all know as "Int"
-- same can be said to Bool, or you name it.
data TpCon a
  = Int (Equal a Int)
  | Bool (Equal a Bool)

instance TypeRep TpCon where
    (~~) (Int x) (Int y) = Just (trans x (symm y))
    (~~) (Bool x) (Bool y) = Just (trans x (symm y))
    (~~) _ _ = Nothing

inttp :: TpCon Int
inttp = Int reflex

booltp :: TpCon Bool
booltp = Bool reflex

-- note that "true" and "ninetythree" are of the same type
-- and existential type hides the real type inside, with proofs constructed
-- by "TpCon" sitting around.
true, ninetythree :: Dynamic TpCon
true = True ::: booltp
ninetythree = 93 ::: inttp

{-
  Type representation for a Haskell type "a"

  - for "TpCon", I think the purpose is to extend existing type represetations
    so some code might be shared (instance impls for example).
    below we are just having type "TpCon" hard-wired by defining "Type" type synonym.
    I have not yet see any other interesting uses, yet. (TODO)
  - for a list type representation "[] x",
    we need a concrete type representation of "x",
    which is what "List" constructor does
  - similarly, for a function type represetation "x -> y",
    we will have to have type representation for both "x" and "y"
-}
data TpRep tpr a
  = TpCon (tpr a)
  | forall x. List (Equal a [x]) (TpRep tpr x)
  | forall x y. Func (Equal a (x -> y))
                     (TpRep tpr x)
                     (TpRep tpr y)

type Type = TpRep TpCon

inttp' :: Type Int
inttp' = TpCon inttp

booltp' :: Type Bool
booltp' = TpCon booltp

list :: TpRep tpr a -> TpRep tpr [a]
list tprA = List reflex tprA

(.->.) :: TpRep tpr a -> TpRep tpr b -> TpRep tpr (a -> b)
a .->. r = Func reflex a r

deduce :: forall x y a b c d. Equal x (a -> b) -> Equal y (c -> d)
       -> Equal a c -> Equal b d -> Equal x y
deduce x1 x2 x3 x4 = x8
  where
    x5 :: Equal (a -> b) (c -> d)
    x5 = congruence x3 x4
    x6 :: Equal (c -> d) y
    x6 = symm x2
    x7 :: Equal x (c -> d)
    x7 = trans x1 x5
    x8 :: Equal x y
    x8 = trans x7 x6

-- the following instnace impl confirms that one purpose of "TpCon"
-- constructor is for code-reusing.
instance TypeRep tpr => TypeRep (TpRep tpr) where
    -- I feel we have begin to see the boring part of this:
    -- for every single type, one has to encode it in some type representation
    -- and construct proofs that confirms it
    -- also, looking at the cases for List and Func,
    -- I don't know if there is a clever way of proof automation.
    (~~) (TpCon x) (TpCon y) = x ~~ y
    (~~) (List x t1) (List y t2) = case t1 ~~ t2 of
        Just eq -> Just (trans (rewrite eq x) (symm y))
        Nothing -> Nothing
    (~~) (Func x a1 r1) (Func y a2 r2) =
        case (a1 ~~ a2, r1 ~~ r2) of
            (Just aarg, Just res) -> Just (deduce x y aarg res)
            _ -> Nothing
    (~~) _ _ = Nothing

plus, one :: Dynamic Type
-- have to make it explicit so we are not relying on operator's precedence
plus = (+) ::: (inttp' .->. (inttp' .->. inttp'))
one = 1 ::: inttp'

dynApply :: TypeRep tp
         => Dynamic (TpRep tp)
         -> Dynamic (TpRep tp)
         -> Maybe (Dynamic (TpRep tp))
dynApply (f ::: ft) = case ft of
    -- get the first argument and branch
    -- so if "f" is not a function we can fail immediately
    Func eqf tyArg tyRes ->
        let f' = coerce eqf f
        in \ (x ::: xt) -> case xt ~~ tyArg of
            -- make sure "x" is of the intended type that "f'" accepts
            Just eqa -> let x' = coerce eqa x
                        in Just (f' x' ::: tyRes)
            Nothing -> Nothing
    _ -> const Nothing

-- beware that "inc" is really a partial function
inc :: Dynamic Type
inc = fromJust (dynApply plus one)

{-
  and "increment" is also partial, but by casting (plus `dynApply` one)
  to "increment", one no longer needs type checking
  (provided it's been type-checked once).
  or another option is to just live with Maybe monad and there will be no risk
  of so.
-}
increment :: Int -> Int
increment = fromJust (fromDyn (inttp' .->. inttp') inc)

-- safe function in Maybe
incrementM :: Maybe (Int -> Int)
incrementM =
    dynApply plus one >>=
    fromDyn (inttp' .->. inttp')
