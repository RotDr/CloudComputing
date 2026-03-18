from DataBase.DataBase import setup_database

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