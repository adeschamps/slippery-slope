module SlippyMap.Layer.Tile
    exposing
        ( Config
        , config
        , layer
        , toUrl
        )

{-| Base tile layer.

@docs Config, config, layer, toUrl

-}

import Regex
import SlippyMap.Geo.Point as Point exposing (Point)
import SlippyMap.Geo.Tile as Tile exposing (Tile)
import SlippyMap.Layer as Layer exposing (Layer)
import SlippyMap.Map.Transform as Transform exposing (Transform)
import Svg exposing (Svg)
import Svg.Attributes
import Svg.Keyed


{-| Configuration for the layer.

TODO: add tileSize

-}
type Config data msg
    = Config
        { toData : Tile -> data
        , renderData : Transform -> data -> Svg msg
        }


{-| -}
config : (Tile -> data) -> (Transform -> data -> Svg msg) -> Config data msg
config toData renderData =
    Config
        { toData = toData
        , renderData = renderData
        }


{-| -}
layer : Config data msg -> Layer msg
layer config =
    Layer.custom (render config) Layer.base


render : Config data msg -> Transform -> Svg msg
render (Config { toData, renderData }) transform =
    let
        tiles =
            Transform.tileCover transform

        tilesRendered =
            List.map
                (tile (toData >> renderData transform) transform)
                tiles
    in
    Svg.Keyed.node "svg"
        [ -- Important for touch pinching
          Svg.Attributes.pointerEvents "none"
        , Svg.Attributes.width (toString transform.size.x)
        , Svg.Attributes.height (toString transform.size.y)
        ]
        tilesRendered


tile : (Tile -> Svg msg) -> Transform -> Tile -> ( String, Svg msg )
tile render transform ({ z, x, y } as tile) =
    let
        key =
            toString z
                ++ "/"
                ++ toString (x % (2 ^ z))
                ++ "/"
                ++ toString (y % (2 ^ z))

        scale =
            transform.crs.scale
                (transform.zoom - toFloat z)

        origin =
            Transform.origin transform

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
                ++ toString point.x
                ++ " "
                ++ toString point.y
                ++ ")"
            )
        ]
        [ render tile ]
    )


{-| Turn an url template like `https://{s}.domain.com/{z}/{x}/{y}.png` into a `Config` by replacing placeholders with actual tile data.
-}
toUrl : String -> List String -> Tile -> String
toUrl urlTemplate subDomains { z, x, y } =
    urlTemplate
        |> replace "{z}" (toString (max 0 z))
        |> replace "{x}" (toString (x % (2 ^ z)))
        |> replace "{y}" (toString (y % (2 ^ z)))
        |> replace "{s}"
            ((abs (x + y) % (max 1 <| List.length subDomains))
                |> flip List.drop subDomains
                |> List.head
                |> Maybe.withDefault ""
            )


replace : String -> String -> String -> String
replace search substitution string =
    string
        |> Regex.replace Regex.All
            (Regex.regex (Regex.escape search))
            (\_ -> substitution)
