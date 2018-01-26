module Template exposing (Model, header, pageAttributes, pageContainerAttributes)

import Html exposing (Html, a, ul, li, nav, text, button, img)
import Html.Attributes exposing (id, class, href, src)
import Html.Events exposing (onClick)
import Route exposing (Route)


type alias Model model =
    { model
        | route : Route
        , yScroll : Int
        , menuHidden : Bool
    }


menuItem : Route -> String -> Route -> Html msg
menuItem currentRoute linkName linkRoute =
    let
        itemClass =
            if linkRoute == currentRoute then
                "pure-menu-item pure-menu-selected"
            else
                "pure-menu-item"

        linkHref =
            href <| Route.toUrl linkRoute
    in
        li [ class itemClass ]
            [ a [ linkHref, class "pure-menu-link" ]
                [ text linkName ]
            ]


getMenuAttributes : Model m -> List (Html.Attribute msg)
getMenuAttributes model =
    let
        -- id needed for `document.getElementById('menu')`
        commonAttributes =
            [ id "menu" ]
    in
        if model.menuHidden then
            class "closed" :: commonAttributes
        else
            class "opened" :: commonAttributes


socialMedia : Html msg
socialMedia =
    Html.div [ class "social-media" ]
        [ a [ href "https://www.facebook.com/langue" ]
            [ img [ src "assets/images/social-media/facebook.png" ] [] ]
        ]


menu : Model m -> Html msg
menu model =
    let
        item =
            menuItem model.route
    in
        nav (getMenuAttributes model)
            [ ul [ class "pure-menu-list" ]
                [ item "Home" "home"
                , item "Cos'è Langue" "langue"
                , item "Luoghi" "luoghi"
                , item "Programma" "programma"
                , item "News e Stampa" "news-e-stampa"
                , item "Le nostre sezioni" "le-nostre-sezioni"
                , item "Chi siamo" "chi-siamo"
                , item "Partecipa" "partecipa"
                ]
            , socialMedia
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
        button [ class "menu-toggle pure-menu-heading", onClick toggle ]
            [ img [ src "assets/images/menu-icon.svg" ] [] ]


logo : Html msg
logo =
    a [ class "heading-logo pure-menu-heading", href <| Route.toUrl "home" ]
        [ img [ src "assets/images/langue-logo.svg" ] [] ]


getHeaderAttributes : Model m -> List (Html.Attribute msg)
getHeaderAttributes model =
    let
        -- id needed for `document.getElementById('menu')`
        commonAttributes =
            [ class "pure-menu pure-menu-horizontal pure-menu-fixed" ]
    in
        if model.yScroll > 10 then
            class "roll-up" :: commonAttributes
        else
            commonAttributes


header : Model m -> msg -> msg -> Html msg
header model openMenuMsg closeMenuMsg =
    Html.header (getHeaderAttributes model)
        [ menuToggleButton model openMenuMsg closeMenuMsg
        , logo
        , menu model
        ]


pageAttributes : List (Html.Attribute msg)
pageAttributes =
    [ class "markdown pure-u-1 pure-u-md-5-6 pure-u-lg-2-3" ]


pageContainerAttributes : Model m -> List (Html.Attribute msg)
pageContainerAttributes model =
    let
        containerClass =
            model.route ++ " content-container pure-g"
    in
        if model.menuHidden then
            [ class containerClass ]
        else
            [ class ("darken " ++ containerClass) ]
