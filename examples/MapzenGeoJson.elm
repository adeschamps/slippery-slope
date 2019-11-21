module MapzenGeoJson exposing (Feature, FeatureProperties, Model, Msg(..), TileCache, decodeProperties, getTile, init, initialLayerConfig, isInteresting, layerConfig, layerStyles, main, mapConfig, namedGeoJsonFeatureObjectToFeature, namedGeoJsonObjectToFeatures, namedGeoJsonToFeatures, newTilesToLoad, propertiesDecoder, renderFeature, sortFeatures, subscriptions, toFeatures, update, vectorTileDecoder, view)

import Dict exposing (Dict)
import GeoJson exposing (GeoJson)
import Html exposing (Html)
import Html.Attributes
import Http
import Json.Decode as Json
import RemoteData exposing (WebData)
import Set exposing (Set)
import SlippyMap.Bundle.Interactive as Map
import SlippyMap.Config as MapConfig
import SlippyMap.Geo.CRS.Stereographic as CRS
import SlippyMap.Geo.Point as Point exposing (Point)
import SlippyMap.Geo.Tile as Tile exposing (Tile)
import SlippyMap.GeoJson.Svg as RenderGeoJson
import SlippyMap.Layer as Layer
import SlippyMap.Layer.RemoteTile as RemoteTile
import SlippyMap.Map as Map exposing (Map)
import SlippyMap.Transform as Transform
import Svg exposing (Svg)
import Svg.Attributes


type alias Model =
    { mapState : Map.State
    , tiles : TileCache
    }


type alias TileCache =
    Dict Tile.Comparable (WebData (List Feature))


type Msg
    = MapMsg Map.Msg
    | TileResponse Tile.Comparable (WebData (List Feature))


type alias Feature =
    { properties : Maybe FeatureProperties
    , geometry : GeoJson.Geometry
    }


type alias FeatureProperties =
    { layerName : String
    , name : Maybe String
    , kind : String
    , minZoom : Float
    , sortRank : Int
    , labelPlacement : Bool
    }


init : ( Model, Cmd Msg )
init =
    let
        initialModel =
            Model
                (Map.at mapConfig
                    { center = { lon = 7, lat = 51 }
                    , zoom = 3
                    }
                )
                Dict.empty

        tilesToLoad =
            newTilesToLoad initialModel

        loadTiles =
            List.map
                (getTile <| layerConfig initialModel.tiles)
                tilesToLoad
    in
    initialModel ! loadTiles


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MapMsg mapMsg ->
            let
                tilesToLoad =
                    newTilesToLoad model

                loadTiles =
                    List.map
                        (getTile <| layerConfig model.tiles)
                        tilesToLoad

                newMapState =
                    Map.update mapConfig
                        mapMsg
                        model.mapState

                newTileCache =
                    tilesToLoad
                        |> List.map
                            (\tile ->
                                ( Tile.toComparable tile
                                , RemoteData.Loading
                                )
                            )
                        |> Dict.fromList
                        |> Dict.union model.tiles

                newModel =
                    { model
                        | mapState = newMapState
                        , tiles = newTileCache
                    }
            in
            newModel ! loadTiles

        TileResponse key data ->
            { model
                | tiles =
                    Dict.insert key data model.tiles
            }
                ! []


newTilesToLoad : Model -> List Tile
newTilesToLoad model =
    let
        tiles =
            Map.tileCover
                (Map.make mapConfig model.mapState)

        newTileSet =
            tiles
                |> List.map Tile.toComparable
                |> Set.fromList

        existingTileSet =
            model.tiles
                |> Dict.keys
                |> Set.fromList
    in
    Set.diff newTileSet existingTileSet
        |> Set.toList
        |> List.map Tile.fromComparable


getTile : RemoteTile.Config (List Feature) Msg -> Tile -> Cmd Msg
getTile config ({ z, x, y } as tile) =
    let
        comparable =
            Tile.toComparable tile

        url =
            RemoteTile.toUrl config tile
    in
    Http.request
        { method = "GET"
        , headers = []
        , url = url
        , body = Http.emptyBody
        , expect = Http.expectJson vectorTileDecoder
        , timeout = Nothing
        , withCredentials = False
        }
        |> RemoteData.sendRequest
        |> Cmd.map (TileResponse comparable)


mapConfig : Map.Config Msg
mapConfig =
    MapConfig.interactive { x = 600, y = 400 } MapMsg



-- |> MapConfig.withCRS CRS.crs


initialLayerConfig : RemoteTile.Config (List Feature) Msg
initialLayerConfig =
    RemoteTile.config
        "https://tile.mapzen.com/mapzen/vector/v1/all/{z}/{x}/{y}.json?api_key=mapzen-A4166oq"
        []
        |> RemoteTile.withRender
            (\( { z, x, y } as tile, features ) map ->
                let
                    zoom =
                        Map.zoom map

                    scale =
                        Map.scaleT map (toFloat z)

                    origin =
                        Map.origin map

                    point =
                        { x = toFloat x
                        , y = toFloat y
                        }
                            |> Point.multiplyBy scale

                    -- |> Point.subtract origin
                in
                Svg.g []
                    (features
                        |> List.filter
                            (\{ properties } ->
                                case properties of
                                    Nothing ->
                                        False

                                    Just props ->
                                        not props.labelPlacement
                                            && (props.minZoom < zoom)
                            )
                        |> List.concatMap
                            (renderFeature
                                (\( lon, lat, _ ) ->
                                    Map.locationToPoint map { lon = lon, lat = lat }
                                        |> Point.subtract point
                                )
                            )
                    )
            )


layerConfig : TileCache -> RemoteTile.Config (List Feature) Msg
layerConfig tileCache =
    RemoteTile.withTile
        (\tile ->
            Dict.get (Tile.toComparable tile) tileCache
                |> Maybe.map (\v -> ( tile, v ))
                |> Maybe.withDefault ( tile, RemoteData.NotAsked )
        )
        initialLayerConfig


view : Model -> Html Msg
view model =
    Html.div [ Html.Attributes.style [ ( "padding", "10px" ) ] ]
        [ Html.node "style" [] [ Html.text layerStyles ]
        , Map.viewWithEvents mapConfig
            model.mapState
            []
            [ RemoteTile.layer (layerConfig model.tiles)
                |> Layer.withAttribution "Mapzen"
            ]
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Map.subscriptions mapConfig model.mapState


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


vectorTileDecoder : Json.Decoder (List Feature)
vectorTileDecoder =
    Json.keyValuePairs GeoJson.decoder
        |> Json.map toFeatures


renderFeature : (GeoJson.Position -> Point) -> Feature -> List (Svg msg)
renderFeature project { properties, geometry } =
    let
        attributes =
            Maybe.map
                (\p ->
                    [ Svg.Attributes.class (p.layerName ++ "-layer " ++ p.kind) ]
                )
                properties
                |> Maybe.withDefault []

        geoJsonConfig =
            RenderGeoJson.config project

        children =
            case geometry of
                GeoJson.Point position ->
                    RenderGeoJson.renderGeoJsonPoint geoJsonConfig attributes position

                GeoJson.MultiPoint positionList ->
                    List.concatMap (RenderGeoJson.renderGeoJsonPoint geoJsonConfig attributes) positionList

                GeoJson.LineString positionList ->
                    RenderGeoJson.renderGeoJsonLineString geoJsonConfig attributes positionList

                GeoJson.MultiLineString positionListList ->
                    List.concatMap (RenderGeoJson.renderGeoJsonLineString geoJsonConfig attributes) positionListList

                GeoJson.Polygon positionListList ->
                    RenderGeoJson.renderGeoJsonPolygon geoJsonConfig attributes positionListList

                GeoJson.MultiPolygon positionListListList ->
                    List.concatMap (RenderGeoJson.renderGeoJsonPolygon geoJsonConfig attributes) positionListListList

                GeoJson.GeometryCollection geometryList ->
                    List.concatMap (RenderGeoJson.renderGeoJsonGeometry geoJsonConfig attributes) geometryList
    in
    children


isInteresting : ( String, GeoJson ) -> Maybe ( String, GeoJson )
isInteresting ( groupName, geojson ) =
    if groupName == "earth" || groupName /= "water" then
        -- if groupName == "roads" then
        Just ( groupName, geojson )

    else
        Nothing


toFeatures : List ( String, GeoJson ) -> List Feature
toFeatures namedGeoJson =
    namedGeoJson
        |> List.filterMap isInteresting
        |> List.concatMap namedGeoJsonToFeatures
        |> sortFeatures


sortFeatures : List Feature -> List Feature
sortFeatures features =
    List.sortBy
        (\{ properties } ->
            case properties of
                Nothing ->
                    0

                Just props ->
                    props.sortRank
        )
        features


namedGeoJsonToFeatures : ( String, GeoJson ) -> List Feature
namedGeoJsonToFeatures ( layerName, ( geoJsonObject, _ ) ) =
    namedGeoJsonObjectToFeatures layerName geoJsonObject


namedGeoJsonObjectToFeatures : String -> GeoJson.GeoJsonObject -> List Feature
namedGeoJsonObjectToFeatures layerName geoJsonObject =
    case geoJsonObject of
        GeoJson.Geometry geometry ->
            [ { properties = Nothing, geometry = geometry } ]

        GeoJson.Feature featureObject ->
            [ namedGeoJsonFeatureObjectToFeature layerName featureObject ]

        GeoJson.FeatureCollection featureCollection ->
            List.map (namedGeoJsonFeatureObjectToFeature layerName) featureCollection


namedGeoJsonFeatureObjectToFeature : String -> GeoJson.FeatureObject -> Feature
namedGeoJsonFeatureObjectToFeature layerName { properties, geometry } =
    { properties = decodeProperties layerName properties
    , geometry =
        geometry
            |> Maybe.withDefault (GeoJson.GeometryCollection [])
    }


decodeProperties : String -> Json.Value -> Maybe FeatureProperties
decodeProperties layerName properties =
    Json.decodeValue (propertiesDecoder layerName) properties
        |> Result.toMaybe


propertiesDecoder : String -> Json.Decoder FeatureProperties
propertiesDecoder layerName =
    Json.succeed (FeatureProperties layerName)
        & Json.maybe (Json.field "name" Json.string)
        & Json.field "kind" Json.string
        & Json.field "min_zoom" Json.float
        & Json.field "sort_rank" Json.int
        & (Json.maybe (Json.field "label_placement" Json.bool)
            |> Json.map
                (\placement ->
                    case placement of
                        Just bool ->
                            bool

                        Nothing ->
                            False
                )
          )


(&) : Json.Decoder (a -> b) -> Json.Decoder a -> Json.Decoder b
(&) =
    Json.map2 (<|)


layerStyles : String
layerStyles =
    """
.tile polyline {
  fill: none;
  stroke: #fff;
  stroke-linejoin: round;
  stroke-linecap: round;
}
.tile polygon {
  fill: none;
  stroke: #fff;
  stroke-linejoin: round;
  stroke-linecap: round;
}
.tile circle {
  fill: none;
  stroke: #fff;
  stroke-linejoin: round;
  stroke-linecap: round;
}
.tile path {
  fill: none;
  stroke: #fff;
  stroke-linejoin: round;
  stroke-linecap: round;
}

.tile .earth { fill: #607d8b; stroke: none; }
.tile .water-layer, .tile .river, .tile .stream, .tile .canal { fill: none; stroke: #ffeb3b; stroke-width: 1.5px; }
.tile .water, .tile .ocean { fill: #2196f3; }
.tile .riverbank { fill: #2196f3; }
.tile .water_boundary, .tile .ocean_boundary, .tile .riverbank_boundary { fill: none; stroke: #93cbc4; stroke-width: 0.5px; }
.tile .major_road { stroke: #fb7b7a; stroke-width: 1px; }
.tile .minor_road { stroke: #999; stroke-width: 0.5px; }
.tile .highway { stroke: #FA4A48; stroke-width: 1.5px; }
.tile .transit-layer { stroke: none; }
.tile .buildings-layer { stroke: #987284; stroke-width: 0.15px; }
.tile .urban_area { fill: #987284; stroke: #987284; stroke-width: 0.15px; }
.tile .park, .tile .nature_reserve, .tile .wood, .tile .protected_land { fill: #88D18A; stroke: #88D18A; stroke-width: 0.5px; }
.tile .pier { fill: #fff; stroke: #fff; stroke-width: 0.5px; }
.tile .rail { stroke: #503D3F; stroke-width: 0.5px; }

/*
polyline {
    fill: none;
    stroke: #333;
    stroke-width: 1px;
}
polygon {
    fill: rgba(0,0,0,0.2);
    stroke: rgba(0,0,0,0.2);
    stroke-width: 1px;
}
circle {
    fill: rgba(255,0,0,0.2);
    stroke: rgba(255,0,0,0.2);
    stroke-width: 1px;
}
.meadow polygon,
.grass polygon,
.scrub polygon,
.farmland polygon {
    fill: green;
    stroke: green;
    stroke-width: 1px;
}
.earth polygon {
    fill: brown;
    stroke: brown;
    stroke-width: 1px;
}
.river *,
.water *,
.canal *,
.basin *,
.stream *,
.ocean * {
    stroke: blue;
}
.train polyline,
.tram polyline,
.subway polyline {
    stroke: black;
    stroke-dasharray: 5;
}
.county polyline,
.locality polyline {
    stroke: red;
}
.major_road polyline,
.highway polyline {
    stroke: orange;
}
*/
    """
