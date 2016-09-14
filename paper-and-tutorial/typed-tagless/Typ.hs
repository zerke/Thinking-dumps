{-# LANGUAGE RankNTypes, ExistentialQuantification #-}
module Typ where

-- trying to replicate http://okmij.org/ftp/tagless-final/course/Typ.hs

{-
  the language of type representation.
  supporting just integers and functions.
  concrete instances are needed to give semantics
-}
class TSYM trepr where
    tint :: trepr Int
    tarr :: trepr a -> trepr b -> trepr (a -> b)

-- "ShowT a" is for printing types out
newtype ShowT a = ShowT String

instance TSYM ShowT where
    tint = ShowT "Int"
    tarr (ShowT a) (ShowT b) = ShowT $ "(" ++ a ++ "->" ++ b ++ ")"

viewTy :: ShowT a -> String
viewTy (ShowT s) = s

-- TODO: I'm not sure what this is for, seems trivial.
newtype TQ t = TQ { unTQ :: forall trepr. TSYM trepr => trepr t }

-- TODO: seems the actual instance are hid inside TQ?
instance TSYM TQ where
    tint = TQ tint
    tarr (TQ a) (TQ b) = TQ (tarr a b)

data Typ = forall t. Typ (TQ t)

newtype EQU a b = EQU { equCast :: forall c. c a -> c b }

refl :: EQU a a
refl = EQU id

trans :: EQU a u -> EQU u b -> EQU a b
trans au ub = equCast ub au
-- consider turning (EQU a) u into (EQU a) b

-- "EQU _ b"
newtype FS b a = FS { unFS :: EQU a b }

-- "EQU a a" with first "a" changed to "b" by using "equ" to cast
symm :: forall a b. EQU a b -> EQU b a
symm equ = unFS . equCast equ . FS $ (refl :: EQU a a)

-- "EQU t (_ -> b)"
newtype F1 t b a = F1 { unF1 :: EQU t (a -> b) }

-- "EQU t (a -> _)"
newtype F2 t a b = F2 { unF2 :: EQU t (a -> b) }

eqArr :: EQU a1 a2 -> EQU b1 b2 -> EQU (a1 -> b1) (a2 -> b2)
eqArr a1a2 b1b2 = cast refl
  where
    cast = cast2 . cast1
    cast1 = unF1 . equCast a1a2 . F1
    cast2 = unF2 . equCast b1b2 . F2
