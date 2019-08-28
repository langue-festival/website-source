module Asset exposing (src)

{-| The purpose of this module is assets management
like url generation.


# Common Helpers

@docs src

-}

import Html
import Html.Attributes


{-| Generates an url to an asset given an `assetsHash` and the asset's url.
Appends `assetsHash` to given url as a query string in order
to force the web server to send right version of asset.

    Html.img [ src assetsHash "assets/image.png" ]

-}
src : String -> String -> Html.Attribute msg
src assetsHash url =
    case assetsHash of
        "" ->
            Html.Attributes.src url

        hash ->
            Html.Attributes.src (url ++ "?" ++ hash)
