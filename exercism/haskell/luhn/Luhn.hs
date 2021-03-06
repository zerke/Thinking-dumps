module Luhn
  ( checkDigit
  , addends
  , checksum
  , isValid
  , create)
  where

checkDigit :: Integer -> Integer
checkDigit = (`rem` 10)

toDigits :: Integer -> [Integer]
toDigits 0 = [0]
toDigits v =
      map snd
    . reverse
    . takeWhile (\(x,y) -> x > 0 || y > 0)
    . tail
    -- [(123,0),(12,3),(1,2),(0,1),(0,0]
    $ iterate (\(x,_) -> x `quotRem` 10) (v,0)
    -- e.g. v=123

addends :: Integer -> [Integer]
addends xs = zipWith ($) fs digits
  where
    digits = toDigits xs
    l = length digits
    onEverySecond x =
        let y = x+x
        in if y >= 10
             then y - 9
             else y
    fs = reverse (take l (cycle [id,onEverySecond]))

checksum :: Integer -> Integer
checksum = (`rem` 10) . sum . addends

isValid :: Integer -> Bool
isValid = (== 0) . checksum

create :: Integer -> Integer
create v = padV + if curChecksum == 0
                    then 0
                    else 10-curChecksum
  where
    -- add "0" as last digit and see if it's valid already
    -- if not, we can change this value to a valid one by subtract it
    -- from 10
    padV = v*10
    curChecksum = checksum padV
