module Example1Basic exposing
    ( Model
    , Msg(..)
    , initialModel
    , selectConfig
    , update
    , view
    )

import Html exposing (..)
import Html.Attributes exposing (class, style)
import Movie exposing (Movie)
import Select
import Shared


{-| In your main application model you should store:

  - The selected item e.g. selectedMovieId
  - The state for the select component e.g. selectState

-}
type alias Model =
    { id : String
    , movies : List Movie
    , selectedMovieId : Maybe String
    , selectState : Select.State
    }


{-| Your model should store the selected item and the state of the Select component(s)
-}
initialModel : String -> Model
initialModel id =
    { id = id
    , movies = Movie.movies
    , selectedMovieId = Nothing
    , selectState = Select.newState id
    }


{-| Your application messages need to include:

  - OnSelect item : This will be called when an item is selected
  - SelectMsg (Select.Msg item) : A message that wraps internal Select library messages. This is necessary to route messages back to the component.

-}
type Msg
    = NoOp
    | OnSelect (Maybe Movie)
    | SelectMsg (Select.Msg Movie)


{-| Create the configuration for the Select component

`Select.newConfig` takes two args:

  - The selection message e.g. `OnSelect`
  - A function that extract a label from an item e.g. `.label`

All the functions after |> are optional configuration.

-}
selectConfig : Select.Config Msg Movie
selectConfig =
    Select.newConfig
        { onSelect = OnSelect
        , toLabel = .label
        , filter = Shared.filter 4 .label
        , toMsg = SelectMsg
        }
        |> Select.withCutoff 12
        |> Select.withNotFound "No matches"
        |> Select.withPrompt "Select a movie"


{-| Your update function should route messages back to the Select component, see `SelectMsg`.
-}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        -- OnSelect is triggered when a selection is made on the Select component.
        OnSelect maybeMovie ->
            let
                maybeId =
                    Maybe.map .id maybeMovie
            in
            ( { model | selectedMovieId = maybeId }, Cmd.none )

        -- Route message to the Select component.
        -- The returned command is important.
        SelectMsg subMsg ->
            let
                ( updated, cmd ) =
                    Select.update selectConfig subMsg model.selectState
            in
            ( { model | selectState = updated }, cmd )

        NoOp ->
            ( model, Cmd.none )


{-| Your view renders the select component passing the config, state, list of items and the currently selected item.
-}
view : Model -> Html Msg
view model =
    let
        currentSelection =
            p
                []
                ([ text "Current selection: "
                 ]
                    ++ selectedMovieList
                )

        selectedMovieList : List (Html msg)
        selectedMovieList =
            List.map
                (\movie ->
                    span []
                        [ text movie.id
                        , text " "
                        , text movie.label
                        ]
                )
                selectedMovies

        selectedMovies : List Movie
        selectedMovies =
            case model.selectedMovieId of
                Nothing ->
                    []

                Just id ->
                    List.filter (\movie -> movie.id == id) Movie.movies

        -- Render the Select view. You must pass:
        -- - The configuration
        -- - The Select internal state (model.selectState)
        -- - A list of available items (model.moviews)
        -- - The currently selected items (selectedMovies)
        select =
            Select.view
                selectConfig
                model.selectState
                model.movies
                selectedMovies
    in
    div [ class "demo-box" ]
        [ h3 [] [ text "Basic example" ]
        , currentSelection
        , p
            []
            [ label [] [ text "Pick a movie" ]
            ]
        , p []
            [ select
            ]
        ]
