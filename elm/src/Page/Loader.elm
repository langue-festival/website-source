module Page.Loader exposing (Cache, Event(Success, Error), loadCache, load)

{-| This library is useful to load markdown formatted pages.
It also cares about caching already loaded pages, so once
a `Route` is loaded successfully it will be cached.


# Definitions

@docs Cache, Event


# Common Helpers

@docs loadCache, load

-}

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


{-| Creates a cache from a list of `(String, String)`.
The first string of the pair should contain the route's name,
while the second string the page content formatted in markdown.

    loadCache [ ( "home", "# Hello, World" ) ]

-}
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
                page : Page msg
                page =
                    Page.parser content

                newCache : Cache msg
                newCache =
                    Dict.insert route.name page cache
            in
                Success route page newCache

        Err error ->
            Error route error


routeToPageUrl : Route -> String
routeToPageUrl route =
    "pages/" ++ String.toLower route.name ++ ".md"


fetch : Route -> Cache msg -> (Event msg -> msg) -> Cmd msg
fetch route cache toAppMsg =
    routeToPageUrl route
        |> Http.getString
        |> Http.send (handleHttpResponse route cache >> toAppMsg)


{-| Loads a page given a `Navigation.Location`, a `Cache` and a function
that converts an `Event` to an application `msg`.
The `Location` is parsed with `Route` module, if the resulting route name
is already present in current cache no request will be made.

    load location pageCache loaderEventToAppMsg

-}
load : Navigation.Location -> Cache msg -> (Event msg -> msg) -> Cmd msg
load location cache toAppMsg =
    let
        route : Route
        route =
            Route.fromLocation location
    in
        case Dict.get route.name cache of
            Just page ->
                Task.perform toAppMsg <| Task.succeed <| Success route page cache

            Nothing ->
                fetch route cache toAppMsg
