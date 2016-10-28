module Raz where

import Control.Monad.Random
import Data.Bits

type Level = Int
data Dir = L | R

data Tree a
  = Nil
  | Leaf a
  | Bin Level Int (Tree a) (Tree a)

data List a
  = LNil
  | LCons a (List a)
  | LLvl Level (List a)
  | LTr (Tree a) (List a)

data Zip a = Zip (List a) a (List a)

singleton :: a -> Zip a
singleton e = Zip LNil e LNil

trim :: Dir -> List a -> List a
trim d tl = case tl of
    LNil -> tl
    LCons {} -> tl
    LLvl {} -> tl
    LTr t rest ->
        let trim' h1 t1 = case h1 of
                Nil -> error "poorly formed tree"
                Leaf elm -> LCons elm t1
                Bin lv _ l r -> case d of
                    L -> trim' r (LLvl lv (LTr l t1))
                    R -> trim' l (LLvl lv (LTr r t1))
        in trim' t rest

rndLevel :: MonadRandom m => m Int
rndLevel = do
    -- provide 30 bits
    x <- getRandomR (0 :: Int, (1 `shiftL` 30)-1)
    if x == 0
       then pure 0
       else
         let loop t r =
                 {- analysis:
                    - INVARIANT: t == 2^r
                    - t is 1, 2, 4, 8, ...
                    - x consists of 30 random bits
                    - for the worse case, every bit of x is "1"
                      (so there's no way of escaping the recursive call early)
                      - x .&. t == 0 will be the case where t = 2^31 => r = 31
                      - so rndLevel outputs a number in between 0 and 31
                  -}
                 if x .&. t == 0
                   then r
                   else loop (t `shiftL` 1) (r+1)
         in pure (loop 1 0)
