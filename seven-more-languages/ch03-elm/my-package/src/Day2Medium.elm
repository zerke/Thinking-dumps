module Day2Medium where

import Tools exposing (..)
import Time
import Signal
import Mouse exposing (..)
import Window exposing (..)
import List
import Array
import Maybe
import Graphics.Element

import Graphics.Collage exposing (..)
import Color exposing (..)

-- seems collage is using a different coord system
-- so we abstract out coordinate translation as a separated function
toCollageCoord : (Int, Int) -> (Int,Int) -> (Float,Float)
toCollageCoord (w,h) (x,y) = ( toFloat x - toFloat w / 2
                             , toFloat h / 2 - toFloat y )

drawShape : (Int,Int) -> (Int,Int) -> Int -> Graphics.Element.Element
drawShape (w,h) (x,y) ind =
  let sInd = ind % Array.length allForms
      shape = Array.get sInd allForms
            |> Maybe.withDefault (filled black (square 40))
    in collage w h 
         [ shape
           |> move (toCollageCoord (w,h) (x,y))
         ]

-- some "pictures" to use
allForms : Array.Array Form
allForms = 
  [ red, green, blue ]
  |> List.concatMap 
     (\color ->
        [ square 40
        , circle 40
        , ngon 5 40
        , ngon 3 40
        ] |> List.concatMap (\shape -> [ filled color shape ]))
  |> Array.fromList

type Update
  = PositionUpdate (Int,Int) (Int,Int) -- on window size / mouse position update
  | NextPicture Bool -- on click events

-- draw picture at the current mouse position.
-- change the picture when a mouse button is pressed
main1 = 
  let drawSignal =
        -- merge window size change and mouse position change as one signal
        Signal.map2 (\w p -> PositionUpdate w p) 
          Window.dimensions
          Mouse.position
      onUpdate s (((w,h),(x,y)),styInd) =
        -- state update: (<window-and-mouse>,<style-id>)
        case s of
          PositionUpdate newW newP -> ((newW,newP),styInd)
          NextPicture b -> (((w,h),(x,y)), if b then styInd+1 else styInd)
  in Signal.merge 
       drawSignal
       (Mouse.isDown |> Signal.map NextPicture)
     |> Signal.foldp onUpdate (((0,0),(0,0)),0)
     |> Signal.map (\((wh,xy),sInd) -> drawShape wh xy sInd)

-- counts up from zero with one count per second
main2 =
  Time.every Time.second
  |> Signal.foldp (\_ s -> s + 1) 0
  |> Signal.map asDiv

main = main1
