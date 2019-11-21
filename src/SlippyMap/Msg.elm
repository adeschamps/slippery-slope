module SlippyMap.Msg exposing (Msg(..), DragMsg(..), PinchMsg(..))

{-| Messages for map state updates.

@docs Msg, DragMsg, PinchMsg

-}

-- import Keyboard exposing (KeyCode)

import Bandaid exposing (KeyCode, Position)
import SlippyMap.Geo.Point exposing (Point)
import SlippyMap.Types exposing (Focus)


{-| -}
type Msg
    = ZoomIn
    | ZoomOut
    | ZoomInAround Point
    | ZoomByAround Float Point
    | DragMsg DragMsg
    | PinchMsg PinchMsg
    | SetFocus Focus
    | KeyboardNavigation KeyCode
    | Tick Float


{-| -}
type DragMsg
    = DragStart Position
    | DragAt Position
    | DragEnd Position


{-| -}
type PinchMsg
    = PinchStart ( Position, Position )
    | PinchAt ( Position, Position )
    | PinchEnd ( Position, Position )
