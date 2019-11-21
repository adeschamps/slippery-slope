module SlippyMap.Layer.Tile exposing (Config, config, layer, toUrl)

{-| Base tile layer.

@docs Config, config, layer, toUrl

-}

import Regex
import SlippyMap.Geo.Point as Point
import SlippyMap.Geo.Tile exposing (Tile)
import SlippyMap.Layer as Layer exposing (Layer)
import SlippyMap.Map as Map exposing (Map)
import Svg exposing (Svg)
import Svg.Attributes
import Svg.Keyed


{-| Configuration for the layer.
-}
type Config data msg
    = Config
        { toData : Tile -> data
        , renderData : Map msg -> data -> Svg msg
        }


{-| -}
config : (Tile -> data) -> (Map msg -> data -> Svg msg) -> Config data msg
config toData renderData =
    Config
        { toData = toData
        , renderData = renderData
        }


{-| -}
layer : Config data msg -> Layer msg
layer withConfig =
    Layer.custom (render withConfig) Layer.base


render : Config data msg -> Map msg -> Svg msg
render (Config { toData, renderData }) map =
    let
        tiles =
            Map.tileCover map

        size =
            Map.size map

        tilesRendered =
            List.map
                (tile
                    (toData >> renderData map)
                    map
                )
                tiles
    in
    Svg.Keyed.node "svg"
        [ -- Important for touch pinching
          Svg.Attributes.pointerEvents "none"
        , Svg.Attributes.width
            (String.fromFloat size.x)
        , Svg.Attributes.height
            (String.fromFloat size.y)
        ]
        tilesRendered


tile : (Tile -> Svg msg) -> Map msg -> Tile -> ( String, Svg msg )
tile renderFn map ({ z, x, y } as theTile) =
    let
        key =
            String.fromInt z
                ++ "/"
                ++ String.fromInt (x |> modBy (2 ^ z))
                ++ "/"
                ++ String.fromInt (y |> modBy (2 ^ z))

        scale =
            Map.scaleT map (toFloat z)

        origin =
            Map.origin map

        point =
            { x = toFloat x
            , y = toFloat y
            }
                |> Point.multiplyBy scale
                |> Point.subtract origin
    in
    ( key
    , Svg.g
        [ Svg.Attributes.class "tile"
        , Svg.Attributes.transform
            ("translate("
                ++ String.fromFloat point.x
                ++ " "
                ++ String.fromFloat point.y
                ++ ")"
            )
        ]
        [ renderFn theTile ]
    )


{-| Turn an url template like `https://{s}.domain.com/{z}/{x}/{y}.png` into a `Config` by replacing placeholders with actual tile data.
-}
toUrl : String -> List String -> Tile -> String
toUrl urlTemplate subDomains { z, x, y } =
    urlTemplate
        |> String.replace "{z}" (String.fromInt (max 0 z))
        |> String.replace "{x}" (String.fromInt (x |> modBy (2 ^ z)))
        |> String.replace "{y}" (String.fromInt (y |> modBy (2 ^ z)))
        -- NOTE: I think this is some sort of load balancing?
        |> String.replace "{s}"
            ((abs (x + y) |> modBy (max 1 <| List.length subDomains))
                |> (\n -> List.drop n subDomains)
                |> List.head
                |> Maybe.withDefault ""
            )
