module SlippyMap.Control.Attribution exposing (control)

{-| Attributions for a map.

@docs control

-}

import Html exposing (Html)
import Html.Attributes
import Json.Encode
import SlippyMap.Config as Config
import SlippyMap.Layer exposing (Layer)
import SlippyMap.Layer.Control as Control
import SlippyMap.Map as Map exposing (Map)


{-| -}
control : List String -> Layer msg
control attributions =
    Control.control Control.bottomRight (render attributions)


render : List String -> Map msg -> Html msg
render attributions map =
    let
        prefixText =
            Config.attributionPrefix (Map.config map)
                |> Maybe.map (\p -> p ++ " | ")
                |> Maybe.withDefault ""
    in
    Html.div [ Html.Attributes.property "innerHTML" <| Json.Encode.string <| prefixText ++ String.join ", " attributions ] []
