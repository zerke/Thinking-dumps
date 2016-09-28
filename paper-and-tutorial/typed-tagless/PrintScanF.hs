module PrintScanF where

import Prelude hiding ((^))
import Data.List
import Data.Char

{-# ANN module "HLint: ignore Use const" #-}
{-# ANN module "HLint: ignore Use fst" #-}
{-# ANN module "HLint: ignore Collapse lambdas" #-}
{-# ANN module "HLint: ignore Redundant bracket" #-}
{-# ANN module "HLint: ignore Avoid lambda" #-}

class FormattingSpec repr where
    lit :: String -> repr a a
    int :: repr a (Int -> a)
    char :: repr a (Char -> a)
    (^) :: repr b c -> repr a b -> repr a c

infixl 5 ^

-- "Pr" for printing
newtype FPr a b = FPr ((String -> a) -> b)

instance FormattingSpec FPr where
    lit str = FPr $ \k -> k str
    int = FPr $ \k -> \x -> k (show x)
    char = FPr $ \k -> \x -> k [x]
    (FPr a) ^ (FPr b) = FPr $ \k -> a (\sa -> b (\sb -> k (sa ++ sb)))

sprintf :: FPr String b -> b
sprintf (FPr fmt) = fmt id

-- "Sc" for scanning
newtype FSc a b = FSc (String -> b -> Maybe (a,String))

instance FormattingSpec FSc where
    lit str = FSc $ \inp f ->
        if str `isPrefixOf` inp
           then Just (f, drop (length str) inp)
           else Nothing
    int = FSc $ \inp f -> case span isDigit inp of
        ([],_) -> Nothing
        (raw,inp') -> Just (f (read raw), inp')
    char = FSc $ \inp f -> case inp of
        (c:inp') -> Just (f c, inp')
        "" -> Nothing
    (FSc a) ^ (FSc b) = FSc $ \inp f ->
        a inp f >>= \(vb,inp') -> b inp' vb

