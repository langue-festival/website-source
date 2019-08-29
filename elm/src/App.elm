port module App exposing (main)

import Browser exposing (UrlRequest(..))
import Browser.Navigation as Navigation
import Html exposing (Html)
import Html.Attributes
import Http
import Page exposing (Page)
import Page.Loader as Loader exposing (Cache)
import Template
import Url exposing (Url)


type Msg
    = UrlChange Url
    | LinkClick UrlRequest
    | LoadError Url Http.Error
    | PageLoad Url (Page Msg) (Cache Msg)
    | YScroll Int
    | OpenMenu
    | CloseMenu


type alias Model =
    { url : Url
    , key : Navigation.Key
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


init : Flags -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init flags url navigationKey =
    let
        template : Template.Model
        template =
            { yScroll = flags.yScroll
            , menuHidden = True
            }

        model : Model
        model =
            { url = url
            , key = navigationKey
            , page = Page.empty
            , template = template
            , assetsHash = flags.assetsHash
            , underConstruction = flags.underConstruction
            , pageCache = Loader.loadCache flags.pages
            }
    in
    handleUrlChange url model


handleUrlChange : Url -> Model -> ( Model, Cmd Msg )
handleUrlChange newUrl ({ pageCache } as model) =
    let
        loaderEventToAppMsg : Loader.Event Msg -> Msg
        loaderEventToAppMsg loaderMsg =
            case loaderMsg of
                Loader.Success url page cache ->
                    PageLoad url page cache

                Loader.Error url error ->
                    LoadError url error

        normalizedUrl : Url
        normalizedUrl =
            if Page.nameFromUrl newUrl == "" then
                { newUrl | path = "/index" }

            else
                newUrl

        loadCmd : Cmd Msg
        loadCmd =
            Loader.load normalizedUrl pageCache loaderEventToAppMsg
    in
    ( model, loadCmd )


handlePageLoad : Url -> Page Msg -> Model -> ( Model, Cmd Msg )
handlePageLoad url page model =
    let
        ( newModel, closeMenuCmd ) =
            { model | url = url, page = page }
                |> update CloseMenu

        commonCmds : List (Cmd Msg)
        commonCmds =
            [ closeMenuCmd
            , setMetaDescription page.description
            ]
    in
    case url.fragment of
        Just fragment ->
            ( newModel, Cmd.batch <| scrollIntoView fragment :: commonCmds )

        Nothing ->
            ( newModel, Cmd.batch <| scrollToTop () :: commonCmds )


handleYScroll : Int -> Model -> ( Model, Cmd Msg )
handleYScroll yScroll ({ template } as model) =
    let
        newTemplate : Template.Model
        newTemplate =
            { template | yScroll = yScroll }
    in
    ( { model | template = newTemplate }, Cmd.none )


handleOpenMenu : Model -> ( Model, Cmd Msg )
handleOpenMenu ({ template } as model) =
    let
        newTemplate : Template.Model
        newTemplate =
            { template | menuHidden = False }

        newModel : Model
        newModel =
            { model | template = newTemplate }
    in
    ( newModel, Cmd.batch [ menuOpened (), scrollToTop () ] )


handleCloseMenu : Model -> ( Model, Cmd Msg )
handleCloseMenu ({ template } as model) =
    let
        newTemplate : Template.Model
        newTemplate =
            { template | menuHidden = True }

        newModel : Model
        newModel =
            { model | template = newTemplate }
    in
    ( newModel, menuClosed () )


set404 : Url -> Model -> ( Model, Cmd Msg )
set404 url model =
    let
        content : String
        content =
            "#404\nNon è stato possibile trovare la pagina richiesta"

        newModel : Model
        newModel =
            { model
                | url = url
                , page = Page.parser content
            }
    in
    ( newModel, Cmd.none )


setViewError : Url -> String -> Model -> ( Model, Cmd Msg )
setViewError url error model =
    let
        content : String
        content =
            "#Si è verificato un errore\n\n" ++ error

        newModel : Model
        newModel =
            { model
                | url = url
                , page = Page.parser content
            }
    in
    ( newModel, Cmd.none )


handleLoadError : Url -> Http.Error -> Model -> ( Model, Cmd Msg )
handleLoadError url error model =
    case error of
        Http.BadUrl badUrl ->
            setViewError url ("Invalid URL: " ++ badUrl) model

        Http.Timeout ->
            setViewError url "Timeout" model

        Http.NetworkError ->
            setViewError url "NetworkError error" model

        Http.BadStatus response ->
            if response == 404 then
                set404 url model

            else
                setViewError url ("Status: " ++ String.fromInt response) model

        Http.BadBody body ->
            setViewError url ("Invalid body: " ++ body) model


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChange newUrl ->
            handleUrlChange newUrl model

        -- TODO: handle "download" links
        LinkClick (Internal url) ->
            ( model, Navigation.pushUrl model.key <| Url.toString url )

        LinkClick (External href) ->
            ( model, Navigation.load href )

        LoadError url error ->
            handleLoadError url error model

        PageLoad url page cache ->
            handlePageLoad url page { model | pageCache = cache }

        YScroll offset ->
            handleYScroll offset model

        OpenMenu ->
            handleOpenMenu model

        CloseMenu ->
            handleCloseMenu model


pageTemplate : Model -> Html Msg
pageTemplate model =
    Html.section (Template.pageContainerAttributes model.template model.url)
        [ Html.div Template.pageAttributes
            [ model.page.content ]
        ]


viewContent : Model -> List (Html Msg)
viewContent model =
    if model.underConstruction then
        let
            url : Url
            url =
                model.url

            newModel : Model
            newModel =
                { model
                    | url = { url | path = "under-construction" }
                    , page = Page.parser "# Sito in costruzione"
                }
        in
        [ pageTemplate newModel ]

    else if model.url.path == "/index" then
        [ model.page.content ]

    else
        [ Template.header model.template model.url model.assetsHash OpenMenu CloseMenu
        , pageTemplate model
        ]


pageTitle : Model -> String
pageTitle { page } =
    case page.title of
        Just title ->
            "Langue Festival | " ++ title

        Nothing ->
            "Langue Festival"


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


view : Model -> Browser.Document Msg
view model =
    { title = pageTitle model
    , body =
        [ Html.div (rootNodeAttributes model) (viewContent model) ]
    }


port setMetaDescription : Maybe String -> Cmd msg


port scrollToTop : () -> Cmd msg


port scrollIntoView : String -> Cmd msg


port menuOpened : () -> Cmd msg


port menuClosed : () -> Cmd msg


port notifyCloseMenu : (() -> msg) -> Sub msg


port notifyYScroll : (Int -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ notifyCloseMenu <| always CloseMenu
        , notifyYScroll YScroll
        ]


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , onUrlChange = UrlChange
        , onUrlRequest = LinkClick
        , subscriptions = subscriptions
        , update = update
        , view = view
        }
