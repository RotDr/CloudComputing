import gleam/list
import gleam/option.{type Option, None, Some}
import interaction_with_back
import lustre/effect.{type Effect}
import model.{
  type Message, type Model, AppError, CardCreation, CardDeleting, CardManager,
  CardModifying, DBConfirmed, DBGaveTheCard, DBGaveTheCards, DBGaveTheDeck,
  DBGaveTheDeckCards, DBGaveTheDecks, DeckCreation, DeckDeleting, DeckManager,
  DeckModifying, ErrorState, Quiz, Start, UserAddsACardToDeck,
  UserConfirmsAction, UserCreatesACard, UserCreatesADeck, UserDeletesACard,
  UserDeletesADeck, UserGoesBack, UserModifiesACard, UserModifiesADeck,
  UserOpensCardManagement, UserOpensDeckManagement, UserPutsDeckInfo,
  UserTakesAQuiz,
}
import objects.{type Card, type Deck, type DeckCards, Card, Deck, DeckCards}

pub fn init(_flags) -> #(Model, Effect(Message)) {
  #(Start, effect.none())
}

fn transition(mod: Model, mess: Message) -> Option(Model) {
  case mod {
    Start ->
      case mess {
        UserOpensCardManagement -> Some(CardManager([]))
        UserOpensDeckManagement -> Some(DeckManager([]))
        UserTakesAQuiz(deck_id, card_list, card_no, score) -> Some(Quiz)
        _ -> None
      }
    CardManager(_) ->
      case mess {
        UserCreatesACard -> Some(CardCreation)
        UserModifiesACard(id) ->
          case id {
            Some(nr) -> Some(CardModifying(nr))
            None -> None
          }
        UserDeletesACard(id) ->
          case id {
            Some(nr) -> Some(CardDeleting(nr))
            None -> None
          }
        UserGoesBack -> Some(Start)
        _ -> None
      }
    CardCreation ->
      case mess {
        UserConfirmsAction -> Some(CardManager([]))
        UserGoesBack -> Some(CardManager([]))
        _ -> None
      }
    CardModifying(id) ->
      case mess {
        UserConfirmsAction -> Some(CardManager([]))
        UserGoesBack -> Some(CardManager([]))
        _ -> None
      }
    CardDeleting(id) ->
      case mess {
        UserConfirmsAction -> Some(CardManager([]))
        UserGoesBack -> Some(CardManager([]))
        _ -> None
      }
    DeckManager(deck) ->
      case mess {
        UserCreatesADeck -> Some(DeckCreation)
        UserModifiesADeck(id) -> None
        //Some(DeckModifying(None,[]))
        UserDeletesADeck(id) -> Some(DeckDeleting(0, ""))
        UserGoesBack -> Some(Start)
        _ -> None
      }
    DeckCreation ->
      case mess {
        UserConfirmsAction -> Some(DeckManager([]))
        UserGoesBack -> Some(DeckManager([]))
        _ -> None
      }
    DeckModifying(deck, cards) ->
      case mess {
        UserConfirmsAction -> Some(DeckManager([]))
        UserGoesBack -> Some(DeckManager([]))
        _ -> None
      }
    DeckDeleting(id, title) ->
      case mess {
        UserConfirmsAction -> Some(DeckManager([]))
        UserGoesBack -> Some(DeckManager([]))
        _ -> None
      }
    Quiz ->
      case mess {
        UserTakesAQuiz(deck_id, card_list, card_no, score) -> None
        UserGoesBack -> Some(Start)
        _ -> None
      }
    ErrorState(c, e) ->
      case mess {
        UserGoesBack -> Some(Start)
        _ -> None
      }
  }
}

pub fn update(mod: Model, mess: Message) -> #(Model, Effect(Message)) {
  case mess {
    DBGaveTheCards(Ok(cards)) -> #(CardManager(cards), effect.none())
    DBGaveTheCards(Error(_)) -> #(
      ErrorState(500, "Failed to fetch cards"),
      effect.none(),
    )

    DBGaveTheCard(Ok(card)) -> #(mod, effect.none())
    DBGaveTheCard(Error(_)) -> #(
      ErrorState(500, "Failed to fetch card"),
      effect.none(),
    )

    DBGaveTheDecks(Ok(decks)) -> #(DeckManager(decks), effect.none())
    DBGaveTheDecks(Error(_)) -> #(
      ErrorState(500, "Failed to fetch decks"),
      effect.none(),
    )

    DBGaveTheDeck(Ok(#(deck, cards))) -> #(
      DeckModifying(deck, cards),
      effect.none(),
    )
    DBGaveTheDeck(Error(_)) -> #(
      ErrorState(500, "Failed to fetch deck"),
      effect.none(),
    )

    DBGaveTheDeckCards(Ok(_)) -> #(mod, effect.none())
    DBGaveTheDeckCards(Error(_)) -> #(
      ErrorState(500, "Failed to fetch deck cards"),
      effect.none(),
    )

    DBConfirmed(Ok(_)) ->
      case mod {
        CardCreation -> #(CardManager([]), interaction_with_back.get_cards())
        CardModifying(_) -> #(
          CardManager([]),
          interaction_with_back.get_cards(),
        )
        CardDeleting(_) -> #(CardManager([]), interaction_with_back.get_cards())
        DeckCreation -> #(DeckManager([]), interaction_with_back.get_decks())
        DeckDeleting(_, _) -> #(
          DeckManager([]),
          interaction_with_back.get_decks(),
        )
        _ -> #(mod, effect.none())
      }
    DBConfirmed(Error(_)) -> #(
      ErrorState(500, "Operation failed"),
      effect.none(),
    )

    AppError(code, err) -> #(ErrorState(code, err), effect.none())

    // ── navigation with side effects ────────────────────────────────────────
    UserOpensCardManagement -> #(
      CardManager([]),
      interaction_with_back.get_cards(),
    )
    UserOpensDeckManagement -> #(
      DeckManager([]),
      interaction_with_back.get_decks(),
    )

    // ── pure transitions ────────────────────────────────────────────────────
    _ -> {
      let assert Some(next) = transition(mod, mess)
      #(next, effect.none())
    }
  }
}
