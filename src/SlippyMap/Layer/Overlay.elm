module SlippyMap.Layer.Overlay
    exposing
        ( Config
        , defaultConfig
        , layer
        )

{-| A layer to show something at specific bounds.

@docs Config, defaultConfig, layer

-}

import SlippyMap.Geo.Location as Location exposing (Location)
import SlippyMap.Geo.Point as Point exposing (Point)
import SlippyMap.Layer as Layer exposing (Layer)
import SlippyMap.Map.Transform as Transform exposing (Transform)
import Svg exposing (Svg)
import Svg.Attributes


-- CONFIG


{-| Configuration for the layer.
-}
type Config overlay msg
    = Config { renderOverlay : ( Float, Float ) -> overlay -> Svg msg }


{-| -}
defaultConfig : Config String msg
defaultConfig =
    Config
        { renderOverlay = imageOverlay
        }


imageOverlay : ( Float, Float ) -> String -> Svg msg
imageOverlay ( width, height ) url =
    Svg.image
        [ Svg.Attributes.width (toString width)
        , Svg.Attributes.height (toString height)
        , Svg.Attributes.xlinkHref url
        ]
        []



-- LAYER


{-| -}
layer : Config overlay msg -> List ( Location.Bounds, overlay ) -> Layer msg
layer config boundedOverlays =
    Layer.withRender Layer.overlay (render config boundedOverlays)


render : Config overlay msg -> List ( Location.Bounds, overlay ) -> Transform -> Svg msg
render config boundedOverlays transform =
    Svg.g []
        (List.map (renderOverlay config transform) boundedOverlays)


renderOverlay : Config overlay msg -> Transform -> ( Location.Bounds, overlay ) -> Svg msg
renderOverlay (Config config) transform ( bounds, overlay ) =
    let
        origin =
            Transform.origin transform

        southWestPoint =
            Transform.locationToPoint transform
                bounds.southWest

        northEastPoint =
            Transform.locationToPoint transform
                bounds.northEast

        overlaySize =
            ( northEastPoint.x - southWestPoint.x
            , southWestPoint.y - northEastPoint.y
            )

        translate =
            Point.subtract origin southWestPoint
    in
    Svg.g
        [ Svg.Attributes.transform
            ("translate("
                ++ toString translate.x
                ++ " "
                ++ toString (translate.y - southWestPoint.y + northEastPoint.y)
                ++ ")"
            )
        ]
        [ config.renderOverlay
            overlaySize
            overlay
        ]
