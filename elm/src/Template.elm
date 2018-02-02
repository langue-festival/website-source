module Template exposing (header, pageAttributes, pageContainerAttributes)

{-| This modules is an helper to generate common html.


# Common Html

@docs header


# Common Element's Attributes

@docs pageAttributes, pageContainerAttributes

-}

import Html exposing (Html, a, ul, li, nav, text, button, img)
import Html.Attributes exposing (id, class, href)
import Html.Events exposing (onClick)
import Route exposing (Route, route, fromName)
import Asset


type alias Model model =
    { model
        | route : Route
        , yScroll : Int
        , menuHidden : Bool
        , appVersion : String
    }


menuAttributes : Model m -> List (Html.Attribute msg)
menuAttributes model =
    let
        -- id needed for `document.getElementById('menu')`
        commonAttributes =
            [ id "menu" ]
    in
        if model.menuHidden then
            class "closed" :: commonAttributes
        else
            class "opened" :: commonAttributes


socialMedia : Model m -> Html msg
socialMedia model =
    li [ class "pure-menu-item social-media" ]
        [ a [ href "https://www.facebook.com/LangueFPSL", class "pure-menu-link" ]
            [ img [ Asset.src model "assets/images/social-media/facebook.png" ] [] ]
        ]


menuParentItem : Route -> String -> Route -> List (Html msg) -> Html msg
menuParentItem currentRoute itemName linkRoute items =
    let
        numItems =
            List.length items

        attributes1 =
            [ class "pure-menu-item" ]

        attributes2 =
            if (numItems > 0 && linkRoute.name == currentRoute.name) || linkRoute == currentRoute then
                class "pure-menu-selected" :: attributes1
            else
                attributes1

        attributes3 =
            if numItems > 0 then
                class "pure-menu-has-children pure-menu-allow-hover" :: attributes2
            else
                attributes2

        linkHref =
            href <| Route.toUrl linkRoute

        link =
            a [ linkHref, class "pure-menu-link" ]
                [ text itemName ]
    in
        if numItems > 0 then
            li attributes3
                [ link, ul [ class "pure-menu-children" ] items ]
        else
            li attributes3 [ link ]


menuItem : Route -> String -> Route -> Html msg
menuItem currentRoute itemName linkRoute =
    menuParentItem currentRoute itemName linkRoute []


menu : Model m -> Html msg
menu model =
    let
        item : String -> Route -> Html msg
        item =
            menuItem model.route

        parentItem : String -> Route -> List (Html msg) -> Html msg
        parentItem =
            menuParentItem model.route
    in
        nav (menuAttributes model)
            [ ul [ class "pure-menu-list" ]
                [ item "Home" <| fromName "home"
                , parentItem "Langue"
                    (fromName "langue")
                    [ item "Chi siamo" <| route "langue" "chi-siamo"
                    , item "Persone importanti" <| route "langue" "persone-importanti"
                    , item "Contatti" <| route "langue" "contatti"
                    , item "Info" <| route "langue" "info"
                    ]
                , parentItem "Il programma"
                    (fromName "programma")
                    [ item "Le sezioni" <| route "programma" "le-sezioni"
                    , item "I luoghi" <| route "programma" "i-luoghi"
                    ]
                , parentItem "Partecipa / Join us"
                    (fromName "partecipa")
                    [ item "Come volontario/a" <| route "partecipa" "come-volontario-a"
                    , item "Come poeta/poetessa" <| route "partecipa" "come-poeta-poetessa"
                    ]
                , item "Sostienici / Support us" <| Route.fromName "sostienici"
                , item "Ringraziamenti" <| Route.fromName "ringraziamenti"
                , socialMedia model
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
        button [ class "menu-toggle pure-menu-heading", onClick toggle ]
            [ img [ Asset.src model "assets/images/menu-icon.svg" ] [] ]


logo : Model m -> Html msg
logo model =
    a [ class "heading-logo pure-menu-heading", href <| Route.toUrl <| fromName "home" ]
        [ img [ Asset.src model "assets/images/langue-logo.svg" ] [] ]


getHeaderAttributes : Model m -> List (Html.Attribute msg)
getHeaderAttributes model =
    let
        commonAttributes =
            [ class "pure-menu" ]
    in
        if model.yScroll > 10 then
            class "roll-up" :: commonAttributes
        else
            commonAttributes


br : Html msg
br =
    Html.br [] []


headerTitle : Html msg
headerTitle =
    Html.div [ class "header-title pure-menu-heading" ]
        [ Html.p [ class "header-title-main" ]
            [ Html.span [ class "header-langue" ]
                [ text "LANGUE" ]
            , br
            , text "FESTIVAL DELLA POESIA"
            , br
            , text "DI SAN LORENZO"
            ]
        , Html.p [ class "header-title-date" ]
            [ text "26 MAGGIO 2018" ]
        ]


{-| Generates an `Html msg` from a `Model`, a `msg`
to send when the menu is opened and a second `msg`
to send when it's closed.

    Template.header model OpenMenu CloseMenu

-}
header : Model m -> msg -> msg -> Html msg
header model openMenuMsg closeMenuMsg =
    Html.div (getHeaderAttributes model)
        [ Html.header [ class "header-container pure-menu-heading" ]
            [ menuToggleButton model openMenuMsg closeMenuMsg
            , headerTitle
            , logo model
            ]
        , menu model
        ]


{-| List of `Html.Attribute`s for the markdown parsed page.
-}
pageAttributes : List (Html.Attribute msg)
pageAttributes =
    [ class "markdown pure-u-1 pure-u-md-5-6 pure-u-lg-2-3" ]


{-| Produces a list of `Html.Attribute`s for the content's container.
-}
pageContainerAttributes : Model m -> List (Html.Attribute msg)
pageContainerAttributes model =
    let
        containerClass =
            model.route.name ++ " content-container pure-g"
    in
        if model.menuHidden then
            [ class containerClass ]
        else
            [ class ("darken " ++ containerClass) ]
