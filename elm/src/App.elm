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
    | TransitionEnd
    | OpenMenu
    | CloseMenu


type alias Model =
    { currentRoute : Route
    , currentPage : Page Msg
    , lastRoute : Route
    , lastPage : Page Msg
    , animateTransition : Bool
    , inTransition : Bool
    , menuHidden : Bool
    , pageCache : Cache Msg
    }


type alias Flags =
    { pages : List ( Route, String )
    , firstAnimation : Bool
    }


init : Flags -> Navigation.Location -> ( Model, Cmd Msg )
init flags location =
    let
        model : Model
        model =
            { currentRoute = Route.parseLocation location
            , currentPage = []
            , lastRoute = Route.parseLocation location
            , lastPage = []
            , animateTransition = flags.firstAnimation
            , inTransition = False
            , menuHidden = True
            , pageCache = Loader.loadCache flags.pages
            }
    in
        handleUrlChange location model


updatePage : Route -> Page Msg -> Model -> Model
updatePage route page model =
    { model
        | currentRoute = route
        , currentPage = page
        , lastRoute = model.currentRoute
        , lastPage = model.currentPage
    }


loaderEventToAppMsg : Loader.Event Msg -> Msg
loaderEventToAppMsg loaderMsg =
    case loaderMsg of
        Loader.Success route page cache ->
            PageLoad route page cache

        Loader.Error route error ->
            LoadError route error


handleUrlChange : Navigation.Location -> Model -> ( Model, Cmd Msg )
handleUrlChange location model =
    if model.inTransition then
        model ! [ Route.toUrl model.currentRoute |> Navigation.load ]
    else
        ( model, Loader.load location model.pageCache loaderEventToAppMsg )


handlePageLoad : Route -> Page Msg -> Model -> ( Model, Cmd Msg )
handlePageLoad route page model =
    if model.inTransition then
        -- let the transition end
        model ! []
    else if model.animateTransition then
        let
            transitionEndListener : Cmd Msg
            transitionEndListener =
                waitForTransitionEnd route

            ( newModel, closeMenuCmd ) =
                { model | inTransition = True }
                    |> updatePage route page
                    |> update CloseMenu
        in
            newModel ! [ transitionEndListener, closeMenuCmd ]
    else
        -- first load, do animation from now on
        updatePage route page { model | animateTransition = True } ! []


set404 : Route -> Model -> ( Model, Cmd Msg )
set404 route model =
    let
        content =
            "#404\nNon è stato possibile trovare la pagina richiesta"

        newModel =
            { model
                | currentRoute = route
                , currentPage = Page.parser route content
            }
    in
        newModel ! []


setViewError : Route -> String -> Model -> ( Model, Cmd Msg )
setViewError route error model =
    let
        content =
            "#Si è verificato un errore\n\n" ++ error

        newModel =
            { model
                | currentRoute = route
                , currentPage = Page.parser route content
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

        TransitionEnd ->
            { model | inTransition = False } ! []

        OpenMenu ->
            { model | menuHidden = False } ! [ startCloseMenuListener () ]

        CloseMenu ->
            { model | menuHidden = True } ! [ stopCloseMenuListener () ]



{- content container attributes -}


containerClasses : List (Html.Attribute Msg)
containerClasses =
    [ Html.Attributes.class "content-container pure-g" ]


enterTransitionAttributes : List (Html.Attribute Msg)
enterTransitionAttributes =
    Html.Attributes.class "enter-transition" :: containerClasses


exitTransitionAttributes : List (Html.Attribute Msg)
exitTransitionAttributes =
    Html.Attributes.class "exit-transition" :: containerClasses



{- end content container attributes -}


renderPage : Model -> Page Msg
renderPage model =
    if model.inTransition then
        [ Html.div exitTransitionAttributes
            model.lastPage
        , Html.div enterTransitionAttributes
            model.currentPage
        ]
    else
        [ Html.div containerClasses
            model.currentPage
        ]


view : Model -> Html Msg
view model =
    Html.div [ Html.Attributes.id "root-node" ]
        (Template.menu model
            :: Template.menuToggleButton model OpenMenu CloseMenu
            :: renderPage model
        )


port waitForTransitionEnd : String -> Cmd msg


port notifyTransitionEnd : (() -> msg) -> Sub msg


port startCloseMenuListener : () -> Cmd msg


port stopCloseMenuListener : () -> Cmd msg


port notifyCloseMenu : (() -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ notifyTransitionEnd (always TransitionEnd)
        , notifyCloseMenu (always CloseMenu)
        ]


main : Program Flags Model Msg
main =
    Navigation.programWithFlags UrlChange
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
