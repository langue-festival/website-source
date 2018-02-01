module Route exposing (Route, route, fromName, toUrl, parseLocation)

import Navigation
import UrlParser


type alias Route =
    { name : String
    , anchor : Maybe String
    }


route : String -> String -> Route
route name anchor =
    { name = name
    , anchor = Just anchor
    }


fromName : String -> Route
fromName name =
    { name = name, anchor = Nothing }


toUrl : Route -> String
toUrl route =
    case route.anchor of
        Just anchor ->
            "#" ++ route.name ++ "@" ++ anchor

        Nothing ->
            "#" ++ route.name


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


parseLocation : Navigation.Location -> Route
parseLocation location =
    case UrlParser.parseHash UrlParser.string location of
        Just path ->
            parseAnchor path

        Nothing ->
            default
