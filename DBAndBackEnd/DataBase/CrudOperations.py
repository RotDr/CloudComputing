from DataBase.GenericOperations import *
from DataBase.objects import *

def delete_a_card(con,card_id:int)-> Http_response:
    cursor=con.cursor()
    if not verify_id(cursor,"cards",card_id) :
        e=Http_response(code=404,message=f"Card {card_id} not found")
        return e
    decks=get_all_decks_that_has_that_card(cursor,card_id)
    if type(decks)==Http_response:
        return decks
    if len(decks)!=0:
        for deck_id in decks:
            deck_id=deck_id[0]
            try :
                remove_card_from_deck(con,deck_id,card_id)
            except Exception as e:
                if type(e[0])==int:
                    return Http_response(code=e.args[0],message=e[1])
                else:
                    return Http_response(code=500,message=f"Internal db error: {str(e)}")
    cursor.close()
    try:
        generic_delete(con,"cards",card_id)
        e=Http_response(code=200,message=f"Card {card_id} deleted ")
        return e
    except Exception as e:
        return Http_response(code=500,message=f"Internal db error: {str(e)}")


def remove_card_from_deck(con,deck_id,card_id) ->Http_response:
    cursor=con.cursor()
    if not verify_id(cursor,"decks",deck_id) :
        return Http_response(code=404,message=f"Deck {deck_id} not found")
    if not verify_id(cursor,"cards",card_id) :
        return Http_response(code=404,message=f"Card {card_id} not found")
    select_statement =f"""
        delete from deck_cards where deck_id = ? and card_id = ?
    """
    cursor.execute(select_statement,(deck_id,card_id))
    con.commit()
    try:
        (cnt,total) = generic_select_unique_id(cursor, "decks", (deck_id,), "cnt, total")
        (score,) = generic_select_unique_id(cursor, "cards", (card_id,), "score")
        total -= score
        cnt -= 1
        
        generic_update(con, "decks", ["cnt", "total"], (cnt, total, deck_id))
        cursor.close()
        return Http_response(code=200,message=f"Card {card_id} removed from deck {deck_id} ")
    except Exception as e:
        return Http_response(code=500,message=f"Internal db error: {str(e)}")


def delete_a_deck_from_id(con,deck_id) -> Http_response:
    cursor=con.cursor()
    if not verify_id(cursor,"decks",deck_id) :
        return Http_response(code=404,message=f"Deck {deck_id} not found")
    cards = get_all_card_ids_by_deck(cursor, deck_id)
    if type(cards)==Http_response:
        return cards
    if len(cards) != 0:
        for card in cards:
            card_id=card[0]
            remove_card_from_deck(con, deck_id, card_id)
    try:
        generic_delete(con,"decks",deck_id)
        cursor.close()
        e=Http_response(code=200,message=f"Deck {deck_id} deleted ")
        return e
    except Exception as e:
        return Http_response(code=500,message=f"Internal db error: {str(e)}")



def get_all_cards_not_from_deck(cursor,deck_id:int) -> list[Card]:
    select_statement = f"""
        select * from cards c where c.id not in (select d.card_id from deck_cards d where d.deck_id = ?)
    """
    cursor.execute(select_statement,(deck_id,))
    cards=cursor.fetchall()
    cards_list = [{
    "id": c[0],
    "question": c[1], 
    "answer": c[2],
    "score": c[3], 
    "times_correct": c[4], 
    "times_wrong": c[5]
    } for c in cards]
    return cards_list

def get_all_decks(cursor)-> list[Deck]:
    select_statement = f"""
        SELECT * FROM decks 
    """
    cursor.execute(select_statement)
    decks=cursor.fetchall()
    decks_list = [{
        "id": d[0],
        "title": d[1],
        "cnt" : d[2],
        "total" : d[3]
    } for d in decks]
    return decks_list


def get_all_cards(cursor)->list[Card]:
    select_statement = f"""
            SELECT * FROM cards 
        """
    cursor.execute(select_statement)
    cards=cursor.fetchall()
    cards_list = [{
    "id": c[0],
    "question": c[1], 
    "answer": c[2],
    "score": c[3], 
    "times_correct": c[4], 
    "times_wrong": c[5]
    } for c in cards]
    return cards_list


def modify_card(con,card_id:int,question:str=None,answer:str=None,score:str=0)->Http_response:
    collums=[]
    values=()
    if not(question is None or question==""):
        collums+=["question"]
        values+=(question,)
    if not(answer is None or answer==""):
        collums+=["answer"]
        values+=(answer,)
    if score<0 :
        return  Http_response(code=405,message=f'Score cannot be negative')
    else:
        collums+=["score"]
        values+=(score,)
    if len(collums)==0:
        return Http_response(code=204,message=f'There is nothing to modify')
    values+=(card_id,)
    try:
        generic_update(con,"cards",collums,values)
        e=Http_response(code=200,message=f'Card {card_id} modified successfully')
        return e
    except Exception as e:
        return Http_response(code=500,message=f"Internal db error: {str(e)}")

def create_deck(con,title:str) ->Http_response: # tested
    if title is None or len(title)==0:
        return Http_response(code=400 ,message='Title cannot be empty nor null')
    if verify_id(con.cursor(),"decks",title,"title"):
        return Http_response(code=409 ,message='Deck already exists')
    try:
        generic_insert(con,"decks",["title"],(title,))
    except Exception as e:
        if type(e.args[0]) in [400,404,409] and type(e.args[1])==str:
            return Http_response(code=e.args[0],message=e.args[1])
        else:
            return Http_response(code=500,message=f"internal db error{str(e)}")
    else:
        return Http_response(code=200 ,message=f'Deck {title} created successfully')



def create_card(con,question:str,answer:str,score:int=0) -> Http_response: #tested
    if question is None or len(question)==0:
        return Http_response(code=400 ,message='Question cannot be empty nor null')
    if  answer is None or len(answer)==0:
        return Http_response(code=400 ,message='Answer cannot be empty nor null')
    if score<0 :
        return Http_response(code=400 ,message='Score cannot be negative')
    try: 
        generic_insert(con, "cards", ["question","answer","score"],(question,answer,score) )
    except Exception as e:
        if type(e.args[0]) in [400,404,409] and type(e.args[1])==str:
            return Http_response(code=e.args[0],message=e.args[1])
        else:
            return Http_response(code=500,message=f"internal db error{str(e)}")
    else:
        return Http_response(code=201 ,message='Card Created')


def add_card_to_deck(con,card_id:int,deck_id:int)-> Http_response:
    cursor = con.cursor()
    if not ( verify_id(cursor,"cards",card_id) ):
        return Http_response(code=404,message=f'Card id not found!')
    if not ( verify_id(cursor,"decks",deck_id) ):
        return Http_response(code=404,message=f'Deck id not found!')
    generic_insert(con,"deck_cards",["deck_id","card_id"],(deck_id,card_id))
    (cnt,total)=generic_select_unique_id(cursor,"decks",(deck_id,),"cnt, total")
    (score,)=generic_select_unique_id(cursor,"cards",(card_id,),"score")
    total+=score
    cnt+=1
    try:
        generic_update(con,"decks",["cnt","total"],(cnt,total,deck_id))
    except Exception as e : 
        if type(e.args[0]) in [400,404,409] and type(e.args[1])==str:
            return Http_response(code=e.args[0],message=e.args[1])
        else:
            return Http_response(code=500,message=f"internal db error{str(e)}")
    else:
        cursor.close()
        return Http_response(code=201 ,message='Card Created')


def get_card(con,card_id:int) -> (Card | Http_response): # tested
    try:
        cursor = con.cursor()
        card=generic_select_unique_id(cursor,"cards",(card_id,))
        cursor.close()
        card=Card(
            id=card[0],
            question=card[1],
            answer=card[2],
            score=card[3],
            times_correct=card[4],
            times_wrong=card[5]
        )
        return card 
    except:
        return Http_response(code=404,message=f'No such id: {card_id} found in cards table!')


def get_deck(con,deck_id:int): #tested
    try:
        cursor = con.cursor()
        deck=generic_select_unique_id(cursor,"decks",(deck_id,))
        cursor.close()
        deck = Deck(
        id= deck[0],
        title= deck[1],
        cnt= deck[2],
        total= deck[3]
        )
        return deck
    except:
        return Http_response(code=404,message=f'No such id: {deck_id} found in decks table!')
def get_all_card_ids_by_deck(cursor,deck_id)-> (list[int] | Http_response): # tested
    try:
        deck=generic_select_non_unique_id(cursor,"deck_cards",(deck_id,),"card_id",["deck_id"])
    
        return deck
    except Exception as e:
        return Http_response(code=404,message=f'No such id: {deck_id} found in deck table!')


def get_all_decks_that_has_that_card(cursor, card_id:int)->list[int]:
    try:
        decks = generic_select_non_unique_id(cursor, "deck_cards", (card_id,), "deck_id", ["card_id"])
        return decks
    except Exception as e:
        return Http_response(code=404,message=f'Error in the database')
    

def register_answer(con, card_id:int, is_correct:bool)-> int: #tested
    field=""
    if is_correct:
        field="times_correct,score"
    else:
        field="times_wrong,score"
    cursor = con.cursor()
    (times,score)=generic_select_unique_id(cursor,"cards",(card_id,),field)
    cursor.close()
    times=times+1
    field=field.split(",")[0]
    generic_update(con,"cards",[field],(times,card_id))
    if not is_correct:
        score=0
    return score