module View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Http exposing (Body, Error(..))
import Model exposing (Model, Msg(..), Score, Submission(..))
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
pickSubmissionView { submission, name } =
    case submission of
        Unsaved num ->
            unsavedScore num name

        Submit Loading ->
            loading

        Submit (Success { score }) ->
            firstScoreView score name

        Submit (Failure err) ->
            [ text ("Error: " ++ httpErrorString err) ]

        Submit NotAsked ->
            [ text "This really shouldn't happen" ]


unsavedScore : Int -> String -> List (Html Msg)
unsavedScore score name =
    [ bigNumber score
    , Html.form [ class "flex-column", onSubmit SubmitScore ]
        [ usernameInput name
        , submitButton name
        ]
    ]


firstScoreView : Int -> String -> List (Html Msg)
firstScoreView score name =
    [ bigNumber score
    , usernameSuccess name
    ]


bigNumber : Int -> Html Msg
bigNumber number =
    div [ class "flex-column" ]
        [ span [ class "big-score" ] [ text <| String.fromInt number ]
        , div [ class "small-text" ] [ text "Score" ]
        ]


submitButton : String -> Html Msg
submitButton username =
    case username of
        "" ->
            button [ onClick SubmitScore, disabled True, class "disabled" ] [ text "Enter a Username" ]

        _ ->
            button [ onClick SubmitScore ] [ text "Submit!" ]


loading : List (Html Msg)
loading =
    [ text "doing an `npm install`, 1 moment plz…" ]


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


usernameSuccess : String -> Html Msg
usernameSuccess username =
    div [ class "username" ] [ text username ]


leaderboardView : WebData (List Score) -> Html Msg
leaderboardView data =
    case data of
        NotAsked ->
            div [ class "solo-refresh" ]
                [ button [ class "refresh", onClick RequestLeaderboard ] [ text "♻" ] ]

        Loading ->
            leaderboardTable "Loading…" []

        Failure err ->
            div [ class "error" ] [ text <| "Error: " ++ httpErrorString err ]

        Success scores ->
            leaderboardTable "Leaderboard" scores


leaderboardTable : String -> List Score -> Html Msg
leaderboardTable title scores =
    section []
        [ table [ class "table" ]
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
