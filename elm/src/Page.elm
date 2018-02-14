module Page exposing (Page, parser, empty)

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
import Html exposing (Html)
import Markdown


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
    -- TODO select urls in src="...
    -- TODO test \(.*assets/[^ )]+
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
        Markdown.toHtmlWith parserOptions [] page
