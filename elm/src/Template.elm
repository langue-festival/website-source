module Template exposing (Model, header, pageAttributes, pageContainerAttributes)

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


type alias Model =
    { yScroll : Int
    , menuHidden : Bool
    }


menuAttributes : Model -> List (Html.Attribute msg)
menuAttributes model =
    let
        commonAttributes : List (Html.Attribute msg)
        commonAttributes =
            [ id "menu" ]
    in
        if model.menuHidden then
            class "closed" :: commonAttributes
        else
            class "opened" :: commonAttributes


socialMedia : String -> Html msg
socialMedia assetsHash =
    li [ class "pure-menu-item social-media" ]
        [ a [ href "https://www.facebook.com/LangueFPSL", class "pure-menu-link" ]
            [ img [ Asset.src assetsHash "assets/images/social-media/facebook.png" ] [] ]
        ]


menuParentItem : Route -> String -> Maybe Route -> List (Html msg) -> Html msg
menuParentItem currentRoute itemName linkRoute childs =
    let
        numChilds : Int
        numChilds =
            List.length childs

        linkRouteName : String
        linkRouteName =
            Maybe.map .name linkRoute
                |> Maybe.withDefault ""

        attributes1 : List (Html.Attribute msg)
        attributes1 =
            [ class "pure-menu-item" ]

        attributes2 : List (Html.Attribute msg)
        attributes2 =
            if linkRoute == Just currentRoute then
                class "pure-menu-selected" :: attributes1
            else
                attributes1

        attributes3 : List (Html.Attribute msg)
        attributes3 =
            if numChilds > 0 then
                class "pure-menu-has-children pure-menu-allow-hover" :: attributes2
            else
                attributes2

        childItems : Html msg
        childItems =
            ul [ class "pure-menu-children" ] childs

        labelAttributes : List (Html.Attribute msg)
        labelAttributes =
            [ class "pure-menu-link" ]

        labelText : List (Html msg)
        labelText =
            [ text itemName ]

        label : Html msg
        label =
            case Maybe.map Route.toUrl linkRoute of
                Just url ->
                    a (href url :: labelAttributes) labelText

                Nothing ->
                    a labelAttributes labelText
    in
        if numChilds > 0 then
            li attributes3 [ label, childItems ]
        else
            li attributes3 [ label ]


menuItem : Route -> String -> Route -> Html msg
menuItem currentRoute itemName linkRoute =
    menuParentItem currentRoute itemName (Just linkRoute) []


menu : Model -> Route -> String -> Html msg
menu model currentRoute assetsHash =
    let
        item : String -> Route -> Html msg
        item =
            menuItem currentRoute

        parentItem : String -> Maybe Route -> List (Html msg) -> Html msg
        parentItem =
            menuParentItem currentRoute
    in
        nav (menuAttributes model)
            [ ul [ class "pure-menu-list" ]
                [ parentItem "Langue"
                    (Just <| fromName "langue")
                    [ item "Chi siamo" <| fromName "chi-siamo"
                    , item "Contatti" <| fromName "contatti"
                    ]
                , parentItem "Il festival"
                    Nothing
                    [ item "Il programma" <| fromName "programma"
                    , item "Le sezioni" <| fromName "sezioni"
                    , item "I luoghi" <| fromName "luoghi"
                    ]
                , parentItem "Partecipa"
                    (Nothing)
                    [ item "Come volontario/a" <| fromName "partecipa-come-volontario"
                    , item "Come poeta/poetessa" <| fromName "partecipa-come-poeta"
                    ]
                , item "Sostienici" <| fromName "sostienici"
                , socialMedia assetsHash
                ]
            ]


menuToggleButton : Model -> String -> msg -> msg -> Html msg
menuToggleButton model assetsHash openMenuMsg closeMenuMsg =
    let
        toggle : msg
        toggle =
            if model.menuHidden then
                openMenuMsg
            else
                closeMenuMsg
    in
        button [ class "menu-toggle pure-menu-heading", onClick toggle ]
            [ img [ Asset.src assetsHash "assets/images/menu-icon.svg" ] [] ]


logo : String -> Html msg
logo assetsHash =
    a [ class "heading-logo pure-menu-heading", href <| Route.toUrl <| fromName "home" ]
        [ img [ Asset.src assetsHash "assets/images/langue-logo.svg" ] [] ]


headerAttributes : Model -> List (Html.Attribute msg)
headerAttributes model =
    let
        commonAttributes : List (Html.Attribute msg)
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


{-| Generates application header.

    Template.header model assetsHash OpenMenu CloseMenu

-}
header : Model -> Route -> String -> msg -> msg -> Html msg
header model currentRoute assetsHash openMenuMsg closeMenuMsg =
    Html.div (headerAttributes model)
        [ Html.header [ class "header-container pure-menu-heading" ]
            [ menuToggleButton model assetsHash openMenuMsg closeMenuMsg
            , headerTitle
            , logo assetsHash
            ]
        , menu model currentRoute assetsHash
        ]


{-| List of `Html.Attribute`s for the markdown parsed page.
-}
pageAttributes : List (Html.Attribute msg)
pageAttributes =
    [ class "markdown pure-u-1 pure-u-md-5-6 pure-u-lg-2-3" ]


{-| Produces a list of `Html.Attribute`s for the content's container.
-}
pageContainerAttributes : Model -> Route -> List (Html.Attribute msg)
pageContainerAttributes model currentRoute =
    let
        containerAttributes : List (Html.Attribute msg)
        containerAttributes =
            [ class currentRoute.name, class "content-container pure-g" ]
    in
        if model.menuHidden then
            containerAttributes
        else
            class "darken" :: containerAttributes
