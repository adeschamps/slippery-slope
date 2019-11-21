module SlippyMap.Layer.Marker exposing (Config, config, layer)

{-| A layer to display markers.

@docs Config, config, layer

-}

import Json.Decode
import SlippyMap.Events exposing (Event)
import SlippyMap.Geo.Location exposing (Location)
import SlippyMap.Layer as Layer exposing (Layer)
import SlippyMap.Map as Map exposing (Map)
import Svg exposing (Svg)
import Svg.Attributes
import VirtualDom



-- CONFIG


{-| Configuration for the layer.
-}
type Config marker msg
    = Config
        { location : marker -> Location
        , icon : marker -> Svg msg
        , toEvents : List (marker -> Event marker msg)
        }


{-| -}
config : (marker -> Location) -> (marker -> Svg msg) -> List (marker -> Event marker msg) -> Config marker msg
config toLocation toIcon toEvents =
    Config
        { location = toLocation
        , icon = toIcon
        , toEvents = toEvents
        }


{-| -}
layer : Config marker msg -> List marker -> Layer msg
layer cfg markers =
    Layer.marker
        |> Layer.custom (render cfg markers)


{-| -}
render : Config marker msg -> List marker -> Map msg -> Svg msg
render ((Config { location }) as cfg) markers map =
    let
        locatedMarkers =
            List.map
                (\marker -> ( location marker, marker ))
                markers

        locatedMarkersFiltered =
            locatedMarkers
    in
    Svg.svg
        [ -- Important for touch pinching
          Svg.Attributes.pointerEvents "none"
        , Svg.Attributes.width "100%"
        , Svg.Attributes.height "100%"
        , Svg.Attributes.style "position: absolute;"
        ]
        (List.map (renderMarker cfg map) locatedMarkersFiltered)


renderMarker : Config marker msg -> Map msg -> ( Location, marker ) -> Svg msg
renderMarker (Config cfg) map ( location, marker ) =
    let
        markerPoint =
            Map.locationToScreenPoint map location

        events =
            List.map
                (\toEvent ->
                    let
                        { name, toDecoder } =
                            toEvent marker
                    in
                    VirtualDom.on name (VirtualDom.MayStopPropagation (toDecoder marker |> Json.Decode.map (\msg -> ( msg, True ))))
                )
                cfg.toEvents
    in
    Svg.g
        (Svg.Attributes.transform
            ("translate("
                ++ String.fromFloat markerPoint.x
                ++ " "
                ++ String.fromFloat markerPoint.y
                ++ ")"
            )
            :: (Svg.Attributes.pointerEvents "auto" :: events)
        )
        [ cfg.icon marker ]
