{-# LANGUAGE
    NoMonomorphismRestriction
  , FlexibleContexts
  , TypeFamilies
#-}
module Main where

-- http://projects.haskell.org/diagrams/doc/vector.html

import Diagrams.Prelude
import Diagrams.Backend.SVG.CmdLine
import Diagrams.TwoD.Vector (e)

ex1 :: Diagram B
ex1 = fromOffsets (concat (replicate 5 [V2 1 1, V2 1 (-1)]))

ex2 :: Diagram B
ex2 = atPoints points (repeat node)
  where
    points :: [Point V2 Double]
    points = [ origin .+^ (5 *^ e (r @@ rad)) | r <- take 7 [tau/4, tau/4-step ..] ]
    step = tau / 2 / 6
    node = circle 1 # fc blue

ex3 :: Diagram B
ex3 = mconcat $ do
    r <- [step, tau/10 + step .. tau]
    x <- [1..3]
    [ fromOffsets [x *^ e (r + step * (x-1) @@ rad)] ]
  where
    step = tau/30

main :: IO ()
main = mainWith ex2
