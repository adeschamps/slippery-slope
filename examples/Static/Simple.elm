module Static.Simple exposing (viewAround, viewAt)

import Html exposing (Html)
import SlippyMap.Bundle.Static as Map
import SlippyMap.Geo.Location as Location exposing (Location)


main : Html msg
main =
    Html.div []
        [ viewAt
        , viewAround
        ]


viewAt : Html msg
viewAt =
    Map.at { width = 600, height = 400 }
        { center = Location 0 0
        , zoom = 2
        }
        [ Map.tileLayer "https://tile.openstreetmap.org/{z}/{x}/{y}.png" ]


viewAround : Html msg
viewAround =
    Map.around { width = 600, height = 400 }
        { southWest = Location 6 35
        , northEast = Location 19 48
        }
        [ Map.tileLayer "https://tile.openstreetmap.org/{z}/{x}/{y}.png" ]
