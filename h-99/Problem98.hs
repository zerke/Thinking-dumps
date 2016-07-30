{-# LANGUAGE FlexibleContexts, TypeFamilies, DataKinds, TupleSections #-}
module Problem98 where

import Control.Monad
import Data.Foldable
import Data.Function
import Data.List
import Data.Maybe
import qualified Data.Array.IArray as Arr
import qualified Data.Map.Strict as M

-- TODO: plan to use some data from https://github.com/mikix/nonogram-db
-- for testing

data Rule = Rule
  { ruleLens :: [Int] -- lengths, all numbers should be greater than 0
    -- calculated from ruleLens, the length of the most compact solution
    -- satisfying this rule.
  , ruleAtLeast :: !Int
  } deriving (Show)

-- "RCRule" (Row/Col Rule) is a rule for a line with index of that line.
-- Left index : Rule for Row "index"
-- Right index: Rule for Col "index"
type RCRule = (Either Int Int, Rule)
-- cell content for an unsolved puzzle.
-- Nothing: not yet filled of anything
-- Just True: this cell is painted black.
-- Just False: this cell is painted white.
type CellContent = Maybe Bool
-- the description of a nonogram, including # of cols and # of rows.
-- and a complete list of rules (paired with line index)
data Nonogram = NG !Int !Int [RCRule]

data RectElemState = Solved | Unsolved

-- just a fancy way of saying "Bool" and "Maybe Bool",
-- depending on whether we are representing a solved or unsolved puzzle
type family RectElem (a :: RectElemState)

type instance RectElem 'Solved = Bool
type instance RectElem 'Unsolved = Maybe Bool

-- the "Rect a" represent a partial or complete solution of puzzle
type Rect a = Arr.Array (Int,Int) (RectElem a)

-- traverse the list, separate the minimum element with rest of the list,
-- it's guaranteed that the ordering is preserved.
minViewBy :: (a -> a -> Ordering) -> [a] -> Maybe (a,[a])
minViewBy _ [] = Nothing
minViewBy f xs = Just . minimumBy (f `on` fst) $ xsWithContext
  where
    xsWithContext = zip xs (zipWith (++)
                              (init $ inits xs)
                              (tail $ tails xs))

mkRule :: [Int] -> Rule
mkRule [] = Rule [] 0
mkRule xs = Rule xs $ sum xs + length xs - 1

mkRowRule, mkColRule :: Int -> [Int] -> RCRule

mkRowRule i xs = (Left i, mkRule xs)
mkColRule i xs = (Right i, mkRule xs)

-- a rule consists of a list of numbers, "ruleView r" destructs a rule like how
-- "minView" destructs an (usually ordered) data structure to separate one element
-- from rest of it.
ruleView :: Rule -> Maybe ((Int, Int), Rule)
ruleView (Rule [] _) = Nothing
ruleView (Rule [x] l) = Just ((x,l), Rule [] 0)
ruleView (Rule (x:xs) l) = Just ((x,l), Rule xs (l-x-1))

solveRule :: Rule -> [CellContent] -> [ [Bool] ]
solveRule r1 xs1 = map tail (($ []) <$> solveRule' r1 (Nothing:xs1) ([] ++))
  where
    -- TODO: let's say to satisfy the next new rule
    -- we always fill in a "False" as the separator
    -- and caller of this function should be responsible
    -- for prepending a Nothing in front of the [CellContent]
    -- TODO: seems this function is producing some space leak,
    -- we might need to investigate further.
    solveRule' :: Rule -> [CellContent] -> ([Bool] -> [Bool]) -> [ [Bool] -> [Bool] ]
    solveRule' r xs acc = case ruleView r of
        -- all rules have been satisfied, we fill rest of the cells with False
        Nothing -> ((\zs -> acc . (zs ++)) . fst) <$>
                     maybeToList (checkedFill False (length xs) xs 0)
        -- now we are trying to have one or more "False" and "curLen" consecutive "True"s
        Just ((curLen,leastL), r') -> do
            -- we can fail immediately here if we have insufficient number of cells.
            guard $ length xs >= leastL + 1
            -- always begin with one "False"
            (filled1,remained1) <- maybeToList $ checkedFill False 1 xs 0
            -- now we have 2 options, either start filling in these cells, or
            let acc' = acc . (filled1 ++)
                fillNow = do
                   (filled2, remained2) <- maybeToList $ checkedFill True curLen remained1 0
                   solveRule' r' remained2 $ acc' . (filled2 ++)
                fillLater = solveRule' r remained1 acc'
            fillNow ++ fillLater
    -- "checkedFill b count ys" tries to fill "count" number of Bool value "b"
    -- into cells, results in failure if cell content cannot match with the indended value.
    checkedFill :: Bool -> Int -> [CellContent] -> Int -> Maybe ([Bool], [CellContent])
    checkedFill b count ys countFilled
        | count == 0 =
            -- no need to fill in anything, done.
            -- there's no need reversing the list, as all values filled in
            -- are the same.
            pure (take countFilled bs, ys)
        | otherwise = case ys of
            [] ->
                -- there's no room for filling anything, results in failure
                mzero
            (m:ys') -> do
                -- if the cell has not yet been filled, there's no problem.
                -- otherwise the already-existing value should match what
                -- we are filling in.
                guard (maybe True (\b2 -> b == b2) m)
                checkedFill b (count-1) ys' $! countFilled+1
      where
        bs = repeat b

mkRect :: Int -> Int -> Rect 'Unsolved
mkRect nRow nCol = Arr.array ((1,1), (nRow,nCol)) vals
  where
    vals = zip
             [(r,c) | r <- [1..nRow], c <- [1..nCol]]
             (repeat Nothing)

{-
  TODO: for now the "flexibility" does not change throughout
  our search, which I believe can be optimized:

  - for each rule, we grab the corresponding cells, and use "solveRule" to
    get a list of all possible solutions, more solutions mean more flexible.
  - to prevent "solveRule" from giving too many alternatives, we can use "take"
    to give an upper bound about this "flexibility": say the upper bound
    is 100, then "flexibility" of a rule (row / col) cannot exceed 100.
  - when the definition of "flexibility" results in a tie,
    the original one (total length - min required number of cells) is compared.
-}
solveRect :: Nonogram -> Maybe (Rect 'Solved)
solveRect (NG nRow nCol rs) = solveRect' (mkRect nRow nCol) rs
  where
    -- measure "flexibility" of a rule, the less flexible a rule is,
    -- the less solutions it can have for one certain row / col
    flex :: RCRule -> Int
    flex (lr, Rule _ atLeast) = case lr of
        Left _ -> nRow - atLeast
        Right _ -> nCol - atLeast

    solveRect' :: Rect 'Unsolved -> [RCRule] -> Maybe (Rect 'Solved)
    solveRect' curRect rules = case minViewBy (compare `on` snd . snd) processedRules of
        Nothing -> checkRect curRect
        Just (((lr,_),(solutions, _)),rules') -> listToMaybe $ do
            let indices = getIndices lr
            solution <- solutions
            let newAssocs = zip indices (map Just solution)
                newRect = Arr.accum (\_old new -> new) curRect newAssocs
            maybeToList $ solveRect' newRect (map fst rules')
      where
        getIndices lr = case lr of
            Left  rowInd -> map (rowInd,) [1..nCol]
            Right colInd -> map (,colInd) [1..nRow]
        -- return type: (row/col index, (all solutions, (bounded length of solutions, flex)))
        processRule :: RCRule -> (RCRule, ([[Bool]], (Int, Int)))
        processRule r@(lr,rule) = (r, (solutions,(estSearchSpace, flex r)))
          where
            searchCap = 10 :: Int
            indices = getIndices lr
            extracted = map (curRect Arr.!) indices
            solutions = solveRule rule extracted
            estSearchSpace = length (take searchCap solutions)
        processedRules = map processRule rules

    checkRect :: Rect 'Unsolved -> Maybe (Rect 'Solved)
    checkRect ar = do
        guard $ all isJust (Arr.elems ar)
        pure $ Arr.amap fromJust ar

fromRawNonogram :: [[Int]] -> [[Int]] -> Nonogram
fromRawNonogram rowRules colRules = NG (length rowRules) (length colRules) rules
  where
    rowRules' = zipWith (\rInd raw -> (Left rInd, mkRule raw)) [1..] rowRules
    colRules' = zipWith (\rInd raw -> (Right rInd, mkRule raw)) [1..] colRules
    rules = rowRules' ++ colRules'

pprSolvedNonogram :: Nonogram -> Rect 'Solved -> String
pprSolvedNonogram (NG nRow nCol rules') rect = unlines (map pprRow [1..nRow] ++ pprdColRules)
  where
    lookupRule k = M.lookup k rules
    rules = M.fromList rules'

    getRawRule (Rule rs _) = rs

    pprdColRules :: [String]
    pprdColRules = map ((' ':) . unwords . map toStr) tr
      where
        colRules = map (maybe [] getRawRule . lookupRule . Right) [1..nCol]
        longest = maximum (map length colRules)
        paddedRules = map (take longest . (++ repeat 0)) colRules
        tr = transpose paddedRules

        toStr 0 = " "
        toStr n = show n

    pprRow :: Int -> String
    pprRow rInd = '|' : intercalate "|" cells ++ "| " ++ unwords (map show rowRule)
      where
        rowRule = maybe [] getRawRule $ lookupRule (Left rInd)
        cells = map (toStr . (rect Arr.!) . (rInd,)) [1..nCol]
        toStr False = "_"
        toStr True = "X"

nonogram :: [[Int]] -> [[Int]] -> String
nonogram rowRules colRules =
    maybe "No solution.\n" (pprSolvedNonogram ng) (solveRect ng)
  where
    ng = fromRawNonogram rowRules colRules
