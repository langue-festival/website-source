port module App exposing (main)

import Page.Loader as Loader exposing (Cache)
import Route exposing (Route)
import Html exposing (Html)
import Page exposing (Page)
import Html.Attributes
import Navigation
import Template
import Http


type Msg
    = UrlChange Navigation.Location
    | LoadError Route Http.Error
    | PageLoad Route (Page Msg) (Cache Msg)
    | OnYScroll Int
    | OpenMenu
    | CloseMenu


type alias Model =
    { route : Route
    , page : Page Msg
    , yScroll : Int
    , underConstruction : Bool
    , pageCache : Cache Msg
    , menuHidden : Bool
    }


type alias Flags =
    { pages : List ( Route, String )
    , yScroll : Int
    }


init : Flags -> Navigation.Location -> ( Model, Cmd Msg )
init flags location =
    let
        model : Model
        model =
            { route = Route.parseLocation location
            , page = Page.empty
            , yScroll = flags.yScroll
            , underConstruction = location.hostname == "www.languefestival.it"
            , pageCache = Loader.loadCache flags.pages
            , menuHidden = True
            }
    in
        handleUrlChange location model


handleUrlChange : Navigation.Location -> Model -> ( Model, Cmd Msg )
handleUrlChange location model =
    let
        loaderEventToAppMsg : Loader.Event Msg -> Msg
        loaderEventToAppMsg loaderMsg =
            case loaderMsg of
                Loader.Success route page cache ->
                    PageLoad route page cache

                Loader.Error route error ->
                    LoadError route error
    in
        ( model, Loader.load location model.pageCache loaderEventToAppMsg )


handlePageLoad : Route -> Page Msg -> Model -> ( Model, Cmd Msg )
handlePageLoad route page model =
    let
        ( newModel, closeMenuCmd ) =
            { model | route = route, page = page }
                |> update CloseMenu
    in
        newModel ! [ closeMenuCmd, scrollToTop () ]


set404 : Route -> Model -> ( Model, Cmd Msg )
set404 route model =
    let
        content : String
        content =
            "#404\nNon è stato possibile trovare la pagina richiesta"

        newModel : Model
        newModel =
            { model
                | route = route
                , page = Page.parser content
            }
    in
        newModel ! []


setViewError : Route -> String -> Model -> ( Model, Cmd Msg )
setViewError route error model =
    let
        content : String
        content =
            "#Si è verificato un errore\n\n" ++ error

        newModel : Model
        newModel =
            { model
                | route = route
                , page = Page.parser content
            }
    in
        newModel ! []


handleLoadError : Route -> Http.Error -> Model -> ( Model, Cmd Msg )
handleLoadError route error model =
    case error of
        Http.BadUrl url ->
            setViewError route ("Url non valido: " ++ url) model

        Http.Timeout ->
            setViewError route "Timeout" model

        Http.NetworkError ->
            setViewError route "errore di rete" model

        Http.BadStatus response ->
            if response.status.code == 404 then
                set404 route model
            else
                setViewError route ("Status: " ++ toString response.status) model

        Http.BadPayload _ response ->
            setViewError route ("Status: " ++ toString response.status) model


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChange location ->
            handleUrlChange location model

        LoadError route error ->
            handleLoadError route error model

        PageLoad route page cache ->
            handlePageLoad route page { model | pageCache = cache }

        OnYScroll offset ->
            { model | yScroll = offset } ! []

        OpenMenu ->
            { model | menuHidden = False } ! [ startCloseMenuListener () ]

        CloseMenu ->
            { model | menuHidden = True } ! [ stopCloseMenuListener () ]


viewIndex : List (Html Msg)
viewIndex =
    [ Html.div [ Html.Attributes.class "content-container landing" ]
        [ Html.div [ Html.Attributes.class "landing-main pure-g" ]
            [ Html.div [ Html.Attributes.class "langue pure-u-1" ]
                [ Html.text "LANGUE" ]
            , Html.div [ Html.Attributes.class "pure-u-1" ]
                [ Html.text "FESTIVAL" ]
            , Html.div [ Html.Attributes.class "pure-u-1" ]
                [ Html.text "DELLA" ]
            , Html.div [ Html.Attributes.class "pure-u-1" ]
                [ Html.text "POESIA" ]
            , Html.div [ Html.Attributes.class "pure-u-1" ]
                [ Html.text "DI SAN" ]
            , Html.div [ Html.Attributes.class "pure-u-1" ]
                [ Html.text "LORENZO" ]
            ]
        , Html.p [ Html.Attributes.class "landing-date" ]
            [ Html.text "26 MAGGIO 2018" ]
        , Html.a
            [ Html.Attributes.href <| Route.toUrl "home"
            , Html.Attributes.class "enter pure-button"
            ]
            [ Html.text "ENTRA" ]
        ]
    ]


viewContent : Model -> List (Html Msg)
viewContent model =
    if model.underConstruction then
        Page.view { model | route = "under-construction", page = Page.parser "# Sito in costruzione" }
    else if model.route == "index" then
        viewIndex
    else
        Template.header model OpenMenu CloseMenu
            :: Page.view model


view : Model -> Html Msg
view model =
    Html.div [ Html.Attributes.id "root-node" ] <| viewContent model


port scrollToTop : () -> Cmd msg


port startCloseMenuListener : () -> Cmd msg


port stopCloseMenuListener : () -> Cmd msg


port notifyCloseMenu : (() -> msg) -> Sub msg


port notifyYScroll : (Int -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ notifyCloseMenu (always CloseMenu)
        , notifyYScroll OnYScroll
        ]


main : Program Flags Model Msg
main =
    Navigation.programWithFlags UrlChange
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
