module View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http exposing (Body, Error(..))
import Model exposing (Model, Msg(..), Score)
import RemoteData exposing (RemoteData(..), WebData)


view : Model -> Html Msg
view model =
    div [ class "main" ]
        [ div [ class "left-side" ] <| pickSubmissionView model
        , div
            [ class "right-side" ]
            [ leaderboardView model.leaderboardData ]
        ]


pickSubmissionView : Model -> List (Html Msg)
pickSubmissionView { existingScore, incomingScore, name } =
    case ( existingScore, incomingScore ) of
        ( Just oldScore, Just newScore ) ->
            overwriteHighScore oldScore newScore name

        ( Nothing, Just score ) ->
            unsavedScore score name

        ( Just score, Nothing ) ->
            firstScoreView score name

        ( Nothing, Nothing ) ->
            [ text "" ]


unsavedScore : Int -> String -> List (Html Msg)
unsavedScore score name =
    [ div [ class "new-score" ] [ text <| String.fromInt score ]
    , div [] [ text "score" ]
    , usernameInput name
    , button [ onClick Submit ] [ text "Submit!" ]
    ]


firstScoreView : Int -> String -> List (Html Msg)
firstScoreView score name =
    [ div [ class "new-score" ] [ text <| String.fromInt score ]
    , div [] [ text "score" ]
    , usernameInput name
    , button [ onClick Submit ] [ text "Submit" ]
    ]


overwriteHighScore : Int -> Int -> String -> List (Html Msg)
overwriteHighScore existingScore incomingScore name =
    [ div [ class "username" ] [ text name ]
    , div [ class "new-score" ] [ text <| String.fromInt incomingScore ]
    , button [ onClick Submit ] [ text "Submit" ]
    , div [ class "old-high-score" ] [ text "Current High Score: ", text <| String.fromInt existingScore ]
    ]


usernameInput : String -> Html Msg
usernameInput username =
    input
        [ id "name-input"
        , onInput NameUpdated
        , type_ "text"
        , placeholder "username"
        , value username
        ]
        []


leaderboardView : WebData (List Score) -> Html Msg
leaderboardView data =
    case data of
        NotAsked ->
            div [ class "solo-refresh" ] [ refreshButton ]

        Loading ->
            leaderboardTable "Loading…" []

        Failure err ->
            div [ class "error" ] [ text <| "Error: " ++ httpErrorString err ]

        Success scores ->
            leaderboardTable "Leaderboard" scores


refreshButton : Html Msg
refreshButton =
    button [ class "refresh", onClick RequestLeaderboard ] [ text "♻" ]


leaderboardTable : String -> List Score -> Html Msg
leaderboardTable title scores =
    section []
        [ div [ class "leaderboard-title" ] [ text title, refreshButton ]
        , table [ class "table" ]
            (thead []
                [ tr []
                    [ th [] [ text "Rank" ]
                    , th [] [ text "Name" ]
                    , th [] [ text "Score" ]
                    ]
                ]
                :: List.indexedMap leaderboardRow scores
            )
        ]


leaderboardRow : Int -> Score -> Html msg
leaderboardRow rank { playerName, score } =
    tr []
        [ td [] [ text <| String.fromInt <| rank + 1 ]
        , td [] [ text playerName ]
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
