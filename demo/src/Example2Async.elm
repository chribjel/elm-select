module Example2Async exposing
    ( Character
    , Model
    , Msg(..)
    , collectionDecoder
    , fetch
    , fetchUrl
    , initialCmds
    , initialModel
    , itemHtml
    , memberDecoder
    , resultDecoder
    , selectConfig
    , update
    , view
    )

import Html exposing (..)
import Html.Attributes exposing (class, style)
import Http
import Json.Decode as Decode
import Select
import Shared


type alias Model =
    { id : String
    , characters : List Character
    , selectedCharacterId : Maybe String
    , selectState : Select.State
    }


type alias Character =
    String


initialModel : String -> Model
initialModel id =
    { id = id
    , characters = []
    , selectedCharacterId = Nothing
    , selectState = Select.newState id
    }


initialCmds : Cmd Msg
initialCmds =
    Cmd.none


type Msg
    = NoOp
    | OnSelect (Maybe Character)
    | SelectMsg (Select.Msg Character)
    | OnFetch (Result Http.Error (List Character))
    | OnQuery String


itemHtml : Character -> Html msg
itemHtml c =
    Html.div []
        [ Html.i [ class "fa fa-rebel" ] []
        , text (" " ++ c)
        ]


selectConfig : Select.Config Msg Character
selectConfig =
    Select.newConfig
        { onSelect = OnSelect
        , toLabel = identity
        , filter = Shared.filter 4 identity
        , toMsg = SelectMsg
        }
        |> Select.withInputWrapperAttrs
            [ style "padding" "0.4rem" ]
        |> Select.withMenuAttrs
            [ class "border border-gray-800 bg-white" ]
        |> Select.withItemAttrs
            [ class "p-1 border-b border-gray-800"
            , style "font-size" "1rem"
            ]
        |> Select.withNotFoundShown False
        |> Select.withHighlightedItemAttrs
            [ class "bg-gray", style "color" "black" ]
        |> Select.withPrompt "Select a character"
        |> Select.withCutoff 12
        |> Select.withOnQuery OnQuery
        |> Select.withItemHtml itemHtml
        |> Select.withUnderlineAttrs [ class "underline" ]
        |> Select.withTransformQuery
            (\query ->
                if String.length query < 3 then
                    ""

                else
                    query
            )


fetchUrl : String -> String
fetchUrl query =
    "https://swapi.co/api/people/?search=" ++ query


fetch : String -> Cmd Msg
fetch query =
    Http.get (fetchUrl query) resultDecoder
        |> Http.send OnFetch


resultDecoder : Decode.Decoder (List Character)
resultDecoder =
    Decode.at [ "results" ] collectionDecoder


collectionDecoder : Decode.Decoder (List Character)
collectionDecoder =
    Decode.list memberDecoder


memberDecoder : Decode.Decoder Character
memberDecoder =
    Decode.field "name" Decode.string


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnQuery query ->
            ( model, fetch query )

        OnFetch result ->
            case result of
                Ok characters ->
                    ( { model | characters = characters }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        OnSelect maybeCharacterId ->
            ( { model | selectedCharacterId = maybeCharacterId }, Cmd.none )

        SelectMsg subMsg ->
            let
                ( updated, cmd ) =
                    Select.update selectConfig subMsg model.selectState
            in
            ( { model | selectState = updated }, cmd )

        NoOp ->
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    let
        selectedCharacters =
            case model.selectedCharacterId of
                Nothing ->
                    []

                Just id ->
                    model.characters
                        |> List.filter (\character -> character == id)

        select =
            Select.view
                selectConfig
                model.selectState
                model.characters
                selectedCharacters
    in
    div [ class "demo-box" ]
        [ h3 [] [ text "Async example" ]
        , text (model.selectedCharacterId |> Maybe.withDefault "")
        , p 
            []
            [ label [] [ text "Pick an star wars character" ]
            ]
        , p []
            [ select
            ]
        ]
