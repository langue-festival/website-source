module Page exposing (Page, parser, view, empty)

{-| This module is responsible for the parsing and
converting markdown formatted strings in `Html msg`.


# Definition

Page contents, parsed markdown.

@docs Page


# Common Helpers

@docs parser view


# Page Constants

@docs empty

-}

import Route exposing (Route)
import Html exposing (Html)
import Markdown
import Template


type alias Page msg =
    Html msg


type alias Model model msg =
    { model
        | route : Route
        , yScroll : Int
        , page : Page msg
        , menuHidden : Bool
        , appVersion : String
    }


{-| An empty page.
-}
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


{-| Parses a markdown formatted string and creates a `Page`.
-}
parser : String -> Page msg
parser pageContent =
    Markdown.toHtmlWith parserOptions Template.pageAttributes pageContent


{-| Takes the page as the field of a `Model` and produces
a `List (Html msg)`.
-}
view : Model m msg -> List (Html msg)
view model =
    [ Html.section (Template.pageContainerAttributes model) [ model.page ] ]
