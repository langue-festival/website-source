module Model exposing (Model, updatePage, updatePageCache)

import Route exposing (Route)
import Html exposing (Html)
import Dict exposing (Dict)
import Msg exposing (Msg)


type alias Model =
    { currentRoute : Route
    , currentPage : List (Html Msg)
    , lastRoute : Route
    , lastPage : List (Html Msg)
    , animateTransition : Bool
    , inTransition : Bool
    , menuHidden : Bool
    , pageCache : Dict Route (List (Html Msg))
    }


updatePage : Route -> List (Html Msg) -> Model -> Model
updatePage route page model =
    { model
        | currentRoute = route
        , currentPage = page
        , lastRoute = model.currentRoute
        , lastPage = model.currentPage
    }


updatePageCache : Route -> List (Html Msg) -> Model -> Model
updatePageCache route page model =
    { model
        | pageCache = Dict.insert route page model.pageCache
    }
