module Profile exposing (..)

import Html as H
import Html.Attributes as A
import Html.Events as E
import Http
import Maybe.Extra as Maybe
import Nav
import State.Main as RootState
import State.Profile exposing (Model)
import User


type Msg
  = GetMe (Result Http.Error User.User)
  | Save
  | Edit
  | NoOp


getMe : Cmd Msg
getMe =
  Http.get "/api/me" User.userDecoder
    |> Http.send GetMe

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    GetMe (Err _) ->
      { model | user = Nothing } ! []

    GetMe (Ok user) ->
      { model | user = Just user } ! []

    Save ->
      { model | editing = False } ! [] -- TODO

    Edit ->
      { model | editing = True } ! []

    NoOp ->
      model ! []


view : Model -> RootState.Model ->  H.Html Msg
view model rootState =
  H.div [ A.class "user-page" ] <|
    [ profileTopRow model rootState
    ] ++ (viewUserMaybe model)


profileTopRow : Model -> RootState.Model -> H.Html Msg
profileTopRow model rootState =
  let
    link =
      case model.user of
        Just _ ->
          H.a
            [ A.href "/logout"
            , A.class "btn"
            ]
            [ H.text "Kirjaudu ulos" ]
        Nothing ->
          H.a
            [ A.href <| Nav.ssoUrl rootState.rootUrl Nav.Profile
            , A.class "btn"
            ]
            [ H.text "Kirjaudu sisään" ]

    saveOrEdit =
      if Maybe.isJust model.user
      then
        H.button
          [ A.class "btn btn-primary profile__top-row-edit-button"
          , E.onClick <| if model.editing then Save else Edit
          ]
          [ H.text (if model.editing then "Tallenna profiili" else "Muokkaa profiilia") ]
      else
        H.div [] []
  in
    H.div
      [ A.classList
          [ ("row", True)
          , ("profile__top-row", True)
          , ("profile__top-row--editing", model.editing)
          ]
      ]
      [ H.div
        [ A.class "container" ]
        [ H.div
          [ A.class "row" ]
          [ H.div
            [ A.class "col-xs-4" ]
            [ H.h4
                [ A.class "profile__heading" ]
                [ H.text "Oma profiili" ] ]
          , H.div
            [ A.class "col-xs-8 profile__buttons" ]
            [ saveOrEdit
            , link
            ]
          ]
        ]
      ]

viewUserMaybe : Model -> List (H.Html Msg)
viewUserMaybe model =
  model.user
    |> Maybe.map viewUser
    |> Maybe.withDefault []


viewUser : User.User -> List (H.Html Msg)
viewUser user =
  [ H.div
    [ A.class "container" ]
    [ H.div
      [ A.class "row user-page__section" ]
      [ H.div
        [ A.class "col-md-6" ]
        [ H.div
          [ A.class "row" ]
          [ H.div
            [ A.class "col-xs-12"]
            [ H.div
              [ A.class "pull-left user-page__pic-container" ]
              [ H.span [ A.class "user-page__pic" ] [] ]
            , H.div
              [ A.class "pull-left" ]
              [ H.h4 [ A.class "user-page__name" ] [ H.text user.name ]
              , H.p
                [ A.class "user-page__work-details" ]
                [ H.text user.primaryDomain
                , H.br [] []
                , H.text user.primaryPosition
                ]
              ]
            ]
          ]
        , H.div
          [ A.class "row user-page__description" ]
          [ H.p [ A.class "col-xs-12" ] [ H.text user.description ]
          ]
        ]
      , H.div
        [ A.class "col-md-6 user-page__membership-info" ]
        [ H.h3 [ A.class "user-page__membership-info-heading" ] [ H.text "Jäsentiedot:" ]
        , H.span [] [ H.text "(eivät näy muille)"]
        , H.table
          [ A.class "user-page__membership-info-definitions" ]
          [ H.tr []
              [ H.td [] [ H.text "Kutsumanimi" ]
              , H.td [] [ H.text "Make"]
              ]
          , H.tr []
            [ H.td [] [ H.text "Etunimi" ]
            , H.td [] [ H.text "Matti" ]
            ]
          , H.tr []
            [ H.td [] [ H.text "Tehtäväluokat" ]
            , H.td [] [ H.text (String.join ", " user.positions)]
            ]
          , H.tr []
            [ H.td [] [ H.text "Toimiala" ]
            , H.td [] [ H.text "Teollisuus, mitäliä, kaikkee muuta" ]
            ]
          ]
        , H.p [] [ H.text "Ovathan jäentietosi ajan tasalla?" ]
        , H.p [] [ H.a
                     [ A.href "https://asiointi.tral.fi/" ]
                     [ H.text "Päivitä tiedot" ]
                 ]
        ]
      ]
    ]
  , H.hr [] []
  , H.div
    [ A.class "container" ]
    [ H.div
      [ A.class "row" ]
      [ H.div
          [ A.class "col-xs-12 col-sm-6"
          ]
          ([ H.h3 [ A.class "user-page__competences-header" ] [ H.text "Toimiala" ]
          ] ++ (List.map skill [ ("Teollisuus", Pro), ("IT", Interested) ]) )
      , H.div
          [ A.class "col-xs-12 col-sm-6"
          ]
          ([ H.h3 [ A.class "user-page__competences-header" ] [ H.text "Tehtäväluokka" ]
          ] ++ (List.map skill [ ("Kirjanpito", Experienced), ("Ohjelmointi", Beginner)]))
      ]
    ]
  ]


type SkillLevel = Interested | Beginner | There | Experienced | Pro

skill : (String, SkillLevel) -> H.Html msg
skill (heading, skillLevel) =
  let
    skillText =
      case skillLevel of
        Interested -> "Kiinnostunut"
        Beginner -> "Aloittelija"
        There -> "Alalla"
        Experienced -> "Kokenut"
        Pro -> "Konkari"

    skillNumber =
      case skillLevel of
        Interested -> 1
        Beginner -> 2
        There -> 3
        Experienced -> 4
        Pro -> 5

  in
    H.div
      []
      [ H.p
          []
          [ H.span [ A.class "skill__heading" ] [ H.text heading ]
          , H.span [ A.class "skill__level-text" ] [ H.text skillText ]
          ]
      , H.p [] [ H.text <| "Liukuri: " ++ toString skillNumber ]
      ]


viewProfileForm : User.User -> H.Html Msg
viewProfileForm user =
  H.form
    []
    [ H.div
        [ A.class "form-group"]
        [ H.label [] [ H.text "Millä nimellä meidän tulisi kutsua sinua?" ]
        , H.input
          [ A.value user.name
          , A.class "form-control"
          , E.onInput <| always NoOp
          ] []
        ]
    , H.div
      [ A.class "form-group" ]
      [ H.label [] [ H.text "Kuvaile itseäsi" ]
      , H.input
        [ A.value user.description
        , A.class "form-control"
        , E.onInput <| always NoOp
        ] []
      ]
    , H.div
      [ A.class "form-group" ]
      ([ H.label [] [ H.text "Tehtävät, joista sinulla on kokemusta" ]] ++
         viewPositions user.positions)
    ]

viewPositions : List String -> List (H.Html Msg)
viewPositions positions =
  List.map (\position -> H.input
              [ A.value position
              , A.class "form-control"
              , E.onInput <| always NoOp
              ] []) positions
