module SlippyMap.Layer.Popup exposing (Config, config, withCloseMsg, layer)

{-| A layer to display popups.

@docs Config, config, withCloseMsg, layer

-}

import Html exposing (Html)
import Html.Attributes exposing (class, style)
import Html.Events
import SlippyMap.Geo.Location exposing (Location)
import SlippyMap.Layer as Layer exposing (Layer)
import SlippyMap.Map as Map exposing (Map)



-- CONFIG


{-| Configuration for the layer.
-}
type Config popup msg
    = Config
        { renderPopup : popup -> Html msg
        , closeMsg : Maybe msg
        }


{-| -}
config : Config String msg
config =
    Config
        { renderPopup = simplePopup
        , closeMsg = Nothing
        }


{-| -}
withCloseMsg : msg -> Config popup msg -> Config popup msg
withCloseMsg closeMsg (Config cfg) =
    Config
        { cfg | closeMsg = Just closeMsg }


simplePopup : String -> Html msg
simplePopup content =
    Html.div
        [ class "popup--simple"
        , style "filter" "drop-shadow(rgba(0,0,0,0.2) 0px 2px 4px)"
        , style "transform" "translate(6px, -50%)"
        , style "display" "flex"
        , style "align-items" "center"
        ]
        [ Html.div
            [ style "position" "relative"
            , style "left" "6px"
            , style "background" "#fff"
            , style "border-radius" "0 0 0 2px"
            , style "width" "12px"
            , style "height" "12px"
            , style "transform" "rotate(45deg)"
            ]
            []
        , Html.div
            [ style "position" "relative"
            , style "background" "#fff"
            , style "border-radius" "4px"
            , style "padding" "0.5em 1em"
            , style "min-width" "60px"
            , style "max-width" "240px"
            ]
            [ Html.text content ]
        ]



-- LAYER


{-| -}
layer : Config popup msg -> List ( Location, popup ) -> Layer msg
layer cfg locatedPopups =
    Layer.custom (render cfg locatedPopups) Layer.popup


render : Config popup msg -> List ( Location, popup ) -> Map msg -> Html msg
render cfg locatedPopups map =
    Html.div [ class "layer--popup" ]
        (List.map (renderPopup cfg map) locatedPopups)


renderPopup : Config popup msg -> Map msg -> ( Location, popup ) -> Html msg
renderPopup (Config cfg) map ( location, popup ) =
    let
        popupPoint =
            Map.locationToScreenPoint map location

        closeAttributes =
            cfg.closeMsg
                |> Maybe.map (Html.Events.onClick >> List.singleton)
                |> Maybe.withDefault []
    in
    Html.div
        ([ class "popup__positioner"
         , style "position" "absolute"
         , style "pointer-events" "auto"
         , style "transform" <|
            "translate("
                ++ String.fromFloat popupPoint.x
                ++ "px, "
                ++ String.fromFloat popupPoint.y
                ++ "px)"
         ]
            ++ closeAttributes
        )
        [ cfg.renderPopup popup ]
