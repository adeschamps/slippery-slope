module SlippyMap.Subscriptions exposing (subscriptions)

{-|

@docs subscriptions

-}

import Bandaid exposing (decodeKey, decodePosition)
import Browser.Events
import Json.Decode as Decode
import SlippyMap.Config as Config exposing (Config(..))
import SlippyMap.Msg exposing (DragMsg(..), Msg(..))
import SlippyMap.State as State exposing (State(..))
import SlippyMap.Types exposing (Focus(..), Interaction(..), Transition(..))


{-| -}
subscriptions : Config msg -> State -> Sub msg
subscriptions config state =
    case Config.tagger config of
        Just toMsg ->
            let
                ( interaction, focus, transition ) =
                    ( State.getInteraction state
                    , State.getFocus state
                    , State.getTransition state
                    )

                dragSubscriptions =
                    case interaction of
                        NoInteraction ->
                            []

                        Pinching _ ->
                            []

                        Dragging _ ->
                            [ Browser.Events.onMouseMove (decodePosition |> Decode.map (DragAt >> DragMsg))
                            , Browser.Events.onMouseUp (decodePosition |> Decode.map (DragEnd >> DragMsg))
                            ]

                keyboardNavigationSubscriptions =
                    case focus of
                        HasFocus ->
                            [ Browser.Events.onKeyDown (decodeKey |> Decode.map KeyboardNavigation) ]

                        HasNoFocus ->
                            []

                transitionSubscriptions =
                    case transition of
                        NoTransition ->
                            []

                        MoveTo _ ->
                            [ Browser.Events.onAnimationFrameDelta Tick ]

                        FlyTo _ ->
                            [ Browser.Events.onAnimationFrameDelta Tick ]
            in
            (dragSubscriptions
                ++ keyboardNavigationSubscriptions
                ++ transitionSubscriptions
            )
                |> List.map (Sub.map toMsg)
                |> Sub.batch

        Nothing ->
            Sub.none
