module Page.Loader exposing
    ( Cache, Event(..)
    , loadCache, load
    )

{-| This library is useful to load markdown formatted pages.
It also cares about caching already loaded pages, so once
a `url.path` is loaded successfully it will be cached.


# Definitions

@docs Cache, Event


# Common Helpers

@docs loadCache, load

-}

import Dict exposing (Dict)
import Http
import Page exposing (Page)
import Task
import Url exposing (Url)


type alias Cache msg =
    Dict String (Page msg)


type Event msg
    = Success Url (Page msg) (Cache msg)
    | Error Url Http.Error


{-| Creates a cache from a list of `(String, String)`.
The first string of the pair should contain the page name,
while the second string the page content formatted in markdown.

    loadCache [ ( "home", "# Hello, World" ) ]

-}
loadCache : List ( String, String ) -> Cache msg
loadCache pageList =
    let
        parseMap : ( String, String ) -> ( String, Page msg )
        parseMap ( pageName, text ) =
            ( pageName, Page.parser text )
    in
    Dict.fromList (List.map parseMap pageList)


handleHttpResponse : Url -> Cache msg -> Result Http.Error String -> Event msg
handleHttpResponse url cache result =
    case result of
        Ok content ->
            let
                page : Page msg
                page =
                    Page.parser content

                newCache : Cache msg
                newCache =
                    Dict.insert (Page.nameFromUrl url) page cache
            in
            Success url page newCache

        Err error ->
            Error url error


fetch : Url -> Cache msg -> (Event msg -> msg) -> Cmd msg
fetch url cache toAppMsg =
    { url = "pages/" ++ Page.nameFromUrl url ++ ".md"
    , expect = Http.expectString (handleHttpResponse url cache >> toAppMsg)
    }
        |> Http.get


{-| Loads a page given a Url, a `Cache` and a function
that converts an `Event` to an application `msg`.

    load url pageCache loaderEventToAppMsg

-}
load : Url -> Cache msg -> (Event msg -> msg) -> Cmd msg
load url cache toAppMsg =
    case Dict.get (Page.nameFromUrl url) cache of
        Just page ->
            Success url page cache
                |> Task.succeed
                |> Task.perform toAppMsg

        Nothing ->
            fetch url cache toAppMsg
