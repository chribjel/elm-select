module Select.Select.Input.Multi exposing (view)

import Accessibility.Styled as Html exposing (..)
import Html.Styled.Attributes
    exposing
        ( attribute
        , autocomplete
        , class
        , id
        , placeholder
        , style
        , value
        )
import Select.Config exposing (Config)
import Select.Messages as Msg exposing (Msg)
import Select.Models exposing (State)
import Select.Select.RemoveItem as RemoveItem
import Select.Shared as Shared exposing (classNames)


view :
    Config msg item
    -> State
    -> List item
    -> List item
    -> Maybe (List item)
    -> List (Html msg)
view config model availableItems selected maybeMatchedItems =
    let
        val =
            model.query |> Maybe.withDefault ""
    in
    [ currentSelection
        config
        selected
    , Html.inputText
        "haha"
        []
    ]


currentSelection config selected =
    button
        ([ class classNames.multiInputItemContainer ]
            ++ config.multiInputItemContainerAttrs
        )
        (List.map
            (currentSelection_item config)
            selected
        )


currentSelection_item config item =
    button
        ([ class classNames.multiInputItem ]
            ++ config.multiInputItemAttrs
        )
        [ div
            [ class classNames.multiInputItemText ]
            [ text (config.toLabel item) ]
        , currentSelection_item_maybeClear
            config
            item
        ]


currentSelection_item_maybeClear config item =
    case config.onRemoveItem of
        Nothing ->
            text ""

        Just _ ->
            currentSelection_item_clear
                config
                item


currentSelection_item_clear config item =
    button
        [ class classNames.multiInputItemRemove
        , Shared.onClickWithoutPropagation (Msg.OnRemoveItem item)
            |> Html.Styled.Attributes.map config.toMsg
        ]
        [ RemoveItem.view config ]
