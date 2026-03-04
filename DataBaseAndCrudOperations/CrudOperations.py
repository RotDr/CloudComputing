from DataBaseAndCrudOperations.DataBase import setup_database


def verify_id(cursor,table,id,id_type="id"):
    select_statement =f"""
    Select 1 from {table} where {id_type} = ?
    """
    cursor.execute(select_statement,(id,))
    if cursor.fetchone() is None:
        return False
    else:
        return True

def generic_delete(con,table,table_id,id_type="id"):
    delete_statement =f"""
    DELETE from {table} where {id_type} = ?
    """
    cursor=con.cursor()
    cursor.execute(delete_statement,(table_id,))
    con.commit()
    cursor.close()
def delete_a_card(con,card_id):
    cursor=con.cursor()
    if not verify_id(cursor,"cards",card_id) :
        return f"Card {card_id} not found"
    decks=get_all_decks_that_has_that_card(cursor,card_id)
    if len(decks)!=0:
        for deck_id in decks:
            (deck_id,)=deck_id
            remove_card_from_deck(con,deck_id,card_id)
    cursor.close()
    generic_delete(con,"cards",card_id)
    return f"Card {card_id} deleted "
def remove_card_from_deck(con,deck_id,card_id):
    cursor=con.cursor()
    if not verify_id(cursor,"decks",deck_id) :
        raise Exception(f"Deck {deck_id} not found")
    if not verify_id(cursor,"cards",card_id) :
        raise Exception(f"Card {card_id} not found")
    select_statement =f"""
        delete from deck_cards where deck_id = ? and card_id = ?
    """
    cursor.execute(select_statement,(deck_id,card_id))
    con.commit()
    (cnt,total) = generic_select_unique_id(cursor, "decks", (deck_id,), "cnt, total")
    (score,) = generic_select_unique_id(cursor, "cards", (card_id,), "score")
    total -= score
    cnt -= 1
    generic_update(con, "decks", ["cnt", "total"], (cnt, total, deck_id))
    cursor.close()
    return f"Card {card_id} removed from deck {deck_id} "
def delete_a_deck_from_id(con,deck_id):
    cursor=con.cursor()
    if not verify_id(cursor,"decks",deck_id) :
        return f"Deck {deck_id} not found"
    cards = get_all_cards_not_from_deck(cursor, deck_id)
    if len(cards) != 0:
        for card in cards:
            (card_id,_,_,_,_,_)=card
            remove_card_from_deck(con, deck_id, card_id)
    generic_delete(con,"decks",deck_id)
    cursor.close()
    return f"Deck {deck_id} deleted "
def get_all_cards_not_from_deck(cursor,deck_id):
    select_statement = f"""
        select * from cards c where c.id not in (select d.card_id from deck_cards d where d.deck_id = ?)
    """
    cursor.execute(select_statement,(deck_id,))
    return cursor.fetchall()
def generic_insert(con,table,requirements,data_tuple):
    data_cnt= len(data_tuple)
    questions="("
    requirements_string="("
    for req in requirements:
        questions+=f"?,"
        requirements_string+=f"{req}, "
    questions=questions[:-1]
    requirements_string=requirements_string[:-2]
    questions+=")"
    requirements_string+=")"
    insert_statement = f"""
        INSERT INTO {table} {requirements_string} VALUES {questions}
    """
    cursor = con.cursor()
    cursor.execute(insert_statement,data_tuple)
    con.commit()
    cursor.close()
def generic_select_unique_id(cursor,table,id_tup,what_to_get="*",id_type=["id"]):
    id_string=""
    for idt in id_type :
        id_string+=f"{idt}=?, "
    id_string=id_string[:-2]
    select_statement = f"""
    Select {what_to_get} from {table} where {id_string} 
    """
    cursor.execute(select_statement,id_tup)
    result=cursor.fetchone()
    if result is None:
        raise Exception(f'No such {id_type} : {id_tup} found in {table}!')
    else:
        return result

def get_all_decks(cursor):
    select_statement = f"""
        SELECT * FROM decks 
    """
    cursor.execute(select_statement)
    result=cursor.fetchall()
    return result
def get_all_cards(cursor):
    select_statement = f"""
            SELECT * FROM cards 
        """
    cursor.execute(select_statement)
    result = cursor.fetchall()
    return result
def generic_select_non_unique_id(cursor,table,id,what_to_get,id_type):
    id_string = ""
    for idt in id_type:
        id_string += f"{idt}=?, "
    id_string = id_string[:-2]
    select_statement = f"""
    Select {what_to_get} from {table} where {id_string}
    """
    cursor.execute(select_statement,id)
    object_list=cursor.fetchall()
    return object_list
def generic_update(con,table,columns,values): # you need to put id into values
    collums_string=""
    cursor=con.cursor()
    for col in columns:
        collums_string=collums_string+f" {col} =?, "
    collums_string=collums_string[:-2]
    update_statement = f"""
    UPDATE {table} 
    SET {collums_string}
    WHERE id = ?
    """
    cursor.execute(update_statement,values)
    con.commit()
    cursor.close()

def modify_card(con,card_id,question=None,answer=None,score=None):
    collums=[]
    values=()
    if not(question is None or question==""):
        collums+=["question"]
        values+=(question,)
    if not(answer is None or answer==""):
        collums+=["answer"]
        values+=(answer,)
    if score.isdigit() :
        score=int(score)
        if score<0 :
            raise Exception('Score cannot be negative')
        collums+=["score"]
        values+=(score,)
    else:
        if not (score is None or score==""):
            raise Exception('Score is not the right format')
    if len(collums)==0:
        raise Exception("There is nothing to modify")
    values+=(card_id,)
    generic_update(con,"cards",collums,values)
    return f'Card {card_id} modified successfully'
def create_deck(con,title): # tested
    if len(title)==0 or title is None:
        raise Exception('Title cannot be empty nor null')
    if verify_id(con.cursor(),"decks",title,"title"):
        raise Exception('Deck already exists')
    generic_insert(con,"decks",["title"],(title,))
    return f'Deck {title} created successfully'

def create_card(con,question,answer,score=0): #tested
    if len(question)==0 or question is None:
        raise Exception('Question cannot be empty nor null')
    if len(answer)==0 or answer is None:
        raise Exception('Answer cannot be empty nor null')
    if score<0 :
        raise Exception('Score cannot be negative')
    generic_insert(con, "cards", ["question","answer","score"],(question,answer,score) )
def add_card_to_deck(con,card_id,deck_id):
    cursor = con.cursor()
    if not ( verify_id(cursor,"cards",card_id) ):
        raise Exception('Card id not found!')
    if not ( verify_id(cursor,"decks",deck_id) ):
        raise Exception('Deck id not found!')
    generic_insert(con,"deck_cards",["deck_id","card_id"],(deck_id,card_id))
    (cnt,total)=generic_select_unique_id(cursor,"decks",(deck_id,),"cnt, total")
    (score,)=generic_select_unique_id(cursor,"cards",(card_id,),"score")
    total+=score
    cnt+=1
    generic_update(con,"decks",["cnt","total"],(cnt,total,deck_id))
    cursor.close()
def get_card(con,card_id): # tested
    try:
        cursor = con.cursor()
        card=generic_select_unique_id(cursor,"cards",(card_id,))
        cursor.close()
        return card # TODO card class and return that instead of a tuple
    except:
        raise Exception(f'No such id: {card_id} found in cards table!')

def get_deck_by_id(con,deck_id): #tested
    try:
        cursor = con.cursor()
        deck=generic_select_unique_id(cursor,"decks",(deck_id,))
        cursor.close()
        return deck # TODO deck class and return that instead of a tuple
    except:
        raise Exception(f'No such id : {deck_id} found in decks table!')
def get_all_card_ids_by_deck(con,deck_id): # tested
    try:
        cursor = con.cursor()
        deck=generic_select_non_unique_id(cursor,"deck_cards",(deck_id,),"card_id",["deck_id"])
        cursor.close()
        return deck
    except Exception as e:
        raise Exception(f'Error in the dababase {str(e)}')


def get_all_decks_that_has_that_card(cursor, card_id):
    try:
        decks = generic_select_non_unique_id(cursor, "deck_cards", (card_id,), "deck_id", ["card_id"])
        cursor.close()
        return decks
    except Exception as e:
        raise Exception(f'Error in the dababase {str(e)}')
def register_answer(con, card_id, is_correct): #tested
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
def see_db(cursor,name):
    select_st=f"select * from {name}"
    cursor.execute(select_st)
    print(cursor.fetchall())