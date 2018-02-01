module Asset exposing (src)

import Html.Attributes
import Html


type alias Model model =
    { model | appVersion : String }


src : Model m -> String -> Html.Attribute msg
src { appVersion } url =
    Html.Attributes.src (url ++ "?" ++ appVersion)
