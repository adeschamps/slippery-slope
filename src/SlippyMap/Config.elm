module SlippyMap.Config exposing (Config, static, interactive, size, withCRS, withZoomSnap, withZoomDelta, withMaxZoom, withMinZoom, withoutZoomControl, zoomControl, Interactions, crs, minZoom, maxZoom, zoomDelta, zoomSnap, tagger, interactions, attributionPrefix, withoutAttributionControl, withAttributionPrefix, pointerPositionDecoder)

{-|

@docs Config, static, interactive, size, withCRS, withZoomSnap, withZoomDelta, withMaxZoom, withMinZoom, withoutZoomControl, zoomControl, Interactions, crs, minZoom, maxZoom, zoomDelta, zoomSnap, tagger, interactions, attributionPrefix, withoutAttributionControl, withAttributionPrefix, pointerPositionDecoder

-}

import DOM
import Json.Decode as Decode exposing (Decoder)
import SlippyMap.Geo.CRS exposing (CRS)
import SlippyMap.Geo.CRS.EPSG3857 as EPSG3857
import SlippyMap.Geo.Point exposing (Point)
import SlippyMap.Msg exposing (Msg)


{-| Configuration for the map.
-}
type Config msg
    = Config (ConfigInternal msg)


type alias ConfigInternal msg =
    { attributionPrefix : Maybe String
    , size : Point
    , minZoom : Float
    , maxZoom : Float
    , zoomSnap : Float
    , zoomDelta : Float
    , toMsg : Maybe (Msg -> msg)
    , crs : CRS
    , zoomControl : Bool
    , attributionControl : Bool
    , interactions : Interactions
    , pointerPositionDecoder : Decoder Point
    }


defaultConfigInternal : ConfigInternal msg
defaultConfigInternal =
    { attributionPrefix = Nothing
    , size = { x = 600, y = 400 }
    , minZoom = 0
    , maxZoom = 19
    , zoomSnap = 1
    , zoomDelta = 1
    , toMsg = Nothing
    , crs = EPSG3857.crs
    , zoomControl = False
    , attributionControl = True
    , interactions = interactiveInteractions
    , pointerPositionDecoder = domPointerPositionDecoder
    }


domPointerPositionDecoder : Decoder Point
domPointerPositionDecoder =
    Decode.map5
        (\clientX clientY rect clientLeft clientTop ->
            { x = clientX - rect.left - clientLeft
            , y = clientY - rect.top - clientTop
            }
        )
        (Decode.field "clientX" Decode.float)
        (Decode.field "clientY" Decode.float)
        -- (DOM.target mapPosition)
        (Decode.field "currentTarget" mapPosition)
        (Decode.field "currentTarget" <|
            Decode.field "clientLeft" Decode.float
        )
        (Decode.field "currentTarget" <|
            Decode.field "clientTop" Decode.float
        )


mapPosition : Decoder DOM.Rectangle
mapPosition =
    Decode.oneOf
        [ DOM.boundingClientRect
        , Decode.lazy (\_ -> DOM.parentElement mapPosition)
        ]


{-| -}
type alias Interactions =
    { scrollWheelZoom : Bool
    , doubleClickZoom : Bool
    , touchZoom : Bool
    , keyboardControl : Bool
    }


interactiveInteractions : Interactions
interactiveInteractions =
    { scrollWheelZoom = True
    , doubleClickZoom = True
    , touchZoom = True
    , keyboardControl = True
    }


{-| -}
static : Point -> Config msg
static size_ =
    Config
        { defaultConfigInternal | size = size_ }


{-| -}
interactive : Point -> (Msg -> msg) -> Config msg
interactive size_ toMsg =
    Config
        { defaultConfigInternal
            | size = size_
            , toMsg = Just toMsg
            , zoomControl = True
        }


{-| -}
withCRS : CRS -> Config msg -> Config msg
withCRS crs_ (Config configInternal) =
    Config
        { configInternal | crs = crs_ }


{-| -}
withoutZoomControl : Config msg -> Config msg
withoutZoomControl (Config configInternal) =
    Config
        { configInternal | zoomControl = False }


{-| -}
withAttributionPrefix : String -> Config msg -> Config msg
withAttributionPrefix prefix (Config configInternal) =
    Config
        { configInternal | attributionPrefix = Just prefix }


{-| -}
withoutAttributionControl : Config msg -> Config msg
withoutAttributionControl (Config configInternal) =
    Config
        { configInternal | attributionControl = False }


{-| -}
withMaxZoom : Float -> Config msg -> Config msg
withMaxZoom atMaxZoom (Config configInternal) =
    Config
        { configInternal | maxZoom = atMaxZoom }


{-| -}
withMinZoom : Float -> Config msg -> Config msg
withMinZoom atMinZoom (Config configInternal) =
    Config
        { configInternal | minZoom = atMinZoom }


{-| -}
withZoomSnap : Float -> Config msg -> Config msg
withZoomSnap atZoomSnap (Config configInternal) =
    Config
        { configInternal | zoomSnap = atZoomSnap }


{-| -}
withZoomDelta : Float -> Config msg -> Config msg
withZoomDelta atZoomDelta (Config configInternal) =
    Config
        { configInternal | zoomDelta = atZoomDelta }


{-| -}
size : Config msg -> Point
size (Config config) =
    config.size


{-| -}
crs : Config msg -> CRS
crs (Config config) =
    config.crs


{-| -}
minZoom : Config msg -> Float
minZoom (Config config) =
    config.minZoom


{-| -}
maxZoom : Config msg -> Float
maxZoom (Config config) =
    config.maxZoom


{-| -}
zoomDelta : Config msg -> Float
zoomDelta (Config config) =
    config.zoomDelta


{-| -}
zoomSnap : Config msg -> Float
zoomSnap (Config config) =
    config.zoomSnap


{-| -}
zoomControl : Config msg -> Bool
zoomControl (Config config) =
    config.zoomControl


{-| -}
tagger : Config msg -> Maybe (Msg -> msg)
tagger (Config { toMsg }) =
    toMsg


{-| -}
interactions : Config msg -> Interactions
interactions (Config config) =
    config.interactions


{-| -}
attributionPrefix : Config msg -> Maybe String
attributionPrefix (Config config) =
    config.attributionPrefix


{-| -}
pointerPositionDecoder : Config msg -> Decoder Point
pointerPositionDecoder (Config config) =
    config.pointerPositionDecoder
