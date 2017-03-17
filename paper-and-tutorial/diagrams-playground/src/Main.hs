{-# LANGUAGE
    NoMonomorphismRestriction
  , FlexibleContexts
  , FlexibleInstances
  , TypeFamilies
  , TupleSections
#-}
module Main where

-- http://projects.haskell.org/diagrams/doc/vector.html

import Diagrams.Prelude
import Diagrams.Backend.SVG.CmdLine
import Diagrams.Backend.SVG
import Diagrams.Backend.CmdLine
import Diagrams.TwoD.Vector (e)
import Data.Foldable
import Control.Monad.Random
-- import Data.List
import Data.Ord
import qualified Data.Set as S
import System.IO.Unsafe

import qualified Data.Vector as V
import qualified Data.Vector.Algorithms.Merge as V

-- has to be stable
sortViaVector :: Ord a => [a] -> [a]
sortViaVector xs = unsafePerformIO $ do
    vec <- V.unsafeThaw (V.fromList xs)
    V.sort vec
    V.toList <$> V.unsafeFreeze vec

sortByViaVector :: (a -> a -> Ordering) -> [a] -> [a]
sortByViaVector f xs = unsafePerformIO $ do
    vec <- V.unsafeThaw (V.fromList xs)
    V.sortBy f vec
    V.toList <$> V.unsafeFreeze vec

ex1 :: Diagram B
ex1 = fromOffsets (concat (replicate 5 [V2 1 1, V2 1 (-1)]))

ex2 :: Diagram B
ex2 = foldMap (\vec -> node # translate vec) vecs
  where
    vecs = [ 5 *^ e (r @@ rad) | r <- take 7 [tau/4, tau/4-step ..] ]
    step = tau / 2 / 6
    node = circle 1 # fc blue

ex3 :: Diagram B
ex3 = mconcat $ do
    r <- [step, tau/10 + step .. tau]
    x <- [1..3]
    [ fromOffsets [x *^ e (r + step * (x-1) @@ rad)] ]
  where
    step = tau/30

vTriangle :: V2 Double -> V2 Double -> Diagram B
vTriangle va vb = fromOffsets [va, negated va ^+^ vb , negated vb]

parallelogram :: V2 Double -> V2 Double -> Diagram B
parallelogram v1 v2 = mconcat
    [ drawV v1 # lc blue
    , drawV v1 # lc blue # translate v2 # dashing'
    , drawV v2 # lc red
    , drawV v2 # lc red # translate v1 # dashing'
    , drawV (v1 ^+^ v2) # lc purple
    ]
  where
    drawV v = fromOffsets [v]
    dashing' = dashingG [0.1,0.1] 0

circleGrid :: Diagram B
circleGrid = mconcat $ do
    x <- [-15 .. 15 :: Int]
    y <- [-15 .. 15]
    let p = p2 (x,y)
        (xD,yD) = (fromIntegral x, fromIntegral y)
        pCenter = origin
        qDist = qd p pCenter
        cir = circle 1 # fc (if qDist <= 15*15 then yellow else purple)
    pure (cir # translate (r2 (xD+xD,yD+yD)))

main :: IO ()
main = do
    pts <- replicateM 400 ((,) <$> getRandomR (-20,20) <*> getRandomR (-20,20))
    let pts' = S.fromList . map p2 $ pts
    mainWith
        [ ("ex1", ex1)
        , ("ex2", ex2)
        , ("ex3", ex3)
        , ("vTriangle", vTriangle unitX (unitX # rotateBy (1/8)))
        , ("parallelogram", parallelogram (unitX # rotateBy (1/120)) (unitX # rotateBy (1/8)))
        , ("circlegrid", circleGrid)
        , ("grahamscan", renderedGrahamScan pts')
        ]

{-

- impl Graham scan
- generate random points for testing
- render diagram

TODO:

- extend to record steps
- render diagram (with steps)

-}

grahamScan :: S.Set (P2 Int) -> [P2 Int]
grahamScan pSet
    | S.size pSet < 3 = error "insufficient points"
    | otherwise = reverse $ go [startPoint2,startPoint] visitList
  where
    startPoint = minimumBy cmp' pSet
    toDbl p = let (x,y) = unp2 p in p2 (fromIntegral x, fromIntegral y :: Double)
    cmp' pa pb =
        let ((xa,ya),(xb,yb)) = (unp2 pa, unp2 pb)
        in (ya `compare` yb) <> (xa `compare` xb)
    visitList :: [P2 Int]
    (startPoint2 : visitList) =
          sortByViaVector (comparing (\p -> signedAngleBetween (toDbl p .-. toDbl startPoint) unitX))
        . S.toList
        $ S.delete startPoint pSet
    go :: [P2 Int] {- current set of convex points -}
       -> [P2 Int] {- a list to be visited -}
       -> [P2 Int]
    go vs [] = vs
    go vs@(pt2:pt1:vs') vList@(ptCur:vList') =
        let va = pt2 .-. pt1
            vb = ptCur .-. pt2
        in -- we are not testing just left turn, but non-right turns, straight line counts.
           if leftTurn va vb || not (leftTurn vb va)
             then go (ptCur:vs) vList'
             else go (pt1:vs') vList
    {-
      the following two cases are unreachable:
      - the guard at the beginning (i.e. "S.size pSet < 3") should have ensured that we
        have sufficient number of points
      - we have gave two initial points in "vs", so the only way that the size of "vs"
        ever goes down is through failing the "non-right turn" test, but since the list
        is sorted by ascending angles, this could never happen.
     -}
    go [] _ = error "unreachable (empty)"
    go [_] _ = error "unreachable (singleton)"

renderedGrahamScan :: S.Set (P2 Int) -> Diagram B
renderedGrahamScan pSet = allVertices <> allEdges
  where
    toDbl p = let (x,y) = unp2 p in p2 (fromIntegral x, fromIntegral y :: Double)
    vertexDg = circle 0.1
    allVertices = foldMap (\pt -> vertexDg # translate (pt .-. origin)) (S.map toDbl pSet)
    allEdges = foldMap (\(pt1,pt2) ->
                        let pt1' = toDbl pt1
                            pt2' = toDbl pt2
                        in fromOffsets [pt2' .-. pt1'] # translate (pt1' .-. origin)) edges
    convexPts = grahamScan pSet
    edges =
        (last convexPts, head convexPts)
        : zip convexPts (tail convexPts)
