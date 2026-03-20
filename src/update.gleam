import gleam/option.{type Option, None, Some}
import interaction_with_back
import lustre/effect.{type Effect}
import lustre_http
import model.{
  type Message, type Model, AppError, CardCreation, CardDeleting, CardManager,
  CardModifying, ConfirmationPage, DBConfirmed, DBGaveTheCard, DBGaveTheCards,
  DBGaveTheDeck, DBGaveTheDecks, DeckCardAddition, DeckCardRemoval, DeckCreation,
  DeckDeleting, DeckManager, DeckModifying, ErrorState, NewDeckCardChoose, Quiz,
  Start, UserAddsACardToDeck, UserConfirmsAction, UserCreatesACard,
  UserCreatesADeck, UserDeletesACard, UserDeletesADeck, UserGoesBack,
  UserModifiesACard, UserModifiesADeck, UserModifiesCard,
  UserOpensCardManagement, UserOpensDeckManagement, UserTakesAQuiz,
  UserTypesCard, UserTypesDeck, UserWantsToAddACardToDeck,
  UserWantsToRemoveACardFromDeck,
}

//import objects.{type Card, type Deck, type DeckCards, Card, Deck, DeckCards}

pub fn http_error_to_string(error: lustre_http.HttpError) -> #(Int, String) {
  case error {
    lustre_http.Unauthorized -> #(
      401,
      "Unauthorized: Check your API keys or login status.",
    )
    lustre_http.NotFound -> #(
      404,
      "Not Found: The requested resource doesn't exist.",
    )
    lustre_http.NetworkError -> #(
      598,
      "Network Error: Please check your internet connection.",
    )
    lustre_http.BadUrl(m) -> #(400, "BadUrl error : " <> m)
    lustre_http.OtherError(code, message) -> #(code, "Error " <> message)
    lustre_http.InternalServerError(m) -> #(
      500,
      "Unexpected internal server error" <> m,
    )
    lustre_http.JsonError(_) -> #(400, "Json error ")
  }
}

pub fn init(_flags) -> #(Model, Effect(Message)) {
  #(Start, effect.none())
}

fn transition(mod: Model, mess: Message) -> Option(Model) {
  case mod {
    Start ->
      case mess {
        UserOpensCardManagement -> Some(CardManager([]))
        UserOpensDeckManagement -> Some(DeckManager([]))
        UserTakesAQuiz(_, _, _, _) -> Some(Quiz)
        _ -> None
      }
    CardManager(cards) ->
      case mess {
        UserCreatesACard -> Some(CardCreation(cards, "", "", None))
        UserModifiesACard(id) ->
          Some(CardModifying(cards, id, None, None, None))
        UserDeletesACard(id) -> Some(CardDeleting(cards, id))
        UserGoesBack -> Some(Start)
        _ -> None
      }
    CardCreation(cards, _, _, _) ->
      case mess {
        UserGoesBack -> Some(CardManager(cards))
        _ -> None
      }
    CardModifying(cards, _, _, _, _) ->
      case mess {
        UserGoesBack -> Some(CardManager(cards))
        _ -> None
      }
    CardDeleting(cards, _) ->
      case mess {
        UserGoesBack -> Some(CardManager(cards))
        _ -> None
      }
    DeckManager(decks) ->
      case mess {
        UserCreatesADeck -> Some(DeckCreation(decks, ""))
        UserModifiesADeck(deck, cards) ->
          Some(DeckModifying(decks, deck, cards))
        UserDeletesADeck(id) -> Some(DeckDeleting(decks, id))
        UserGoesBack -> Some(Start)
        _ -> None
      }
    DeckCardAddition(decks, deck, cards, _, _) ->
      case mess {
        UserGoesBack -> Some(DeckModifying(decks, deck, cards))
        _ -> None
      }

    DeckCreation(decks, _) ->
      case mess {
        UserGoesBack -> Some(DeckManager(decks))
        UserTypesDeck(title) -> Some(DeckCreation(decks, title))
        _ -> None
      }
    DeckModifying(decks, deck, cards) ->
      case mess {
        UserGoesBack -> Some(DeckManager(decks))
        UserWantsToRemoveACardFromDeck(card_id) ->
          Some(DeckCardRemoval(decks, deck, cards, card_id))
        _ -> None
      }
    NewDeckCardChoose(decks, deck, cards, not_in_cards) -> {
      case mess {
        UserGoesBack -> Some(DeckManager(decks))
        UserAddsACardToDeck(card_id) ->
          Some(DeckCardAddition(decks, deck, cards, not_in_cards, card_id))
        _ -> None
      }
    }
    DeckDeleting(decks, _) ->
      case mess {
        UserGoesBack -> Some(DeckManager(decks))
        _ -> None
      }
    Quiz ->
      case mess {
        UserTakesAQuiz(_, _, _, _) -> None
        UserGoesBack -> Some(Start)
        _ -> None
      }
    ErrorState(_, _) ->
      case mess {
        UserGoesBack -> Some(Start)
        _ -> None
      }
    ConfirmationPage(_) -> {
      case mess {
        UserGoesBack -> Some(Start)
        _ -> None
      }
    }
    _ -> None
  }
}

pub fn update(mod: Model, mess: Message) -> #(Model, Effect(Message)) {
  case mess {
    DBGaveTheCards(Ok(cards)) -> {
      case mod {
        Start -> #(CardManager(cards), effect.none())
        NewDeckCardChoose(decks, deck, deck_cards, _) -> #(
          NewDeckCardChoose(decks, deck, deck_cards, cards),
          effect.none(),
        )
        CardManager(_) -> #(CardManager(cards), effect.none())
        _ -> #(ErrorState(500, "How?"), effect.none())
      }
    }
    DBGaveTheCards(Error(e)) -> {
      let #(code, msg) = http_error_to_string(e)
      #(ErrorState(code, msg), effect.none())
    }

    DBGaveTheCard(Ok(_)) -> #(mod, effect.none())
    DBGaveTheCard(Error(e)) -> {
      let #(code, msg) = http_error_to_string(e)
      #(ErrorState(code, msg), effect.none())
    }

    DBGaveTheDecks(Ok(decks)) -> #(DeckManager(decks), effect.none())
    DBGaveTheDecks(Error(e)) -> {
      let #(code, msg) = http_error_to_string(e)
      #(ErrorState(code, msg), effect.none())
    }

    DBGaveTheDeck(Ok(#(deck, cards))) ->
      case mod {
        DeckModifying(decks, _, _) -> #(
          DeckModifying(decks, deck, cards),
          effect.none(),
        )
        DeckManager(decks) -> #(
          DeckModifying(decks, deck, cards),
          effect.none(),
        )
        _ -> #(
          ErrorState(500, "Unexpected state for DBGaveTheDeck"),
          effect.none(),
        )
      }
    DBGaveTheDeck(Error(e)) -> {
      let #(code, msg) = http_error_to_string(e)
      #(ErrorState(code, msg), effect.none())
    }

    DBConfirmed(Ok(mes)) ->
      case mod {
        ConfirmationPage(_) -> #(ConfirmationPage(mes), effect.none())
        _ -> #(Start, effect.none())
      }
    DBConfirmed(Error(e)) -> {
      let #(code, msg) = http_error_to_string(e)
      #(ErrorState(code, msg), effect.none())
    }

    AppError(code, err) -> #(ErrorState(code, err), effect.none())
    UserWantsToAddACardToDeck ->
      case mod {
        DeckModifying(decks, deck, cards) -> #(
          NewDeckCardChoose(decks, deck, cards, []),
          interaction_with_back.get_cards_not_from_deck(deck.id),
        )
        _ -> #(Start, effect.none())
      }
    UserOpensCardManagement -> #(
      CardManager([]),
      interaction_with_back.get_cards(),
    )
    UserOpensDeckManagement -> #(
      DeckManager([]),
      interaction_with_back.get_decks(),
    )
    UserDeletesADeck(id) ->
      case mod {
        DeckManager(decks) -> #(DeckDeleting(decks, id), effect.none())
        _ -> #(mod, effect.none())
      }
    UserTypesCard(q, a, s) ->
      case mod {
        CardCreation(cards, _, _, _) -> #(
          CardCreation(cards, q, a, s),
          effect.none(),
        )
        _ -> #(mod, effect.none())
      }
    UserTypesDeck(t) ->
      case mod {
        DeckCreation(decks, _) -> #(DeckCreation(decks, t), effect.none())
        _ -> #(mod, effect.none())
      }
    UserModifiesCard(q, a, s) -> {
      case mod {
        CardModifying(cards, card_id, _, _, _) -> #(
          CardModifying(cards, card_id, q, a, s),
          effect.none(),
        )
        _ -> #(mod, effect.none())
      }
    }
    UserModifiesADeck(deck, cards) ->
      case mod {
        DeckManager(decks) -> #(
          DeckModifying(decks, deck, cards),
          interaction_with_back.get_deck(deck.id),
        )
        _ -> #(mod, effect.none())
      }
    UserAddsACardToDeck(card_id) -> {
      case mod {
        NewDeckCardChoose(_, deck, _, _) -> #(
          Start,
          interaction_with_back.add_card_to_deck(deck.id, card_id),
        )
        _ -> #(mod, effect.none())
      }
    }
    UserConfirmsAction ->
      case mod {
        CardCreation(_, question, answer, score) -> {
          case score {
            Some(s) -> #(
              ConfirmationPage(""),
              interaction_with_back.create_card(question, answer, s),
            )
            None -> #(
              ConfirmationPage(""),
              interaction_with_back.create_card(question, answer, 0),
            )
          }
        }
        CardModifying(_, card_id, question, answer, score) -> #(
          ConfirmationPage(""),
          interaction_with_back.modify_card(card_id, question, answer, score),
        )

        CardDeleting(_, card_id) -> #(
          ConfirmationPage(""),
          interaction_with_back.delete_card(card_id),
        )
        DeckCreation(_, title) -> #(
          ConfirmationPage(""),
          interaction_with_back.create_deck(title),
        )
        DeckCardRemoval(_, deck, _, card_id) -> #(
          ConfirmationPage(""),
          interaction_with_back.remove_card_from_deck(deck.id, card_id),
        )
        DeckDeleting(_, deck_id) -> #(
          ConfirmationPage(""),
          interaction_with_back.delete_deck(deck_id),
        )
        DeckCardAddition(_, deck, _, _, card_id) -> #(
          ConfirmationPage(""),
          interaction_with_back.add_card_to_deck(deck.id, card_id),
        )

        _ -> {
          let assert Some(next) = transition(mod, mess)
          #(next, effect.none())
        }
      }
    _ -> {
      let assert Some(next) = transition(mod, mess)
      #(next, effect.none())
    }
  }
}
