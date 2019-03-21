module Model exposing (InitialValue, Model, Msg(..), Score, Submission(..), getLeaderboard, initFromValue, submitScore)

import Http
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode
import RemoteData exposing (WebData)


type Msg
    = SubmitScore
    | SubmitScoreCompleted (WebData Score)
    | RequestLeaderboard
    | RequestLeaderboardCompleted (WebData (List Score))
    | NameUpdated String


type alias Model =
    { name : String
    , gameId : String
    , submission : Submission
    , leaderboardData : WebData (List Score)
    }


type Submission
    = Unsaved Int
    | Submit (WebData Score)


type alias Score =
    { gameName : String
    , playerName : String
    , score : Int
    }


type alias InitialValue =
    { gameId : String
    , score : Int
    }


initFromValue : Value -> ( Model, Cmd Msg )
initFromValue value =
    let
        { gameId, score } =
            initialize value
    in
    ( { gameId = gameId
      , name = ""
      , submission = Unsaved score
      , leaderboardData = RemoteData.NotAsked
      }
    , getLeaderboard gameId
    )


initialize : Decode.Value -> InitialValue
initialize value =
    let
        decoder : Decoder InitialValue
        decoder =
            Decode.map2 InitialValue
                (Decode.field "gameId" Decode.string)
                (Decode.field "score" Decode.int)
    in
    value
        |> Decode.decodeValue decoder
        |> Result.withDefault
            { gameId = ""
            , score = 0
            }


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
        , expect = Http.expectJson (RemoteData.fromResult >> SubmitScoreCompleted) decoder
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
