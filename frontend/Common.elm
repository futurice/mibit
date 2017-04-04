module Common exposing (..)

import Html as H
import Html.Attributes as A
import Html.Events as E
import Json.Decode as Json
import Models.User exposing (User)
import Nav exposing (Route, routeToPath, routeToString)
import SvgIcons


authorInfo : User -> H.Html msg
authorInfo user =
  H.div
    []
    [ H.span [ A.class "author-info__pic" ] [ picElementForUser user ]
    , H.span
      [ A.class "author-info__info" ]
      [ H.span [ A.class "author-info__name"] [ H.text user.name ]
      , H.br [] []
      , H.span [ A.class "author-info__title"] [ H.text user.primaryPosition ]
      ]
    ]

picElementForUser : User -> H.Html msg
picElementForUser user =
  user.croppedPictureFileName
    |> Maybe.map (\url ->
                   H.img
                     [ A.src <| "/static/images/" ++ url
                     ]
                     []
                )
    |> Maybe.withDefault
      SvgIcons.userPicPlaceHolder

authorInfoWithLocation : User -> H.Html msg
authorInfoWithLocation user =
  H.div
    []
    [ H.span [ A.class "author-info__pic" ] [ picElementForUser user ]
    , H.span
      [ A.class "author-info__info" ]
      [ H.span [ A.class "author-info__name"] [ H.text user.name ]
      , H.br [] []
      , H.span [ A.class "author-info__title"] [ H.text user.primaryPosition ]
      , H.br [] []
      , showLocation user.location
      ]
    ]

link : Route -> (Route -> msg ) -> H.Html msg
link route toMsg =
  let
    action = linkAction route toMsg
  in
    H.a
      [ action
      , A.href (routeToPath route)
      ]
      [ H.text (routeToString route) ]


linkAction : Route -> (Route -> msg) -> H.Attribute msg
linkAction route toMsg =
  E.onWithOptions
    "click"
    { stopPropagation = False
    , preventDefault = True
    }
    (Json.succeed <| toMsg route)

showLocation : String -> H.Html msg
showLocation location =
  H.div [ A.class "profile__location" ]
    [ H.img [ A.class "profile__location--marker", A.src "/static/lokaatio.svg" ] []
    , H.span [ A.class "profile__location--text" ] [ H.text (location) ]
    ]

lengthHint : String -> String -> Int -> Int -> H.Html msg
lengthHint class text minLength maxLength =
  H.span
    [ A.class class ]
    [ H.text <|
      if String.length text < minLength
      then
        "Vielä vähintään " ++ toString (minLength - String.length text) ++ " merkkiä"
      else
        if String.length text <= maxLength
        then
          "Enää korkeintaan " ++ toString (maxLength - String.length text) ++ " merkkiä"
        else
          toString (String.length text - maxLength) ++ " merkkiä liian pitkä"
    ]
