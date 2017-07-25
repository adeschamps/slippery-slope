module New exposing (..)

import Data.World
import GeoJson exposing (GeoJson)
import SlippyMap.Geo.CRS.EPSG3857 as CRS
import SlippyMap.Geo.Location as Location exposing (Location)
import SlippyMap.Geo.Point as Point exposing (Point)
import SlippyMap.Layer.GeoJson.Render as Render
import SlippyMap.Layer.Graticule as Graticule
import SlippyMap.Map.Transform as Transform exposing (Transform)
import SlippyMap.Static as Static
import Svg
import Svg.Attributes


transform : Transform
transform =
    { size = Point 512 512
    , crs = CRS.crs
    , center = Location 0 0
    , zoom = 1
    }


main : Svg.Svg msg
main =
    Static.view { width = 512, height = 512 }
        (Static.center (Location 0 0) 1)
        [ Graticule.layer ]


main2 : Svg.Svg msg
main2 =
    let
        centerPoint =
            Transform.locationToScreenPoint transform transform.center

        viewBox =
            [ 0, 0, transform.size.x, transform.size.y ]
                |> List.map toString
                |> String.join " "

        project ( lon, lat, _ ) =
            Transform.locationToScreenPoint transform (Location lon lat)

        style =
            always
                [ Svg.Attributes.stroke "#111"
                , Svg.Attributes.strokeWidth "1"
                , Svg.Attributes.fill "#111"
                , Svg.Attributes.fillOpacity "0.2"
                , Svg.Attributes.strokeLinecap "round"
                , Svg.Attributes.strokeLinejoin "round"
                ]

        graticuleStyle =
            always
                [ Svg.Attributes.stroke "#666"
                , Svg.Attributes.strokeWidth "0.5"
                , Svg.Attributes.strokeOpacity "0.5"
                , Svg.Attributes.strokeDasharray "2"

                -- , Svg.Attributes.shapeRendering "crispEdges"
                , Svg.Attributes.fill "none"
                ]

        renderConfig =
            Render.Config
                { project = project
                , style = style
                }

        graticuleRenderConfig =
            Render.Config
                { project = project
                , style = graticuleStyle
                }
    in
    Svg.svg
        [ Svg.Attributes.width (toString transform.size.x)
        , Svg.Attributes.height (toString transform.size.y)
        , Svg.Attributes.viewBox viewBox
        ]
        [ Render.renderGeoJson renderConfig (Maybe.withDefault myGeoJson Data.World.geoJson)
        , Render.renderGeoJson graticuleRenderConfig Graticule.graticule
        , Svg.circle
            [ Svg.Attributes.r "8"
            , Svg.Attributes.fill "#3388ff"
            , Svg.Attributes.stroke "white"
            , Svg.Attributes.strokeWidth "3"

            -- , Svg.Attributes.cx (toString <| floor centerPoint.x)
            -- , Svg.Attributes.cy (toString <| floor centerPoint.y)
            , Svg.Attributes.transform
                ("translate("
                    ++ toString centerPoint.x
                    ++ " "
                    ++ toString centerPoint.y
                    ++ ")"
                )
            ]
            []
        ]


myGeoJson : GeoJson
myGeoJson =
    ( GeoJson.Geometry
        (GeoJson.Polygon
            [ [ ( -6.3281250000000036
                , 42.032974332441356
                , 0
                )
              , ( 14.414062499999996
                , 33.431441335575265
                , 0
                )
              , ( 29.179687499999996
                , 62.75472592723181
                , 0
                )
              , ( -5.273437500000001
                , 62.103882522897855
                , 0
                )
              , ( -17.226562500000004
                , 47.98992166741417
                , 0
                )
              , ( -6.3281250000000036
                , 42.032974332441356
                , 0
                )
              ]
            , [ ( 4.21875
                , 56.36525013685606
                , 0
                )
              , ( 1.40625
                , 46.558860303117164
                , 0
                )
              , ( 16.171875
                , 55.37911044801047
                , 0
                )
              , ( 4.21875
                , 56.36525013685606
                , 0
                )
              ]
            ]
        )
    , Nothing
    )