module Page.Loader exposing (load)

import Msg exposing (Msg(ContentLoad, ContentLoadError, PageLoad))
import Route exposing (Route)
import Model exposing (Model)
import Dict exposing (Dict)
import Navigation
import Http
import Task


handleResponse : Route -> Result Http.Error String -> Msg
handleResponse route result =
    case result of
        Ok page ->
            ContentLoad ( route, page )

        Err e ->
            ContentLoadError ( route, e )


routeToPageUrl : Route -> String
routeToPageUrl route =
    "pages/" ++ (String.toLower route) ++ ".md"


fetch : Route -> Cmd Msg
fetch route =
    routeToPageUrl route
        |> Http.getString
        |> Http.send (handleResponse route)


load : Navigation.Location -> Model -> Cmd Msg
load location model =
    let
        route =
            Route.parseLocation location
    in
        case Dict.get route model.pageCache of
            Just page ->
                Task.perform (\page -> PageLoad ( route, page )) (Task.succeed page)

            Nothing ->
                fetch route
