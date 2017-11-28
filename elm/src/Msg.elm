module Msg exposing (Msg(..))

import Html exposing (Html)
import Navigation
import Http


type Msg
    = UrlChange Navigation.Location
    | ContentLoad ( String, String )
    | ContentLoadError ( String, Http.Error )
    | PageLoad ( String, List (Html Msg) )
    | TransitionEnd
    | OpenMenu
    | CloseMenu
