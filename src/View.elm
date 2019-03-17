module View exposing (view)

import Html exposing (..)
import Html.Events exposing (onClick, onInput)
import Http exposing (Body, Error(..))
import Model exposing (Model, Msg(..), Score)
import RemoteData exposing (RemoteData(..), WebData)


view : Model -> Html Msg
view model =
    div []
        [ div [] [ text model.name ]
        , input [ onInput NameUpdated ] []
        , div [] [ button [ onClick Submit ] [ text "Submit!" ], button [ onClick RequestLeaderboard ] [ text "Load Leaderboard" ] ]
        , submitResults model.submitData
        , leaderboard model.leaderboardData
        ]


leaderboard : WebData (List Score) -> Html msg
leaderboard data =
    case data of
        NotAsked ->
            text ""

        Loading ->
            text "Loading…"

        Failure err ->
            text ("Error: " ++ httpErrorString err)

        Success scores ->
            table [] (List.map leaderboardEntry scores)


leaderboardEntry : Score -> Html msg
leaderboardEntry { playerName, score } =
    tr []
        [ td [] [ text playerName ]
        , td [] [ text <| String.fromInt score ]
        ]


submitResults : WebData Score -> Html msg
submitResults data =
    case data of
        NotAsked ->
            text ""

        Loading ->
            text "Loading…"

        Failure err ->
            text ("Error: " ++ httpErrorString err)

        Success { gameName, playerName, score } ->
            div []
                [ text "OMG IT WORKED!"
                , text <| "Remember the name: " ++ playerName
                , text <| "because I just score a " ++ String.fromInt score ++ " in " ++ gameName
                ]


httpErrorString : Http.Error -> String
httpErrorString error =
    case error of
        BadUrl text ->
            "Bad Url: " ++ text

        Timeout ->
            "Http Timeout"

        NetworkError ->
            "Network Error"

        BadStatus code ->
            "Bad Http Status: " ++ String.fromInt code

        BadBody text ->
            "Bad body: " ++ text
