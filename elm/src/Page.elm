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

import Regex exposing (Regex, regex, replace)
import Route exposing (Route)
import Html exposing (Html)
import Markdown
import Template


type alias Page msg =
    Html msg


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


markdownAssetRegex : Regex
markdownAssetRegex =
    regex "\\(assets/[^ )]+"


{-| Parses a markdown formatted string and creates a `Page`
and appends `assetsHash` to the assets as query string.
-}
parser : String -> String -> Page msg
parser assetsHash pageContent =
    let
        assetUrlReplace : Regex.Match -> String
        assetUrlReplace { match } =
            match ++ "?" ++ assetsHash

        page : String
        page =
            replace Regex.All markdownAssetRegex assetUrlReplace pageContent
    in
        Markdown.toHtmlWith parserOptions Template.pageAttributes page


{-| Takes the current route, the page to render, template's model
and creates a `List (Html msg)` to the current page.
-}
view : Route -> Page msg -> Template.Model -> List (Html msg)
view currentRoute page model =
    [ Html.section (Template.pageContainerAttributes model currentRoute) [ page ] ]
