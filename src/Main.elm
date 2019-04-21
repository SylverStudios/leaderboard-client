port module Main exposing (main)

import Browser
import Debug
import Json.Decode exposing (Decoder, Value)
import Json.Encode
import Model exposing (InitialValue, Model, Msg(..), Score, Submission(..), getLeaderboard, initFromValue, submitScore)
import RemoteData
import View exposing (view)


port show : (Bool -> msg) -> Sub msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NameUpdated str ->
            ( { model | name = str }, Cmd.none )

        SubmitScore ->
            case model.submission of
                Unsaved score ->
                    ( { model | submission = Submit RemoteData.Loading }
                    , submitScore model.gameId model.name score
                    )

                Submit _ ->
                    ( model, Cmd.none )

        SubmitScoreCompleted data ->
            ( { model | submission = Submit data }, getLeaderboard model.gameId )

        RequestLeaderboard ->
            ( { model | leaderboardData = RemoteData.Loading }
            , getLeaderboard model.gameId
            )

        RequestLeaderboardCompleted result ->
            ( { model | leaderboardData = result }, Cmd.none )

        Show bool ->
            ( { model | show = bool }, Cmd.none )



---- PROGRAM ----


main : Program Value Model Msg
main =
    Browser.element
        { view = view
        , init = initFromValue
        , update = update
        , subscriptions = subs
        }


subs : Model -> Sub Msg
subs _ =
    show (\shouldShow -> Show shouldShow)
