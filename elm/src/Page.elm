module Page exposing
    ( Page
    , empty
    , nameFromUrl, parser
    )

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

import Html exposing (Html)
import Markdown
import Url exposing (Url)


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


foldUrlSegment : String -> Maybe String -> Maybe String
foldUrlSegment segment acc =
    case segment of
        "" ->
            acc

        _ ->
            Just segment


{-| Get the page name from a URL.
-}
nameFromUrl : Url -> String
nameFromUrl { path } =
    String.split "/" path
        |> List.foldl foldUrlSegment Nothing
        |> Maybe.withDefault ""


splitBodyFrontMatter : String -> ( List String, String )
splitBodyFrontMatter fullText =
    case String.indexes "---" fullText of
        0 :: end :: _ ->
            let
                preambleList : List String
                preambleList =
                    String.slice 3 end fullText
                        |> String.lines
                        |> List.map String.trim
                        |> List.filter ((/=) "")

                body : String
                body =
                    String.dropLeft (end + 3) fullText
            in
            ( preambleList, body )

        _ ->
            ( [], fullText )


readFromRule : String -> String -> Maybe String
readFromRule rule key =
    if String.startsWith key rule then
        String.dropLeft (String.length key + 1) rule
            |> String.trim
            |> Just

    else
        Nothing


parseTitle : String -> Page msg -> Page msg
parseTitle rule page =
    case readFromRule rule "title" of
        Just title ->
            { page | title = Just title }

        Nothing ->
            page


parseDescription : String -> Page msg -> Page msg
parseDescription rule page =
    case readFromRule rule "description" of
        Just desc ->
            { page | description = Just desc }

        Nothing ->
            page


parseFrontMatter : List String -> Page msg
parseFrontMatter rules =
    List.foldl
        (\rule -> parseTitle rule >> parseDescription rule)
        empty
        rules


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
parser fullText =
    let
        ( rules, body ) =
            splitBodyFrontMatter fullText

        page : Page msg
        page =
            parseFrontMatter rules

        pageContent : Html msg
        pageContent =
            Markdown.toHtmlWith parserOptions [] body
    in
    { page | content = pageContent }
