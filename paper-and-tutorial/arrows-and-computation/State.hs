module State where

import qualified Control.Category as Cat
import Control.Arrow

newtype State s i o = ST { runST :: (s,i) -> (s,o) }

{-# ANN arrS "HLint: ignore Use second" #-}
arrS :: (i -> o) -> State s i o
arrS f = ST $ \(s,i) -> (s,f i)

compS :: State s a b -> State s b c -> State s a c
compS (ST f) (ST g) = ST (g . f)

firstS :: State s a b -> State s (a,d) (b,d)
firstS (ST f) = ST $ \(s,(a,d)) -> let (s',b) = f (s,a) in (s',(b,d))

instance Cat.Category (State s) where
    id = arrS id
    g . f = compS f g

instance Arrow (State s) where
    arr = arrS
    first = firstS