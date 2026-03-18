
from typing import TypedDict
class Http_response(TypedDict) :
    code:int
    message:str
class Deck(TypedDict):
    id:int
    title:str
    cnt:int
    total:int
class Card(TypedDict):
    id:int
    question:str
    answer:str
    score:int
    times_correct:int 
    times_wrong:int
class  Deck_cards(TypedDict):
    deck_id:int
    card_id:int 