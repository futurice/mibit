module Login exposing (..)

import Html as H
import Html.Attributes as A
import Html.Events exposing (onClick, onInput, onWithOptions)
import Http
import Json.Decode
import Json.Decode.Pipeline exposing (decode, required)
import Json.Encode
import Link
import Nav
import State.Login exposing (..)
import Translation exposing (T)
import Util exposing (UpdateMessage(..))


type Msg
    = Email String
    | Password String
    | SendResponse (Result Http.Error Response)
    | Submitted
    | PasswordForgotten


type alias Response =
    { status : String }


submit : Model -> Cmd Msg
submit model =
    let
        encoded =
            Json.Encode.object <|
                [ ( "email", Json.Encode.string model.email )
                , ( "password", Json.Encode.string model.password )
                ]
    in
    Http.post "/kirjaudu" (Http.jsonBody encoded) decodeResponse
        |> Http.send SendResponse


decodeResponse : Json.Decode.Decoder Response
decodeResponse =
    decode Response
        |> required "status" Json.Decode.string


update : Msg -> Model -> ( Model, Cmd (UpdateMessage Msg) )
update msg model =
    case msg of
        Email email ->
            { model | email = email } ! []

        Password password ->
            { model | password = password } ! []

        SendResponse (Err error) ->
            { model | status = Failure } ! []

        SendResponse (Ok response) ->
            model ! [ Util.refreshMe, Util.reroute Nav.Home ]

        Submitted ->
            model ! [ Cmd.map LocalUpdateMessage <| submit model ]

        PasswordForgotten ->
            model ! [ Util.reroute Nav.RenewPassword ]


loginForm : T -> Model -> Maybe String -> H.Html Msg
loginForm t model errorMessage =
    H.div
        [ A.class "container last-row" ]
        [ H.div
            [ A.class "row login col-sm-6 col-sm-offset-3" ]
            [ H.form
                [ A.class "login__container"
                , onWithOptions "submit"
                    { preventDefault = True, stopPropagation = False }
                    (Json.Decode.succeed Submitted)
                ]
                [ H.h1
                    [ A.class "login__heading" ]
                    [ H.text <| t "login.title" ]
                , H.p [] [ H.text <| t "login.hint" ]
                ]
            ]
        ]


view : T -> Model -> H.Html Msg
view t model =
    case model.status of
        NotLoaded ->
            loginForm t model Nothing

        Failure ->
            loginForm t model <|
                Just (t "login.failure")

        NetworkError ->
            loginForm t model <|
                Just (t "login.networkError")
