module Page.Loader exposing (Cache, Event(Success, Error), loadCache, load)

import Route exposing (Route)
import Dict exposing (Dict)
import Page exposing (Page)
import Navigation
import Http
import Task


type alias Cache msg =
    Dict String (Page msg)


type Event msg
    = Success Route (Page msg) (Cache msg)
    | Error Route Http.Error


loadCache : List ( String, String ) -> Cache msg
loadCache pageList =
    let
        parseMap : ( String, String ) -> ( String, Page msg )
        parseMap ( routeName, content ) =
            ( routeName, Page.parser content )
    in
        Dict.fromList <| List.map parseMap pageList


handleHttpResponse : Route -> Cache msg -> Result Http.Error String -> Event msg
handleHttpResponse route cache result =
    case result of
        Ok content ->
            let
                page =
                    Page.parser content

                newCache =
                    Dict.insert route.name page cache
            in
                Success route page newCache

        Err error ->
            Error route error


routeToPageUrl : Route -> String
routeToPageUrl route =
    "pages/" ++ (String.toLower route.name) ++ ".md"


fetch : Route -> Cache msg -> (Event msg -> msg) -> Cmd msg
fetch route cache toAppMsg =
    routeToPageUrl route
        |> Http.getString
        |> Http.send (handleHttpResponse route cache >> toAppMsg)


load : Navigation.Location -> Cache msg -> (Event msg -> msg) -> Cmd msg
load location cache toAppMsg =
    let
        route =
            Route.parseLocation location
    in
        case Dict.get route.name cache of
            Just page ->
                Task.perform toAppMsg <| Task.succeed <| Success route page cache

            Nothing ->
                fetch route cache toAppMsg
