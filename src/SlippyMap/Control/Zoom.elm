module SlippyMap.Control.Zoom exposing (Config, config, control)

{-| Zoom control for a map.

@docs Config, config, control

-}

import Html exposing (Html)
import Html.Attributes
import Html.Events
import Json.Decode
import SlippyMap.Config as Map
import SlippyMap.Layer exposing (Layer)
import SlippyMap.Layer.Control as Control
import SlippyMap.Map as Map exposing (Map)
import SlippyMap.Msg as Msg exposing (Msg)
import SlippyMap.State as Map
import Svg
import Svg.Attributes


{-| -}
type Config msg
    = Config { toMsg : Msg -> msg }


{-| -}
config : (Msg -> msg) -> Config msg
config toMsg =
    Config
        { toMsg = toMsg
        }


{-| -}
control : Config msg -> Layer msg
control cfg =
    Control.control Control.topLeft (render cfg)


{-| TODO: This also needs the general map config, or at least its min- and maxZoom
-}
render : Config msg -> Map msg -> Html msg
render (Config { toMsg }) map =
    let
        ( currentZoom, minZoom, maxZoom ) =
            ( Map.state map |> Map.getScene |> .zoom
            , Map.config map |> Map.minZoom
            , Map.config map |> Map.maxZoom
            )
    in
    Html.map toMsg <|
        Html.div []
            [ Html.button
                (List.map (\( attr, value ) -> Html.Attributes.style attr value)
                    (buttonStyleProperties
                        ++ [ ( "top", "12px" )
                           , ( "border-radius", "2px 2px 0 0" )
                           ]
                    )
                    ++ [ Html.Attributes.disabled (currentZoom >= maxZoom)
                       , Html.Events.custom "touchend"
                            (Json.Decode.succeed
                                { message = Msg.ZoomIn
                                , preventDefault = True
                                , stopPropagation = True
                                }
                            )
                       , Html.Events.custom "click"
                            (Json.Decode.succeed
                                { message = Msg.ZoomIn
                                , preventDefault = True
                                , stopPropagation = True
                                }
                            )
                       ]
                )
                [ Svg.svg
                    [ Svg.Attributes.width "24"
                    , Svg.Attributes.height "24"
                    ]
                    [ Svg.path
                        [ Svg.Attributes.d "M6,12L18,12M12,6L12,18"
                        , Svg.Attributes.strokeWidth "2"
                        , Svg.Attributes.stroke "#444"
                        ]
                        []
                    ]
                ]
            , Html.button
                (List.map (\( attr, value ) -> Html.Attributes.style attr value)
                    (buttonStyleProperties
                        ++ [ ( "top", "37px" )
                           , ( "border-radius", "0 0 2px 2px" )
                           ]
                    )
                    ++ [ Html.Attributes.disabled (currentZoom <= minZoom)
                       , Html.Events.custom "touchend"
                            (Json.Decode.succeed
                                { message = Msg.ZoomOut
                                , preventDefault = True
                                , stopPropagation = True
                                }
                            )
                       , Html.Events.custom "click"
                            (Json.Decode.succeed
                                { message = Msg.ZoomOut
                                , preventDefault = True
                                , stopPropagation = True
                                }
                            )
                       ]
                )
                [ Svg.svg
                    [ Svg.Attributes.width "24"
                    , Svg.Attributes.height "24"
                    ]
                    [ Svg.path
                        [ Svg.Attributes.d "M6,12L18,12"
                        , Svg.Attributes.strokeWidth "2"
                        , Svg.Attributes.stroke "#444"
                        ]
                        []
                    ]
                ]
            ]


buttonStyleProperties : List ( String, String )
buttonStyleProperties =
    [ ( "cursor", "pointer" )
    , ( "box-sizing", "content-box" )
    , ( "width", "24px" )
    , ( "height", "24px" )
    , ( "padding", "0" )
    , ( "background-color", "#fff" )
    , ( "color", "#000" )
    , ( "border", "1px solid #aaa" )
    , ( "position", "absolute" )
    , ( "left", "12px" )
    , ( "pointer-events", "all" )
    ]
