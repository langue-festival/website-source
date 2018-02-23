module Route exposing (Route, route, fromName, fromLocation, toUrl)

{-| Module for handling app routes.


# Definition

@docs Route


# Common Helpers

@docs route, fromName, fromLocation, toUrl

-}

import Navigation
import UrlParser


type alias Route =
    { name : String
    , anchor : Maybe String
    }


default : Route
default =
    { name = "index"
    , anchor = Nothing
    }


parseAnchor : String -> Route
parseAnchor path =
    case String.split "@" path of
        fst :: snd :: _ ->
            { name = fst
            , anchor = Just snd
            }

        fst :: _ ->
            { name = fst
            , anchor = Nothing
            }

        [] ->
            default


{-| Creates a `Route` from a name and an anchor.

    route "home" "an-anchor"

-}
route : String -> String -> Route
route name anchor =
    { name = name
    , anchor = Just anchor
    }


{-| Creates a `Route` from its name.

    fromName "home"

-}
fromName : String -> Route
fromName name =
    { name = name, anchor = Nothing }


{-| Parses a `Navigation.Location` and creates a `Route`.
-}
fromLocation : Navigation.Location -> Route
fromLocation location =
    case UrlParser.parseHash UrlParser.string location of
        Just path ->
            if String.startsWith "!" path then
                parseAnchor <| String.dropLeft 1 path
            else
                parseAnchor path

        Nothing ->
            default


{-| Takes ad `Route` and returns a string.
-}
toUrl : Route -> String
toUrl route =
    case route.anchor of
        Just anchor ->
            "#!" ++ route.name ++ "@" ++ anchor

        Nothing ->
            "#!" ++ route.name
