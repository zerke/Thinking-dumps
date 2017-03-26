{-# LANGUAGE
    NoMonomorphismRestriction
  , FlexibleContexts
  , FlexibleInstances
  , TypeFamilies
  , TupleSections
#-}
module TrailsAndPaths where

-- http://projects.haskell.org/diagrams/doc/paths.html

import Diagrams.Prelude
import Diagrams.Direction
import Control.Arrow
import Types

tapBundle :: Actioned Double
tapBundle = nest "tap" $ Actioned
    [ ("ex1_1", pure ex1_1)
    , ("ex1_2", pure ex1_2)
    , ("ex1_3", pure ex1_3)
    , ("ex1_4", pure ex1_4)
      -- alternative ex4 using "pentagon" function
    , ("ex1_4alt", pure ex1_4Alt)
    , ("ex1_5", pure ex1_5)
    , ("ex2_1", pure ex2_1)
    , ("ex2_2", pure (strokeLine ex2_2))
    , ("ex2_3", pure ex2_3)
    , ("ex2_3alt", pure ex2_3Alt)
    , ("ex3_1", pure ex3_1)
    , ("ex3_2", pure ex3_2)
    , ("ex4_1", pure ex4_1)
    , ("ex4_2", pure ex4_2)
    , ("ex4_3", pure ex4_3)
    , ("ex5_1", pure ex5_1)
    , ("ex5_2", pure ex5_2)
    , ("ex6_1", pure ex6_1)
    ]

-- this can actually work without "strokeLine"
ex1_1 :: Diagram B
ex1_1 = strokeLine (fromOffsets [unitX, scale 2 unitY, scale 2 unitX])

ex1_2 :: Diagram B
ex1_2 = ex1_1 # rotate (negated ang)
  where
    -- not sure why, but I have to put type annotations for this to work..
    ang = angleBetweenDirs dir dirX
    trail :: Trail' Line V2 Double
    trail = fromOffsets [unitX, scale 2 unitY, scale 2 unitX]
    dir :: Direction V2 Double
    dir = direction (lineOffset trail)
    dirX :: Direction V2 Double
    dirX = direction unitX

ex1_3 :: Diagram B
ex1_3 = fromVertices (origin : take 9 (map p2 coords'))
  where
    coords' = (0,1) : (1,0) : (map . first) succ coords'

ex1_4 :: Diagram B
ex1_4 = fromOffsets (take 5 xs)
  where
    xs = unitX : map (rotateBy (1/5)) xs

ex1_4Alt :: Diagram B
ex1_4Alt = pentagon 1

{-

"pentagon" does not specify how segments are arranged,
we know with "onLineSegments" it's just a matter of locate the segment in
question and remove it, but it still takes some trial and error to figure this out.

-}
ex1_5 :: Diagram B
ex1_5 = strokeLine $ onLineSegments tail (pentagon 1)

ex2_1 :: Diagram B
ex2_1 = strokeLine $ dg `mappend` dg
  where
    dg = onLineSegments init (pentagon 1)

-- ex2_2 :: Diagram B
ex2_2 = mconcat $ iterateN 5 (rotateBy (1/5)) dg
  where
    dg = onLineSegments init (pentagon 1)

ex2_3 :: Diagram B
ex2_3 = strokeLine $ dg3 <> reverseLine (reflectX dg3)
  where
    dg1 = fromOffsets [unitX, unitY # rotateBy (1/12), unitX # rotateBy (1/6) ^* 2]
    dg2 = dg1 <> reverseLine (reflectX dg1)
    dg3 = dg2
          <> fromOffsets [unitX]
          <> rotateBy (-1/3) (reverseLine dg2)
          <> fromOffsets [rotateBy (1/12) unitY]
          <> rotateBy (1/3) dg2
          <> fromOffsets [unitX # rotateBy (1/6)]
          <> rotateBy (-1/3) (reverseLine dg2)
          <> fromOffsets [unitX # rotateBy (1/6)]
          <> dg1

-- TODO: this is not quite working...
ex2_3Alt :: Diagram B
ex2_3Alt = strokeLine (mkLines (fromOffsets [unitX]))
  where
    dg1 = fromOffsets [unitX, unitY # rotateBy (1/12), unitX # rotateBy (1/6) ^* 2] # rotateBy (-1/6) # reflectY
    mkLines basicDg = f $ basicDg <> reverseLine dg1' <> rotateBy (1/6) dg'
      where
        dg' = reflectY basicDg
        dg1' = rotateBy (-1/6) dg'
        f x = x <> reverseLine (reflectX x)

ex3_1 :: Diagram B
ex3_1 = strokeLoop (pentagon 1) # fc blue

-- should be just lines with no color filled
ex3_2 :: Diagram B
ex3_2 = strokeLine (pentagon 1) # fc blue

ex4_1 :: Diagram B
ex4_1 = strokeLoop (glueLine ex2_2) # fc green

ex4_2 :: Diagram B
ex4_2 = strokeLoop (glueLine l) # fc red
  where
    l = fromOffsets (concat (replicate 5 [unitY,unitX]) ++ [unit_Y ^* 5, unit_X ^* 5])

ex4_3 :: Diagram B
ex4_3 = strokeLoop (glueLine (mconcat (take 5 (iterate (rotateBy (-1/5)) dg)))) # fc blue
  where
    -- some work on paper can mathematically show that it's 0.3 (turn)
    dg = fromOffsets [unitY]
        <> arc (dir unit_X) ((-1/2) @@ turn)
        <> fromOffsets [unit_Y]
        <> arc (dir unit_X) (0.3 @@ turn)

ex5_1 :: Diagram B
ex5_1 = strokeLoop (closeLine (fromOffsets [r2 (1,3),unitX ^* 3, r2(1,-3)]))

ex5_2 :: Diagram B
ex5_2 = strokeLoop (closeLine $ l1 <> stimes (10 :: Int) (l1 <> l2) <> l2) # fc yellow
  where
    l1 = fromOffsets [r2 (1,5)]
    l2 = fromOffsets [r2 (1,-5)]

-- TODO: not working yet
ex6_1 :: Diagram B
ex6_1 = mconcat (map (rotateBy (1/24) . strokeLine) $ explodeTrail c)
  where
    c = heptagon 1 `at` origin
