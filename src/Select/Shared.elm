module Select.Shared exposing
    ( classNames
    , difference
    , inputAttributes
    ,  onClickWithoutPropagation
       -- , onKeyPressAttribute
       -- , onKeyUpAttribute

    , referenceAttr
    , referenceDataName
    , splitWithSeparators
    , uniqueBy
    )

-- import Html exposing (Attribute)

import Accessibility.Styled as Html exposing (Attribute, Html)
import Array
import Html.Styled.Attributes exposing (attribute, autocomplete, class)
import Html.Styled.Events exposing (keyCode, on, onFocus, onInput, preventDefaultOn, stopPropagationOn)
import Json.Decode as Decode
import Regex
import Select.Config exposing (Config)
import Select.Messages as Msg exposing (Msg)
import Select.Models exposing (State)
import Set exposing (Set)


classNames =
    { root = "elm-select"
    , inputWrapper = "elm-select-input-wrapper"
    , input = "elm-select-input"
    , clear = "elm-select-clear"
    , underline = "elm-select-input-underline"
    , underlineWrapper = "elm-select-input-underline-wrapper"

    -- Multi input
    , multiInputItemContainer = "elm-select-multi-input-item-container"
    , multiInputItem = "elm-select-multi-input-item"
    , multiInputItemText = "elm-select-multi-input-item-text"
    , multiInputItemRemove = "elm-select-multi-item-remove"

    --
    -- Menu
    , menu = "elm-select-menu"
    , menuAnchor = "elm-select-menu-anchor"
    , menuItem = "elm-select-menu-item"
    , menuItemSelectable = "elm-select-menu-item-selectable"
    }


referenceDataName : String
referenceDataName =
    "data-select-id"


referenceAttr : Config msg item -> State -> Attribute msg2
referenceAttr config model =
    attribute referenceDataName model.id


difference : List item -> List item -> List item
difference listA listB =
    List.filter (\x -> not <| List.any (\y -> x == y) listB) listA


inputAttributes : Config msg item -> State -> List item -> List item -> Maybe (List item) -> List (Html.Attribute msg)
inputAttributes config model availableItems selectedItems maybeMatchedItems =
    let
        promptAttrs =
            if List.isEmpty selectedItems then
                config.promptAttrs

            else
                []

        -- item that will be selected if enter if pressed
        preselectedItem : Maybe item
        preselectedItem =
            case maybeMatchedItems of
                Nothing ->
                    Nothing

                Just matchedItems ->
                    case model.highlightedItem of
                        Nothing ->
                            List.head matchedItems

                        Just n ->
                            Array.fromList matchedItems
                                |> Array.get (remainderBy (List.length matchedItems) n)
    in
    [ autocomplete False
    , attribute "autocorrect" "off" -- for mobile Safari
    , onBlurAttribute config model |> Html.Styled.Attributes.map config.toMsg
    , onKeyUpAttribute preselectedItem |> Html.Styled.Attributes.map config.toMsg
    , onKeyPressAttribute preselectedItem |> Html.Styled.Attributes.map config.toMsg
    , onInput Msg.OnQueryChange |> Html.Styled.Attributes.map config.toMsg
    , onFocus Msg.OnFocus |> Html.Styled.Attributes.map config.toMsg
    , referenceAttr config model
    ]
        ++ [ class classNames.input ]
        ++ config.inputAttrs
        ++ promptAttrs


onClickWithoutPropagation : Msg item -> Attribute (Msg item)
onClickWithoutPropagation msg =
    Decode.succeed ( msg, False )
        |> stopPropagationOn "click"


onKeyPressAttribute : Maybe item -> Attribute (Msg item)
onKeyPressAttribute maybeItem =
    let
        fn code =
            case code of
                -- Tab
                9 ->
                    maybeItem
                        |> Maybe.map (Decode.succeed << Msg.OnSelect)
                        |> Maybe.withDefault (Decode.fail "nothing selected")

                -- Enter
                13 ->
                    maybeItem
                        |> Maybe.map (Decode.succeed << Msg.OnSelect)
                        |> Maybe.withDefault (Decode.fail "nothing selected")

                _ ->
                    Decode.fail "not TAB or ENTER"
    in
    preventDefaultOn "keypress"
        (Decode.andThen fn keyCode
            |> Decode.map (\msg -> ( msg, True ))
        )


onKeyUpAttribute : Maybe item -> Attribute (Msg item)
onKeyUpAttribute maybeItem =
    let
        selectItem =
            case maybeItem of
                Nothing ->
                    Decode.fail "not Enter"

                Just item ->
                    Decode.succeed (Msg.OnSelect item)

        fn code =
            case code of
                13 ->
                    selectItem

                38 ->
                    Decode.succeed Msg.OnUpArrow

                40 ->
                    Decode.succeed Msg.OnDownArrow

                27 ->
                    Decode.succeed Msg.OnEsc

                _ ->
                    Decode.fail "not ENTER"
    in
    preventDefaultOn "keyup"
        (Decode.andThen fn keyCode
            |> Decode.map (\msg -> ( msg, True ))
        )


onBlurAttribute : Config msg item -> State -> Attribute (Msg item)
onBlurAttribute config state =
    let
        dataDecoder =
            Decode.at [ "relatedTarget", "attributes", referenceDataName, "value" ] Decode.string

        attrToMsg attr =
            if attr == state.id then
                Msg.NoOp

            else
                Msg.OnBlur

        blur =
            Decode.maybe dataDecoder
                |> Decode.map (Maybe.map attrToMsg)
                |> Decode.map (Maybe.withDefault Msg.OnBlur)
    in
    on "focusout" blur


splitWithSeparators : List String -> String -> List String
splitWithSeparators separators phrase =
    if List.isEmpty separators then
        [ phrase ]

    else
        let
            separatorRegex =
                separators
                    |> String.join "|"
                    |> Regex.fromString
                    |> Maybe.withDefault Regex.never
        in
        Regex.split separatorRegex phrase
            |> List.map String.trim


uniqueBy : (a -> comparable) -> List a -> List a
uniqueBy f list =
    uniqueHelper f Set.empty list []


uniqueHelper : (a -> comparable) -> Set comparable -> List a -> List a -> List a
uniqueHelper f existing remaining accumulator =
    case remaining of
        [] ->
            List.reverse accumulator

        first :: rest ->
            let
                computedFirst =
                    f first
            in
            if Set.member computedFirst existing then
                uniqueHelper f existing rest accumulator

            else
                uniqueHelper f (Set.insert computedFirst existing) rest (first :: accumulator)
