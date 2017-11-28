module Page.Parser exposing (parse)

import Html exposing (Html)
import Markdown


parserOptions : Markdown.Options
parserOptions =
    { githubFlavored = Nothing
    , defaultHighlighting = Nothing
    , sanitize = False
    , smartypants = False
    }


parse : String -> List (Html.Attribute msg) -> Html msg
parse page attributes =
    Markdown.toHtmlWith parserOptions attributes page
