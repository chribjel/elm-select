module Select.Select.Menu exposing (view)

import Accessibility.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (class, style)
import Select.Config exposing (Config)
import Select.Messages exposing (..)
import Select.Models as Models exposing (State)
import Select.Select.Item as Item
import Select.Shared exposing (classNames)


view : Config msg item -> State -> Maybe (List item) -> List item -> Html msg
view config state maybeMatchedItems selectedItems =
    div [ class classNames.menuAnchor ] [ maybeMenu config state maybeMatchedItems selectedItems ]


maybeMenu : Config msg item -> State -> Maybe (List item) -> List item -> Html msg
maybeMenu config state maybeMatchedItems selectedItems =
    case maybeMatchedItems of
        Nothing ->
            text ""

        Just matchedItems ->
            menu config state matchedItems selectedItems


menu : Config msg item -> State -> List item -> List item -> Html msg
menu config state matchedItems selectedItems =
    let
        hideWhenNotFound =
            config.notFoundShown == False && matchedItems == []

        menuStyles =
            if hideWhenNotFound then
                [ style "display" "none" ]

            else
                []

        noResultElement =
            if matchedItems == [] then
                Item.viewNotFound config

            else
                text ""

        itemCount =
            List.length matchedItems

        elements =
            matchedItems
                |> List.indexedMap (Item.view config state itemCount selectedItems)
    in
    button
        ([ class classNames.menu ]
            ++ menuStyles
            ++ config.menuAttrs
        )
        (noResultElement :: elements)
