port module App exposing (main)

import Model exposing (Model, updatePage, updatePageCache)
import Route exposing (Route)
import Dict exposing (Dict)
import Html exposing (Html)
import Msg exposing (Msg)
import Html.Attributes
import Page.Loader
import Page.Parser
import Navigation
import Template
import Http


type alias Flags =
    { pages : List ( Route, String )
    }


init : Flags -> Navigation.Location -> ( Model, Cmd Msg )
init flags location =
    let
        pareRouteContent : ( Route, String ) -> ( Route, List (Html Msg) )
        pareRouteContent ( route, content ) =
            ( route, parsePage route content )

        pageCache : Dict Route (List (Html Msg))
        pageCache =
            List.map pareRouteContent flags.pages
                |> Dict.fromList

        model : Model
        model =
            { currentRoute = Route.parseLocation location
            , currentPage = []
            , lastRoute = Route.parseLocation location
            , lastPage = []
            , animateTransition = False
            , inTransition = False
            , menuHidden = True
            , pageCache = pageCache
            }
    in
        handleUrlChange location model


handleUrlChange : Navigation.Location -> Model -> ( Model, Cmd Msg )
handleUrlChange location model =
    if model.inTransition then
        model ! [ Route.toUrl model.currentRoute |> Navigation.load ]
    else
        ( model, Page.Loader.load location model )


parsePage : Route -> String -> List (Html msg)
parsePage route pageContent =
    [ Html.div
        [ Html.Attributes.class "pure-u-1-12 pure-u-md-1-24" ]
        []
    , Page.Parser.parse
        pageContent
        [ Html.Attributes.id route
        , Html.Attributes.class "markdown pure-u-7-8 pure-u-md-2-3"
        ]
    ]


handleContentLoad : Route -> String -> Model -> ( Model, Cmd Msg )
handleContentLoad route pageContent model =
    let
        page : List (Html Msg)
        page =
            parsePage route pageContent

        newModel : Model
        newModel =
            updatePageCache route page model
    in
        handlePageLoad route page newModel


handlePageLoad : Route -> List (Html Msg) -> Model -> ( Model, Cmd Msg )
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
                    |> update Msg.CloseMenu
        in
            newModel ! [ transitionEndListener, closeMenuCmd ]
    else
        -- first load
        updatePage route page { model | animateTransition = True } ! []


set404 : Route -> Model -> ( Model, Cmd Msg )
set404 route model =
    handleContentLoad route "#404\nNon è stato possibile trovare la pagina richiesta" model


setViewError : Route -> String -> Model -> ( Model, Cmd Msg )
setViewError route error model =
    --TODO do not cache errors!
    handleContentLoad route ("#Si è verificato un errore\n\n" ++ error) model


handleContentLoadError : Route -> Http.Error -> Model -> ( Model, Cmd Msg )
handleContentLoadError route error model =
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

        Http.BadPayload payload response ->
            setViewError route ("Status: " ++ toString response.status) model


handleTransitionEnd : Model -> ( Model, Cmd Msg )
handleTransitionEnd model =
    { model | inTransition = False } ! []


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    -- TODO anchor handling
    case msg of
        Msg.UrlChange location ->
            handleUrlChange location model

        Msg.ContentLoad ( route, pageContent ) ->
            handleContentLoad route pageContent model

        Msg.ContentLoadError ( route, error ) ->
            handleContentLoadError route error model

        Msg.PageLoad ( route, page ) ->
            handlePageLoad route page model

        Msg.TransitionEnd ->
            handleTransitionEnd model

        Msg.OpenMenu ->
            { model | menuHidden = False } ! [ startCloseMenuListener () ]

        Msg.CloseMenu ->
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


renderPage : Model -> List (Html Msg)
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
            :: Template.menuToggleButton model
            :: renderPage model
        )


port waitForTransitionEnd : String -> Cmd msg


port notifyTransitionEnd : (() -> msg) -> Sub msg


port startCloseMenuListener : () -> Cmd msg


port stopCloseMenuListener : () -> Cmd msg


port notifyCloseMenu : (() -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ notifyTransitionEnd (always Msg.TransitionEnd)
        , notifyCloseMenu (always Msg.CloseMenu)
        ]


main : Program Flags Model Msg
main =
    Navigation.programWithFlags Msg.UrlChange
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
