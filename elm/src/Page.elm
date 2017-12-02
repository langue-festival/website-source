module Page exposing (Page, parser)

import Route exposing (Route)
import Html exposing (Html)
import Html.Attributes
import Markdown


type alias Page msg =
    List (Html msg)


parserOptions : Markdown.Options
parserOptions =
    { githubFlavored = Nothing
    , defaultHighlighting = Nothing
    , sanitize = False
    , smartypants = False
    }


parser : Route -> String -> Page msg
parser route pageContent =
    [ Html.div
        [ Html.Attributes.class "pure-u-md-1-24" ]
        []
    , Markdown.toHtmlWith
        parserOptions
        [ Html.Attributes.id route
        , Html.Attributes.class "markdown pure-u-1 pure-u-md-2-3"
        ]
        pageContent
    ]
