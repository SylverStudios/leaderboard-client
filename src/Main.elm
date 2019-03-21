module Main exposing (main)

import Browser
import Debug
import Json.Decode exposing (Decoder, Value)
import Json.Encode
import Model exposing (InitialValue, Model, Msg(..), Score, getLeaderboard, initFromValue, submitScore)
import Ports
import RemoteData
import View exposing (view)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NameUpdated str ->
            ( { model | name = str }, Cmd.none )

        Submit ->
            ( { model | submitData = RemoteData.Loading }
            , submitScore model.gameId model.name 4
            )

        SubmitCompleted ((RemoteData.Success { score }) as data) ->
            ( { model | submitData = data, incomingScore = Nothing, existingScore = Just score }, Cmd.none )

        SubmitCompleted result ->
            ( { model | submitData = result }, Cmd.none )

        RequestLeaderboard ->
            ( { model | leaderboardData = RemoteData.Loading }
            , getLeaderboard model.gameId
            )

        RequestLeaderboardCompleted result ->
            ( { model | leaderboardData = result }, Cmd.none )

        ScoreUpdated score ->
            ( { model | incomingScore = Just score }, Cmd.none )



---- PROGRAM ----


main : Program InitialValue Model Msg
main =
    Browser.element
        { view = view
        , init = initFromValue
        , update = update
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions _ =
    Ports.newScore ScoreUpdated
