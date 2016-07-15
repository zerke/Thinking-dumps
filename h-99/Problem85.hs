{-# LANGUAGE ScopedTypeVariables #-}
module Problem85
  ( Graph
  , mkGraph
  , findIsoMaps
  , iso
  , degreeTable
  ) where

{-
  NOTE:
  - search by purposing partial bijections, reject immediately
    if the iso cannot be established in the given way
  - group nodes by their degrees, by which we can reduce search space.
-}

import qualified Data.Set as S
import qualified Data.Map.Strict as M
import Control.Arrow hiding (loop)
import Control.Monad
import Data.List
import Data.Function
import Data.Maybe
import Control.Monad.State
import qualified DisjointSet as DS
import DisjointSetState

import Graph
import Utils
import Problem80

-- for this problem we keep not just the graph itself but the list of all edges of it.
-- we could have inferred it from the graph itself but having the redundant info around
-- will make things easier.
type Graph a = (AdjForm a (Edge a), [Edge a])

mkGraph :: Ord a => [a] -> [(a,a)] -> Graph a
mkGraph vs es = (graphFormToAdjForm (GraphForm vSet eSet), es')
  where
    convert = map (uncurry Edge)
    es' = convert es
    vSet = S.fromList vs
    eSet = S.fromList es'

degreeTable :: forall a b. Ord a => AdjForm a b -> [(Int,[a])]
degreeTable (AdjForm g) =
        M.toAscList
      . M.map S.toList
      . M.fromListWith mappend
      . map (\(v,d) -> (d,S.singleton v))
      $ degrees
  where
    -- the degree of a vertex is the number of edges connected to it.
    -- (undirected)
    degrees :: [(a, Int)]
    degrees = M.toList $ M.map S.size g

-- for 2 graphs to be isomorphic, the degree table must match
-- returns more properly structured data when succeeded: [(Int, ([a],[b]))]
-- in which first Int is still the degree, and ([a],[b]) are 2 lists of the same size.
-- if 2 graphs are indeed isomorphic, then vertices' mapping must be established inside
-- of every group.
-- note that it's not necessary for vertices of 2 graphs to have the same type
-- as long as the mapping can be established (which means at least "Ord" needs to
-- be supported by the corresponding type), everything should work.
checkDegreeTables :: [(Int,[a])] -> [(Int,[b])] -> Maybe [(Int, ([a],[b]))]
checkDegreeTables dt1 dt2
    | convert dt1 == convert dt2 = Just (zip (map fst dt1)
                                             (zip (map snd dt1)
                                                  (map snd dt2)))
    | otherwise = Nothing
  where
    convert = map (second length)

{-
  we need to keep track of many things
  it's not necessary, but let's organize them in pairs:

  * es1 & es2: edges to be verified
  * grps: remaining groups of same degrees
  * curGp1 & curGp2: current group we are working on

-}
search :: forall a b deg. (Ord a, Eq b) =>
          ([Edge a], [Edge b]) ->
          [(deg, ([a],[b]))] ->
          ([a],[b]) ->
          M.Map a b ->
          [M.Map a b]
search (es1,es2) [] ([],[]) vsMap = do
    -- let's put it in invariant that
    -- at the beginning of every call to search
    -- es1 & es2 should already have all verified edges removed
    -- so at this point we can just test emptiness of them
    -- instead of querying vsMap for (unnecessarily) verification
    guard $ null es1 && null es2
    pure vsMap
search ess ((_,(gp1,gp2)):grps') ([],[]) vsMap =
    -- when current group of vertices are done,
    -- we move our focus to the next group
    search ess grps' (gp1,gp2) vsMap
search (es1,es2) grps (curGp1,curGp2) vsMap = do
    (v2,v2s) <- pick curGp2
    let (v1:v1s) = curGp1
        newVsMap = M.insert v1 v2 vsMap :: M.Map a b
        (es1L, es1R) = partition test (es1 :: [Edge a])
          where
            test (Edge l1 l2)
                  -- when both ends can be found in new vsMap
                | Just _ <- M.lookup l1 newVsMap
                , Just _ <- M.lookup l2 newVsMap = True
                | otherwise = False
    -- now we need to check consistencies for all edges in es1L
    es2R <- fix (\ loop curEs1L curEs2 ->
      case curEs1L of
          [] -> pure curEs2
          (Edge l1 l2:es1L') -> do
              let (Just r1) = M.lookup l1 newVsMap
                  (Just r2) = M.lookup l2 newVsMap
              guard $ Edge r1 r2 `elem` curEs2 || Edge r2 r1 `elem` curEs2
              let newEs2 = delete (Edge r1 r2) $ delete (Edge r2 r1) curEs2
              loop es1L' newEs2
          ) es1L es2
    search (es1R,es2R) grps (v1s,v2s) newVsMap


-- | find mappings between two graphs that can prove they are isomorphic
findIsoMaps :: (Ord a, Ord b) => Graph a -> Graph b -> [M.Map a b]
findIsoMaps (ga,eas) (gb,ebs) = do
    let dta = degreeTable ga
        dtb = degreeTable gb
        dtPair = checkDegreeTables dta dtb
    guard $ isJust dtPair
    let dtp = fromJust dtPair
    search (eas,ebs) dtp ([],[]) M.empty

-- | test whether two graphs are isomorphic
iso :: (Ord a, Ord b) => Graph a -> Graph b -> Bool
iso ga gb = not . null $ findIsoMaps ga gb

{-
  TODO:
  - divide graph into connected components
  - group connected components by number of edges an vertices
  - for each group, try to find a proof of isomorphism within groups

-}
-- | divide an undirected graph into its connected components.
findConnectedComponents :: forall a. Ord a => Graph a -> [Graph a]
findConnectedComponents (AdjForm g,es) = undefined
  where
    vs = M.keys g
    subgraphVS = DS.toGroups (execState findComponents M.empty)
      where
        findComponents = initM vs >> mapM_ (\(Edge a b) -> unionM a b) es
