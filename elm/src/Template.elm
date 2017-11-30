module Template exposing (menu, menuToggleButton)

import Html exposing (Html, a, ul, li, nav, text, button, img)
import Html.Attributes exposing (id, class, href, src)
import Html.Events exposing (onClick)
import Route exposing (Route)


type alias Model model =
    { model
        | currentRoute : Route
        , inTransition : Bool
        , menuHidden : Bool
    }


getLinkAttributes : Model m -> List (Html.Attribute msg)
getLinkAttributes model =
    if model.inTransition then
        [ class "pure-menu-link disabled" ]
    else
        [ class "pure-menu-link" ]


menuItem : String -> Route -> Model m -> Html msg
menuItem linkName linkRoute model =
    let
        itemClass =
            if linkRoute == model.currentRoute then
                "pure-menu-item pure-menu-selected"
            else
                "pure-menu-item"

        linkHref =
            href <| Route.toUrl linkRoute
    in
        li [ class itemClass ]
            [ a (linkHref :: getLinkAttributes model) [ text linkName ] ]


getMenuAttributes : Model m -> List (Html.Attribute msg)
getMenuAttributes model =
    -- id needed for `document.getElementById('menu')`
    if model.menuHidden then
        [ id "menu", class "closed pure-menu pure-menu-fixed" ]
    else
        [ id "menu", class "opened pure-menu pure-menu-fixed" ]


menu : Model m -> Html msg
menu model =
    nav (getMenuAttributes model)
        [ ul [ class "pure-menu-list" ]
            [ menuItem "Home" "home" model
            , menuItem "Cos'è Langue" "langue" model
            , menuItem "Luoghi" "luoghi" model
            , menuItem "Programma" "programma" model
            , menuItem "News e Stampa" "news-e-stampa" model
            , menuItem "Le nostre sezioni" "le-nostre-sezioni" model
            , menuItem "Chi siamo" "chi-siamo" model
            , menuItem "Partecipa" "partecipa" model
            ]
        ]


menuToggleButton : Model m -> msg -> msg -> Html msg
menuToggleButton model openMenuMsg closeMenuMsg =
    let
        toggle =
            if model.menuHidden then
                openMenuMsg
            else
                closeMenuMsg
    in
        button [ id "toggle-menu", onClick toggle ]
            [ img [ src "assets/images/menu-icon.svg" ] [] ]
