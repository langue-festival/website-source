module Route exposing (Route, route, routeWithAnchor, fromLocation, toUrl)

{-| Module for handling app routes.


# Definition

@docs Route


# Common Helpers

@docs route, routeWithAnchor, fromLocation, toUrl

-}

import String exposing (split)
import List exposing (foldl)
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


parseAnchor : Navigation.Location -> Maybe String
parseAnchor location =
    UrlParser.parseHash UrlParser.string location


{-| Creates a `Route` from name.

    route "home"

-}
route : String -> Route
route name =
    { name = name
    , anchor = Nothing
    }


{-| Creates a `Route` from name and anchor.

    routeWithAnchor "home" "an-anchor"

-}
routeWithAnchor : String -> String -> Route
routeWithAnchor name anchor =
    { name = name
    , anchor = Just anchor
    }


{-| Parses a `Navigation.Location` and creates a `Route`.
-}
fromLocation : Navigation.Location -> Route
fromLocation ({ pathname } as location) =
    case split "/" pathname |> foldl (Just >> always) Nothing of
        Just "main.html" ->
            default

        Just "index.html" ->
            default

        Nothing ->
            default

        Just path ->
            { name = path
            , anchor = parseAnchor location
            }


{-| Takes ad `Route` and returns a string.
-}
toUrl : Route -> String
toUrl route =
    case route.anchor of
        Just anchor ->
            route.name ++ "#" ++ anchor

        Nothing ->
            route.name
