module Template exposing
    ( header
    , pageAttributes, pageContainerAttributes
    , Model
    )

{-| This modules is an helper to generate common html.


# Common Html

@docs header


# Common Element's Attributes

@docs pageAttributes, pageContainerAttributes

-}

import Asset
import Html exposing (Html, a, button, img, li, nav, text, ul)
import Html.Attributes exposing (class, href, id, target)
import Html.Events exposing (onClick)
import Page
import Url exposing (Url)


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
        [ a [ href "https://www.facebook.com/LangueFPSL", target "_blank", class "pure-menu-link" ]
            [ img [ Asset.src assetsHash "assets/images/social-media/facebook.png" ] [] ]
        , a [ href "mailto:festival.langue@gmail.com", class "pure-menu-link" ]
            [ img [ Asset.src assetsHash "assets/images/social-media/mail.png" ] [] ]
        ]


menuParentItem : Url -> String -> Maybe String -> List (Html msg) -> Html msg
menuParentItem currentUrl itemName destPath childs =
    let
        numChilds : Int
        numChilds =
            List.length childs

        attributes1 : List (Html.Attribute msg)
        attributes1 =
            [ class "pure-menu-item" ]

        isPathActive : Maybe String -> Bool
        isPathActive maybePath =
            maybePath
                |> Maybe.map (\path -> String.endsWith path currentUrl.path)
                |> Maybe.withDefault False

        attributes2 : List (Html.Attribute msg)
        attributes2 =
            if isPathActive destPath then
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
            case destPath of
                Just path ->
                    a (href path :: labelAttributes) labelText

                Nothing ->
                    a (href "#" :: labelAttributes) labelText
    in
    if numChilds > 0 then
        li attributes3 [ label, childItems ]

    else
        li attributes3 [ label ]


menuItem : Url -> String -> String -> Html msg
menuItem currentUrl itemName destPath =
    menuParentItem currentUrl itemName (Just destPath) []


menu : Model -> Url -> String -> Html msg
menu model currentUrl assetsHash =
    let
        item : String -> String -> Html msg
        item =
            menuItem currentUrl

        parentItem : String -> Maybe String -> List (Html msg) -> Html msg
        parentItem =
            menuParentItem currentUrl
    in
    nav (menuAttributes model)
        [ ul [ class "pure-menu-list" ]
            [ parentItem "Langue"
                (Just "langue")
                [ item "Chi siamo" "chi-siamo"
                , item "Contatti" "contatti"
                ]
            , parentItem "Il festival"
                Nothing
                [ item "Il programma" "programma"
                , item "Le sezioni" "sezioni"
                , item "I luoghi" "luoghi"
                ]
            , parentItem "Partecipa"
                Nothing
                [ item "Come volontario/a" "partecipa-come-volontario"
                , item "Come poeta/poetessa" "partecipa-come-poeta"
                ]
            , item "Sostienici" "sostienici"
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
    a [ class "heading-logo pure-menu-heading", href "langue" ]
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
header : Model -> Url -> String -> msg -> msg -> Html msg
header model currentUrl assetsHash openMenuMsg closeMenuMsg =
    Html.div (headerAttributes model)
        [ Html.header [ class "header-container pure-menu-heading" ]
            [ menuToggleButton model assetsHash openMenuMsg closeMenuMsg
            , headerTitle
            , logo assetsHash
            ]
        , menu model currentUrl assetsHash
        ]


{-| List of `Html.Attribute`s for the markdown parsed page.
-}
pageAttributes : List (Html.Attribute msg)
pageAttributes =
    [ class "markdown pure-u-1 pure-u-md-5-6 pure-u-lg-2-3" ]


{-| Produces a list of `Html.Attribute`s for the content's container.
-}
pageContainerAttributes : Model -> Url -> List (Html.Attribute msg)
pageContainerAttributes model currentUrl =
    let
        containerAttributes : List (Html.Attribute msg)
        containerAttributes =
            [ class (Page.nameFromUrl currentUrl), class "content-container pure-g" ]
    in
    if model.menuHidden then
        containerAttributes

    else
        class "darken" :: containerAttributes
