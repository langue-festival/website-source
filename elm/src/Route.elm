module Route exposing (Route, toUrl, parseLocation)

import Navigation
import UrlParser


type alias Route =
    String


toUrl : Route -> String
toUrl route =
    "#" ++ route


parseLocation : Navigation.Location -> Route
parseLocation location =
    case UrlParser.parseHash UrlParser.string location of
        Just route ->
            route

        Nothing ->
            "index"
