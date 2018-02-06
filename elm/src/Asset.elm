module Asset exposing (src)

{-| The purpose of this module is assets management
like url generation.


# Common Helpers

@docs src

-}

import Html.Attributes
import Html


type alias Model model =
    { model | assetsHash : String }


{-| Generates an url to an asset given a `Model` that
contains an `assetsHash` field and the asset's url.
Appends `assetsHash` to given url as a query string in order
to force the web server to send right version of asset.

    Html.img [ src model "assets/image.png" ]

-}
src : Model m -> String -> Html.Attribute msg
src { assetsHash } url =
    case assetsHash of
        "" ->
            Html.Attributes.src url

        hash ->
            Html.Attributes.src (url ++ "?" ++ hash)
