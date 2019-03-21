module Model exposing (InitialValue, Model, Msg(..), Score, getLeaderboard, initFromValue, submitScore)

import Http
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode
import RemoteData exposing (WebData)


type Msg
    = Submit
    | SubmitCompleted (WebData Score)
    | RequestLeaderboard
    | RequestLeaderboardCompleted (WebData (List Score))
    | NameUpdated String
    | ScoreUpdated Int


type alias Model =
    { name : String
    , gameId : String
    , existingScore : Maybe Int
    , incomingScore : Maybe Int
    , submitData : WebData Score
    , leaderboardData : WebData (List Score)
    }


type alias Score =
    { gameName : String
    , playerName : String
    , score : Int
    }


type alias InitialValue =
    { gameId : String
    }


initFromValue : InitialValue -> ( Model, Cmd Msg )
initFromValue { gameId } =
    ( { gameId = gameId
      , name = ""
      , existingScore = Nothing
      , incomingScore = Nothing
      , submitData = RemoteData.NotAsked
      , leaderboardData = RemoteData.NotAsked
      }
    , Cmd.none
    )


submitScore : String -> String -> Int -> Cmd Msg
submitScore gameId playerName total =
    let
        mutation =
            """
      mutation NewScore($gameId: ID!, $name: String!, $total: Int!) {
        submit(game_id: $gameId, name: $name, total: $total) {
          game { name }
          player { name }
          total
        }
      }
      """

        variables =
            [ ( "gameId", Encode.string gameId )
            , ( "name", Encode.string playerName )
            , ( "total", Encode.int total )
            ]

        body =
            Http.jsonBody <|
                Encode.object
                    [ ( "query", Encode.string mutation )
                    , ( "operationName", Encode.string "NewScore" )
                    , ( "variables", Encode.object variables )
                    ]

        gameDecoder =
            Decode.map3 Score
                (Decode.at [ "submit", "game", "name" ] Decode.string)
                (Decode.at [ "submit", "player", "name" ] Decode.string)
                (Decode.at [ "submit", "total" ] Decode.int)

        decoder =
            Decode.oneOf
                [ Decode.at [ "data" ] gameDecoder
                , Decode.fail "expecting data"
                ]
    in
    Http.post
        { url = "http://localhost:4000/api"
        , body = body
        , expect = Http.expectJson (RemoteData.fromResult >> SubmitCompleted) decoder
        }


getLeaderboard : String -> Cmd Msg
getLeaderboard gameId =
    let
        query =
            """
      query HighScores($gameId: ID!) {
        game(id: $gameId) {
          name
          scores(limit: 10) {
            player { name }
            total
          }
        }
      }
      """

        variables =
            [ ( "gameId", Encode.string gameId ) ]

        body =
            Http.jsonBody <|
                Encode.object
                    [ ( "query", Encode.string query )
                    , ( "operationName", Encode.string "HighScores" )
                    , ( "variables", Encode.object variables )
                    ]

        gameListDecoder =
            Decode.andThen
                (\gameName ->
                    Decode.at [ "game", "scores" ] <|
                        Decode.list
                            (Decode.map2 (Score gameName)
                                (Decode.at [ "player", "name" ] Decode.string)
                                (Decode.field "total" Decode.int)
                            )
                )
                (Decode.at [ "game", "name" ] Decode.string)

        decoder =
            Decode.oneOf
                [ Decode.at [ "data" ] gameListDecoder
                , Decode.fail "expecting data"
                ]
    in
    Http.post
        { url = "http://localhost:4000/api"
        , body = body
        , expect = Http.expectJson (RemoteData.fromResult >> RequestLeaderboardCompleted) decoder
        }
