module Ch03RedBlackTest where

import Test.Hspec
import Test.QuickCheck
import qualified Data.IntSet as IS
import Data.Foldable

import Ch03RedBlack

{-# ANN module "HLint: ignore Redundant do" #-}

fromList :: Ord a => [a] -> Tree a
fromList = foldl' (flip insert) empty

sortByTree :: Ord a => [a] -> [a]
sortByTree = toAscList . fromList

main :: IO ()
main = hspec $ do
    describe "RedBlack" $ do
      it "can sort elements (no duplicate elements)" $ do
        property $ \xs -> sortByTree (xs :: [Int]) ==
                          (IS.toAscList . IS.fromList $ xs)
