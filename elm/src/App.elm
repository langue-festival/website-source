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
    | YScroll Int
    | OpenMenu
    | CloseMenu
    | UpdateUrl String


type alias Model =
    { route : Route
    , page : Page Msg
    , assetsHash : String
    , underConstruction : Bool
    , pageCache : Cache Msg
    , template : Template.Model
    }


type alias Flags =
    { pages : List ( String, String )
    , assetsHash : String
    , yScroll : Int
    , underConstruction : Bool
    }


init : Flags -> Navigation.Location -> ( Model, Cmd Msg )
init flags location =
    let
        template : Template.Model
        template =
            { yScroll = flags.yScroll
            , menuHidden = True
            }

        model : Model
        model =
            { route = Route.fromLocation location
            , page = Page.empty
            , template = template
            , assetsHash = flags.assetsHash
            , underConstruction = flags.underConstruction
            , pageCache = Loader.loadCache flags.assetsHash flags.pages
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

        loadCmd : Cmd Msg
        loadCmd =
            Loader.load location model.assetsHash model.pageCache loaderEventToAppMsg
    in
        model ! [ loadCmd ]


handlePageLoad : Route -> Page Msg -> Model -> ( Model, Cmd Msg )
handlePageLoad route page model =
    let
        ( newModel, closeMenuCmd ) =
            { model | route = route, page = page }
                |> update CloseMenu

        commonCmds : List (Cmd Msg)
        commonCmds =
            [ closeMenuCmd
            , setTitle page.title
            , setMetaDescription page.description
            ]
    in
        case route.anchor of
            Just anchor ->
                newModel ! (scrollIntoView anchor :: commonCmds)

            Nothing ->
                newModel ! (scrollToTop () :: commonCmds)


handleYScroll : Int -> Model -> ( Model, Cmd Msg )
handleYScroll yScroll ({ template } as model) =
    let
        newTemplate : Template.Model
        newTemplate =
            { template | yScroll = yScroll }
    in
        { model | template = newTemplate } ! []


handleOpenMenu : Model -> ( Model, Cmd Msg )
handleOpenMenu ({ template } as model) =
    let
        newTemplate =
            { template | menuHidden = False }
    in
        { model | template = newTemplate } ! [ menuOpened (), scrollToTop () ]


handleCloseMenu : Model -> ( Model, Cmd Msg )
handleCloseMenu ({ template } as model) =
    let
        newTemplate =
            { template | menuHidden = True }
    in
        { model | template = newTemplate } ! [ menuClosed () ]


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
                , page = Page.parser model.assetsHash content
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
                , page = Page.parser model.assetsHash content
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

        YScroll offset ->
            handleYScroll offset model

        OpenMenu ->
            handleOpenMenu model

        CloseMenu ->
            handleCloseMenu model

        UpdateUrl url ->
            model ! [ Navigation.newUrl url ]


pageTemplate : Model -> Html Msg
pageTemplate model =
    Html.section (Template.pageContainerAttributes model.template model.route)
        [ Html.div Template.pageAttributes
            [ model.page.content ]
        ]


viewContent : Model -> List (Html Msg)
viewContent model =
    if model.underConstruction then
        let
            tmpModel : Model
            tmpModel =
                { model
                    | route = Route.route "under-construction"
                    , page = Page.parser model.assetsHash "# Sito in costruzione"
                }
        in
            [ pageTemplate tmpModel ]
    else if model.route.name == "index" then
        [ model.page.content ]
    else
        [ Template.header model.template model.route model.assetsHash OpenMenu CloseMenu
        , pageTemplate model
        ]


rootNodeAttributes : Model -> List (Html.Attribute msg)
rootNodeAttributes model =
    let
        commonAttributes : List (Html.Attribute msg)
        commonAttributes =
            [ Html.Attributes.id "root-node" ]
    in
        if model.template.menuHidden then
            commonAttributes
        else
            Html.Attributes.class "no-scroll" :: commonAttributes


view : Model -> Html Msg
view model =
    Html.div (rootNodeAttributes model) <| viewContent model


port setTitle : Maybe String -> Cmd msg


port setMetaDescription : Maybe String -> Cmd msg


port scrollToTop : () -> Cmd msg


port scrollIntoView : String -> Cmd msg


port menuOpened : () -> Cmd msg


port menuClosed : () -> Cmd msg


port notifyCloseMenu : (() -> msg) -> Sub msg


port notifyYScroll : (Int -> msg) -> Sub msg


port notifyUrlUpdate : (String -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ notifyCloseMenu <| always CloseMenu
        , notifyYScroll YScroll
        , notifyUrlUpdate UpdateUrl
        ]


main : Program Flags Model Msg
main =
    Navigation.programWithFlags UrlChange
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
