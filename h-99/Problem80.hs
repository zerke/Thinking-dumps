{-# LANGUAGE MultiParamTypeClasses, TupleSections, FlexibleInstances, ConstraintKinds #-}
module Problem80 where

import Data.List hiding (concatMap, concat)
import Data.Either
import Data.Foldable
import qualified Data.Map.Strict as M
import qualified Data.Set as S
import Data.Monoid
import Data.Function

import Prelude hiding
    ( concat
    , concatMap
    )

-- assume that edges are unique in a graph
-- and this is true if edges are represented by two vertices
-- together with some more information
data GraphForm v e = GraphForm
    { gfVertices :: S.Set v
    , gfEdges    :: S.Set e
    } deriving Show

-- instead of storing vertices for each nodes, we simply store
-- the edge itself, as it might contain more information
data AdjForm v e = AdjForm (M.Map v (S.Set e)) deriving Show

data FndForm v e = FndForm [Either v e] deriving Show

type OrdVE v e = (Ord v, Ord e, VertexEdge v e)

-- "Edge" does not allow more than one edge between any pair of vertices
-- also it's undirected
data Edge v = Edge v v deriving Show

instance Eq v => Eq (Edge v) where
    (Edge a b) == (Edge c d) = (a,b) == (c,d) || (a,b) == (d,c)

instance Ord v => Ord (Edge v) where
    compare = compare `on` normalize
        where
          normalize (Edge a b)
              | a <= b = (a,b)
              | otherwise = (b,a)

-- the relation between vertex and edge
-- minimal implementation: terminals
class Eq v => VertexEdge v e where
    -- edges have two terminals
    terminals :: e -> (v,v)
    -- can test if a vertex is one of its terminal
    terminalOf :: v -> e -> Bool

    v `terminalOf` e = let (a,b) = terminals e
                       in v == a || v == b

instance Eq v => VertexEdge v (Edge v) where
    terminals (Edge a b) = (a,b)

pairToList :: (a,a) -> [a]
pairToList ~(x,y) = [x,y]

graphFormToAdjForm :: OrdVE v e => GraphForm v e -> AdjForm v e
graphFormToAdjForm (GraphForm vs es) = AdjForm (M.fromListWith S.union allPairs)
  where
    allPairs = emptyPairs ++ vertEdgePairs
    -- used to ensure that isolated vertices are included
    emptyPairs = map (,S.empty) . S.toList $ vs
    vertEdgePairs = concatMap edgeToPair . S.toList $ es
    edgeToPair e
        | (a,b) <- terminals e = [(a, S.singleton e),(b, S.singleton e)]

adjFormToGraphForm :: (Ord v, Ord e, VertexEdge v e) => AdjForm v e -> GraphForm v e
adjFormToGraphForm (AdjForm as) = GraphForm vs es
  where
    vs = M.keysSet as
    es = mconcat . M.elems $ as


fndFormToGraphForm :: (Ord v, Ord e, VertexEdge v e) => FndForm v e -> GraphForm v e
fndFormToGraphForm (FndForm fs) = GraphForm vs (S.fromList es)
  where
    es = rights fs
    vs1 = lefts fs
    vs2 = concatMap (pairToList . terminals ) es
    vs = S.fromList $ vs1 ++ vs2

graphFormToFndForm :: (Ord v, VertexEdge v e) => GraphForm v e -> FndForm v e
graphFormToFndForm (GraphForm vs es) = FndForm (map Left vs' ++ map Right es')
  where
    -- vertices that appear at least once in the list of edges
    evs = S.fromList . concatMap (pairToList . terminals) $ es
    vs' = S.toList $ evs `S.difference` vs
    es' = S.toList es

example :: GraphForm Char (Edge Char)
example = GraphForm vs es
  where
    vs = S.fromList "ghbcfkd"
    es = S.fromList (map (uncurry Edge) [ ('g','h')
                            , ('b','c')
                            , ('b','f')
                            , ('f','c')
                            , ('f','k')
                            ])

main :: IO ()
main = do
    -- TODO: use quickcheck for some simple property-checking?
    print example
    -- TODO: missing some vertices
    print (graphFormToAdjForm example)
    print (adjFormToGraphForm . graphFormToAdjForm $ example)
