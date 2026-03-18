import http.server
import json
import re
import sqlite3
import socketserver
from DataBase.CrudOperations import *
from flask import Flask, jsonify, request 
from flask_cors import CORS
import os

db = os.path.join(os.path.dirname(__file__), 'DataBase/decks.db')

app =Flask(__name__)
CORS(app)

def get_db_connection():
    conn = sqlite3.connect(db)
    return conn

@app.route('/cards',methods=['GET'])
def list_cards():
    conn=get_db_connection()
    cursor=conn.cursor()
    cards = get_all_cards(cursor)
    cursor.close()
    conn.close()
    return jsonify(cards) if cards else (jsonify([]), 204)

@app.route('/cards/<int:card_id>',methods=['GET'])
def get_a_card(card_id):
    conn=get_db_connection()
    cursor=conn.cursor()
    card=get_card(conn,card_id)
    cursor.close()
    conn.close()
    if type(card)==Http_response:
        return jsonify({"message":card["message"]}),card["code"]
    else:
        return jsonify(card)
    # return jsonify(card) if card else (jsonify({"error":"error, card not found"}), 404)

@app.route('/decks',methods=['GET'])
def list_decks():
    conn=get_db_connection()
    cursor=conn.cursor()
    decks=get_all_decks(cursor)
    cursor.close()
    conn.close()
    return jsonify(decks) if decks else (jsonify([]), 204)

@app.route('/decks/<int:deck_id>',methods=['GET'])
def get_a_deck(deck_id:int):
    conn=get_db_connection()
    cursor=conn.cursor()
    deck_cards=get_all_card_ids_by_deck(cursor,deck_id)
    cursor.close()
    conn.close()
    return jsonify(deck_cards) if deck_cards else (jsonify([]), 204)

@app.route('/cards/<int:card_id>',methods=['PATCH'])
def register_an_answer(card_id:int):
    answer = request.json
    conn=get_db_connection()
    if "is_correct" in answer.keys():
        if type(answer["is_correct"])==bool:
            try:
                score=register_answer(conn,card_id,answer["is_correct"])
                conn.close()
                if type(score)==Http_response:
                    return (jsonify({"message":score.message}),score.code)
                else:
                    return (jsonify(score=score),200)
            except Exception as e:
                if e.args[0] in [400,404,405,409] and type(e.args[1])==str:
                    return (jsonify({"message":e.args[1]}),e.args[0])
                else:
                   return (jsonify({"error":str(e)}),500)
        else:
            conn.close()
            return (jsonify({"message":"Incorrect format"}),405)
    else:
        conn.close()
        return (jsonify({"message":"Incorrect format"}),405)

@app.route('/cards',methods=['POST'])
def add_a_card():
    conn=get_db_connection()
    card=request.json
    score=0
    question=None
    answer=None
    if "score" in card.keys():
        if type(card["score"])==int:
            score=card["score"]
        else:
            conn.close()
            return (jsonify({"message":"Incorrect format for score"}),405)
    if "question" in card.keys():
        if type(card["question"])==str:
            question=card["question"]
        else:
            conn.close()
            return (jsonify({"message":"Incorrect format for question"}),405)
    else:
        conn.close()
        return (jsonify({"message":"Question missing"}),405)
    if "answer" in card.keys():
        if type(card["answer"])==str:
            answer=card["answer"]
        else:
            conn.close()
            return (jsonify({"message":"Incorrect format for answer"}),405)
    else:
        conn.close()
        return (jsonify({"message":"Answer missing"}),405)
    rp=create_card(conn,
                    question,
                    answer,
                    score
                    )
    conn.close()
    return (jsonify({"message":rp.message,}),rp.code)


@app.route('/decks',methods=['POST'])
def add_a_deck():
    conn=get_db_connection()
    card=request.json
    title=None
    if "title" in card.keys():
        if type(card["title"])==str:
            title=card["title"]
        else:
            conn.close()
            return (jsonify({"message":"Incorrect format for title"}),405)
    else:
        conn.close()
        return (jsonify({"message":"title missing"}),405)
    rp=create_deck(conn,
                    title
                    )
    conn.close()
    return (jsonify({"message":rp.message,}),rp.code)

@app.route('/decks/<int:deck_id>/<int:card_id>',methods=['POST'])
def add_a_card_to_deck(deck_id:int,card_id:int):
    conn=get_db_connection()
    rp=add_card_to_deck(conn,card_id,deck_id)
    conn.close()
    return (jsonify({"message":rp.message,}),rp.code)

@app.route('/cards/<int:card_id>',methods=['PUT'])
def modify_a_card(card_id:int):
    conn=get_db_connection()
    card=request.json
    score:int=0
    question:str=None
    answer:str=None
    if "score" in card.keys():
        if type(card["score"])==int:
            score=card["score"]
        else:
            conn.close()
            return (jsonify({"message":"Incorrect format for score"}),405)
    if "question" in card.keys():
        if type(card["question"])==str:
            question=card["question"]
        else:
            conn.close()
            return (jsonify({"message":"Incorrect format for question"}),405)
    if "answer" in card.keys():
        if type(card["answer"])==str:
            answer=card["answer"]
        else:
            conn.close()
            return (jsonify({"message":"Incorrect format for answer"}),405)
    rp=modify_card(conn,card_id,question,answer,score)
    conn.close()
    return (jsonify({"message":rp.message,}),rp.code)

@app.route('/cards/<int:card_id>',methods=['DELETE'])
def delete_card(card_id:int):
    conn=get_db_connection()
    rp=delete_a_card(conn,card_id)
    conn.close()
    return (jsonify({"message":rp.message,}),rp.code)

@app.route('/decks/<int:deck_id>',methods=['DELETE'])
def delete_deck(deck_id:int):
    conn=get_db_connection()
    rp=delete_a_deck_from_id(conn,deck_id)
    conn.close()
    return (jsonify({"message":rp.message,}),rp.code)

@app.route('/decks/<int:deck_id>/<int:card_id>',methods=['DELETE'])
def delete_a_card_from_deck(deck_id:int,card_id:int):
    conn=get_db_connection()
    rp=remove_card_from_deck(conn,deck_id,card_id)
    conn.close()
    return (jsonify({"message":rp.message,}),rp.code)
# class MyHandler(http.server.SimpleHTTPRequestHandler):
#     con = sqlite3.connect('DataBaseAndCrudOperations/decks.db')
#     def _set_response(self, status_code=200, content_type='application/json'):
#         self.send_response(status_code)
#         self.send_header('Content-type', content_type)
#         self.send_header('Access-Control-Allow-Origin','*')
#         self.send_header('Access-Control-Allow-Methods','GET,POST,PUT,DELETE,OPTIONS')
#         self.send_header('Access-Control-Allow-Headers', 'Content-Type')
#         self.end_headers()

#     def _read_body(self):
#         content_length = int(self.headers.get('Content-Length', 0))
#         # verificam daca exista un body si cat de mare e
#         if content_length == 0: # nu are body
#             return {}
#         post_data = self.rfile.read(content_length)
#         # rfile este la fel ca open(http-body,r)
#         return json.loads(post_data.decode('utf-8'))

#     def do_GET(self):
#         if self.path == '/cards':
#             cursor = self.con.cursor()
#             cards=get_all_cards(cursor)
#             cursor.close()
#             cards_list = []
#             for card in cards:

#                 card_json = {
#                     "id": card[0],
#                     "question": card[1],
#                     "answer": card[2],
#                     "score": card[3],
#                     "times_correct": card[4],
#                     "times_wrong": card[5],
#                 }
#                 cards_list.append(card_json)
#             if len(cards_list) > 0:
#                 self._set_response(200)
#                 self.wfile.write(json.dumps(cards_list).encode('utf-8'))
#             else:
#                 self._set_response(204)
#                 self.wfile.write(json.dumps([]).encode('utf-8'))
#     def do_POST(self):
#         if self.path == '/cards':
#             body = self._read_body()
#             score=0
#             if "score" in body.keys():
#                 score=body["score"]
#                 try:
#                     score=int(score)
#                 except ValueError:
#                     self._set_response(400)
#                     self.wfile.write(json.dumps({"error": "Bad Request, wrong format for score"}).encode('utf-8'))
#                     return
#             question=""
#             if "question" in body.keys():
#                 question=body["question"]
#             else:
#                 self._set_response(400)
#                 self.wfile.write(json.dumps({"error": "Bad Request, question not found"}).encode('utf-8'))
#                 return
#             answer=""
#             if "answer" in body.keys():
#                 answer=body["answer"]
#             else:
#                 self._set_response(400)
#                 self.wfile.write(json.dumps({"error": "Bad Request, answer not found"}).encode('utf-8'))
#                 return
#             try:
#                 create_card(self.con, question, answer, score)
#             except Exception as e:
#                 self._set_response(400)
#                 self.wfile.write(json.dumps({"error":"DataBase error "+ str(e)}).encode('utf-8'))
#                 return
#             else:
#                 self._set_response(201)
#                 self.wfile.write(json.dumps({"message": "Card created successfully"}).encode('utf-8'))
#                 return
#     def do_PUT(self):
#         if self.path.startswith('/cards/'):
#             id_string = self.path[len('/cards/'):]
#             card_id=None
#             if id_string.isdigit():
#                 card_id = int(id_string)
#             else:
#                 self._set_response(400)
#                 self.wfile.write(json.dumps({"error": "wrong id format"}).encode('utf-8'))
#             body = self._read_body()
#             score=None
#             if "score" in body.keys():
#                 score = body["score"]
#             question = None
#             if "question" in body.keys():
#                 question = body["question"]
#             answer = None
#             if "answer" in body.keys():
#                 answer = body["answer"]
#             try:
#                 if score is not None:
#                     score=str(score)
#                 if isinstance(question,str) and isinstance(answer,str):
#                     modify_card(self.con, card_id, question, answer,score)
#                 else :
#                     raise Exception("Error in body formatting")
#             except Exception as e:
#                 self._set_response(400)
#                 self.wfile.write(json.dumps({"error":"DataBase error "+ str(e)}).encode('utf-8'))
#                 return
#             else:
#                 self._set_response(200)
#                 self.wfile.write(json.dumps({"message": f"Card {card_id} modified successfully"}).encode('utf-8'))
#                 return
#     def do_PATCH(self):
#         if self.path.startswith('/cards/'):
#             id_string = self.path[len('/cards/'):]
#             card_id = None
#             try:
#                 if id_string.isdigit():
#                     card_id = int(id_string)
#                 else:
#                     raise Exception("Error in id formatting")
#                 body = self._read_body()
#                 if "is_correct" in body.keys():
#                     is_correct = body["is_correct"]
#                     if isinstance(is_correct,bool):
#                         register_answer(self.con, card_id, is_correct)
#                     else:
#                         raise Exception("Error in body formatting")
#                 else:
#                     raise Exception("is_correct not found")
#             except Exception as e:
#                 self._set_response(400)
#                 self.wfile.write(json.dumps({"error":str(e)}).encode('utf-8'))
#                 return
#             else:
#                 self._set_response(200)
#                 self.wfile.write(json.dumps({"message": f"Answer registered for card {card_id}"}).encode('utf-8'))
#                 return
#     def do_DELETE(self):
#         if self.path.startswith('/cards/'):
#             id_string = self.path[len('/cards/'):]
#             card_id = None
#             try:
#                 if id_string.isdigit():
#                     card_id = int(id_string)
#                 else:
#                     raise Exception("Error in id formatting")
#                 delete_a_card(self.con, card_id)
#             except Exception as e:
#                 self._set_response(400)
#                 self.wfile.write(json.dumps({"error":str(e)}).encode('utf-8'))
#                 return

#     def do_OPTIONS(self):
#         self._set_response(200)





# PORT=5000

# handler = MyHandler

# myServer = socketserver.TCPServer(("", PORT), handler)
