module Page exposing (Page, parser, view, empty)

import Route exposing (Route)
import Html exposing (Html)
import Markdown
import Template


type alias Page msg =
    Html msg


type alias Model model msg =
    { model
        | route : Route
        , page : Page msg
        , menuHidden : Bool
    }


empty : Page msg
empty =
    Html.div [] []


parserOptions : Markdown.Options
parserOptions =
    { githubFlavored = Nothing
    , defaultHighlighting = Nothing
    , sanitize = False
    , smartypants = False
    }


parser : String -> Page msg
parser pageContent =
    Markdown.toHtmlWith parserOptions Template.pageAttributes pageContent


view : Model m msg -> List (Html msg)
view model =
    [ Html.section (Template.pageContainerAttributes model) [ model.page ] ]
