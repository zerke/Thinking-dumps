module POV
  ( Graph(..)
  , fromPOV
  , tracePathBetween
  ) where

import Data.List

data Graph a
  = Graph a [Graph a]
  deriving (Eq, Show)

{-
  plan: we need a zipper, as we walk through
  the tree, we will try to find the tag, at that time
  some context will be accumulated, which includes enough
  information for us to construct the new tree..
-}
data GraphContext a = GContext
  { parentTag :: a
    -- (<visited>, <rest of the elements>)
  , bothers :: ([Graph a], [Graph a])
  }

getChildZippers :: Graph a -> [(Graph a, GraphContext a)]
getChildZippers (Graph t xs) = undefined

-- create list zippers: [1,2,3] -> [([],[1,2,3]), ([1],[2,3]), ([2,1],[3]), ([3,2,1],[])]
listZippers :: [a] -> [([a],[a])]
listZippers xs = unfoldr f ([],xs)
  where
    f (st,xs) = case xs of
        [] -> Nothing
        (x:xs) -> let v = (x:st,xs) in Just (v,v)

fromPOV :: Eq a => a -> Graph a -> Maybe (Graph a)
fromPOV = undefined

tracePathBetween :: Eq a => a -> a -> Graph a -> Maybe [a]
tracePathBetween = undefined
