module SlippyMap.Layer.Control exposing (Config, bottomLeft, bottomRight, control, topLeft, topRight)

{-| A layer tor create custom controls.

@docs Config, bottomLeft, bottomRight, control, topLeft, topRight

-}

import Html exposing (Html)
import Html.Attributes
import SlippyMap.Layer as Layer exposing (Layer)
import SlippyMap.Map exposing (Map)



-- CONFIG


{-| Configuration for the layer.
-}
type Config msg
    = Config
        { position : Position
        , renderer : Map msg -> Html msg
        }


type Position
    = TopLeft
    | TopRight
    | BottomRight
    | BottomLeft


config : Position -> Config msg
config position =
    Config
        { position = position
        , renderer = always (Html.text "")
        }


withRenderer : (Map msg -> Html msg) -> Config msg -> Config msg
withRenderer renderer (Config cfg) =
    Config
        { cfg | renderer = renderer }


{-| -}
topLeft : Config msg
topLeft =
    config TopLeft


{-| -}
topRight : Config msg
topRight =
    config TopRight


{-| -}
bottomLeft : Config msg
bottomLeft =
    config BottomLeft


{-| -}
bottomRight : Config msg
bottomRight =
    config BottomRight


{-| -}
control : Config msg -> (Map msg -> Html msg) -> Layer msg
control cfg renderer =
    Layer.custom
        (render (withRenderer renderer cfg))
        Layer.control


{-| -}
render : Config msg -> Map msg -> Html msg
render (Config { position, renderer }) map =
    Html.div (positionStyle position)
        [ renderer map ]


positionStyle : Position -> List (Html.Attribute msg)
positionStyle position =
    let
        baseProperties =
            [ ( "position", "absolute" ) ]

        positionProperties =
            case position of
                TopLeft ->
                    [ ( "top", "0" )
                    , ( "left", "0" )
                    ]

                TopRight ->
                    [ ( "top", "0" )
                    , ( "right", "0" )
                    ]

                BottomRight ->
                    [ ( "bottom", "0" )
                    , ( "right", "0" )
                    ]

                BottomLeft ->
                    [ ( "bottom", "0" )
                    , ( "left", "0" )
                    ]
    in
    (baseProperties ++ positionProperties) |> List.map (\( key, value ) -> Html.Attributes.style key value)
