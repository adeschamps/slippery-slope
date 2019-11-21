module Bandaid exposing (KeyCode, Position, decodeKey, decodePosition)

import Json.Decode as D exposing (Decoder)
import Json.Encode as E


type alias Position =
    { x : Int
    , y : Int
    }


decodePosition : Decoder Position
decodePosition =
    D.map2 Position
        (D.field "pageX" D.int)
        (D.field "pageY" D.int)


type alias KeyCode =
    Int


decodeKey : Decoder KeyCode
decodeKey =
    D.field "key" D.string |> D.map toKeyCode



{- The keyboardNavigation function in SlippyMap.Update is just going
   to turn this back into a custom type, but this is the quickest way to
   get things working without unnecessary refactoring.
-}


toKeyCode : String -> KeyCode
toKeyCode string =
    case string of
        "ArrowLeft" ->
            37

        "ArrowUp" ->
            38

        "ArrowRight" ->
            39

        "ArrowDown" ->
            40

        _ ->
            0
