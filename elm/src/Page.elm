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

import Regex exposing (Regex, regex, split, find, replace)
import Html exposing (Html)
import Markdown


type alias Page msg =
    { title : Maybe String
    , description : Maybe String
    , content : Html msg
    }


{-| An empty page.
-}
empty : Page msg
empty =
    { title = Nothing
    , description = Nothing
    , content = Html.div [] []
    }


parserOptions : Markdown.Options
parserOptions =
    { githubFlavored = Nothing
    , defaultHighlighting = Nothing
    , sanitize = False
    , smartypants = False
    }


descriptionRegex : Regex
descriptionRegex =
    regex "description: ?([^\\n]+)\\n"


titleRegex : Regex
titleRegex =
    regex "<h1[^>]*>([^<]+)</h1>"


assetRegex : Regex
assetRegex =
    let
        markdownAssetPattern : String
        markdownAssetPattern =
            """\\[[^\\]]*\\]\\(.*assets\\/[^ )]+"""

        htmlAssetPattern : String
        htmlAssetPattern =
            """<img.*src="assets\\/[^"]+"""

        assetPattern : String
        assetPattern =
            "(" ++ markdownAssetPattern ++ ")|(" ++ htmlAssetPattern ++ ")"
    in
        regex assetPattern


{-| Parses a markdown formatted string and creates a `Page`
and appends `assetsHash` to the assets as query string.
-}
parser : String -> String -> Page msg
parser assetsHash fullContent =
    let
        descriptionSplitResult : List String
        descriptionSplitResult =
            split Regex.All descriptionRegex fullContent
                |> List.filter ((/=) "")

        ( description, markdownContent ) =
            case descriptionSplitResult of
                desc :: p1 :: p2 ->
                    ( Just desc, String.join "" (p1 :: p2) )

                _ ->
                    ( Nothing, fullContent )

        title : Maybe String
        title =
            find (Regex.AtMost 1) titleRegex markdownContent
                |> List.head
                |> Maybe.map .submatches
                |> Maybe.withDefault []
                |> List.head
                |> Maybe.withDefault Nothing

        assetUrlReplace : Regex.Match -> String
        assetUrlReplace result =
            result.match ++ "?" ++ assetsHash

        pageContent : Html msg
        pageContent =
            replace Regex.All assetRegex assetUrlReplace markdownContent
                |> Markdown.toHtmlWith parserOptions []
    in
        { title = title
        , description = description
        , content = pageContent
        }
