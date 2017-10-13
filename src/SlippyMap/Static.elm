module SlippyMap.Static
    exposing
        ( around
        , at
        , geoJsonLayer
        , markerLayer
        , popupLayer
        , tileLayer
        , withAttribution
        )

{-| Just a static map.

@docs at, around

@docs tileLayer, markerLayer, geoJsonLayer, popupLayer, withAttribution

-}

import GeoJson exposing (GeoJson)
import Html exposing (Html)
import SlippyMap.Geo.Location as Location exposing (Location)
import SlippyMap.Geo.Point as Point
import SlippyMap.Layer as Layer exposing (Layer)
import SlippyMap.Layer.GeoJson as GeoJson
import SlippyMap.Layer.Marker.Circle as Marker
import SlippyMap.Layer.Popup as Popup
import SlippyMap.Layer.StaticImage as StaticImageLayer
import SlippyMap.Map.Config as Config
import SlippyMap.Map.State as State
import SlippyMap.Map.Types exposing (Scene, Size)
import SlippyMap.Map.View as View


-- VIEW


{-| Render a map at a given center and zoom.
-}
at : Size -> Scene -> List (Layer msg) -> Html msg
at size scene =
    let
        config =
            Config.static (Point.fromSize size)
    in
    View.view config
        (State.at config scene)


{-| Render a map around given bounds.
-}
around : Size -> Location.Bounds -> List (Layer msg) -> Html msg
around size bounds =
    let
        config =
            Config.static (Point.fromSize size)
    in
    View.view config
        (State.around config bounds)



-- LAYER


{-| -}
tileLayer : String -> Layer msg
tileLayer urlTemplate =
    StaticImageLayer.layer
        (StaticImageLayer.config urlTemplate [])


{-| -}
markerLayer : List Location -> Layer msg
markerLayer locations =
    Marker.marker locations


{-| -}
geoJsonLayer : GeoJson -> Layer msg
geoJsonLayer =
    GeoJson.layer (GeoJson.defaultConfig (always []))


{-| -}
popupLayer : List ( Location, String ) -> Layer msg
popupLayer =
    Popup.layer Popup.config


{-| -}
withAttribution : String -> Layer msg -> Layer msg
withAttribution =
    Layer.withAttribution
