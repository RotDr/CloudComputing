import gleam/option.{type Option}
import lustre_http
import objects.{type Card, type Deck}

pub type Model {
  CardManager(cards: List(Card))
  CardModifying(card_id: Int)
  CardDeleting(card_id: Int)
  CardCreation
  DeckManager(deck: List(Deck))
  DeckModifying(deck: Deck, cards: List(Card))
  DeckDeleting(deck_id: Int, deck_title: String)
  DeckCreation
  Start
  Quiz
  ErrorState(code: Int, err_msg: String)
}

pub type Message {
  UserOpensCardManagement
  UserCreatesACard
  UserModifiesACard(card_id: Option(Int))
  UserDeletesACard(card_id: Option(Int))
  UserConfirmsAction
  UserPutsDeckInfo(title: Option(String))
  UserGoesBack
  UserOpensDeckManagement
  UserCreatesADeck
  UserModifiesADeck(deck_id: Option(Int))
  UserDeletesADeck(deck_id: Option(Int))
  UserAddsACardToDeck(deck_id: Option(Int), card_id: Option(Int))
  UserTakesAQuiz(
    deck_id: Int,
    card_list: Option(List(Int)),
    card_no: Option(Int),
    score: Int,
  )
  DBGaveTheCards(cards: Result(List(Card), lustre_http.HttpError))
  DBGaveTheDecks(deck: Result(List(Deck), lustre_http.HttpError))
  DBGaveTheCard(card: Result(Card, lustre_http.HttpError))
  DBGaveTheDeck(Result(#(Deck, List(Card)), lustre_http.HttpError))
  AppError(code: Int, err: String)
  DBConfirmed(Result(String, lustre_http.HttpError))
  DBGaveTheDeckCards(Result(List(Int), lustre_http.HttpError))
}
