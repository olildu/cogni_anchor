from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List
import psycopg2
import numpy as np

app = FastAPI()

# ---- DATABASE CONNECTION ----
def get_conn():
    return psycopg2.connect(
        host="localhost",
        port="5433",  # IMPORTANT: your database runs on 5433 now
        database="face_db",
        user="postgres",
        password="Gettowork123#"
    )

# ---- DATA MODELS ----
class EnrollRequest(BaseModel):
    name: str
    relationship: str
    occupation: str
    age: str
    notes: str
    embedding: List[float]  # length 192


class SearchRequest(BaseModel):
    embedding: List[float]


# ---- ENROLL API ----
@app.post("/api/v1/faces/enroll")
def enroll_person(data: EnrollRequest):
    emb = np.array(data.embedding, dtype=float)

    if emb.shape[0] != 192:
        raise HTTPException(status_code=400, detail="Embedding must be 192 dimensions")

    try:
        conn = get_conn()
        cur = conn.cursor()

        sql = """
        INSERT INTO persons (name, relationship, occupation, age, notes, embedding)
        VALUES (%s, %s, %s, %s, %s, %s)
        RETURNING id;
        """

        cur.execute(sql, (
            data.name,
            data.relationship,
            data.occupation,
            data.age,
            data.notes,
            emb.tolist()
        ))

        conn.commit()
        cur.close()
        conn.close()

        return {"success": True, "message": "Person enrolled"}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ---- SEARCH API ----
@app.post("/api/v1/faces/recognize")
def recognize_face(data: SearchRequest):
    emb = np.array(data.embedding, dtype=float)

    if emb.shape[0] != 192:
        raise HTTPException(status_code=400, detail="Embedding must be 192 dimensions")

    try:
        conn = get_conn()
        cur = conn.cursor()

        # pgvector: distance search
        sql = """
        SELECT id, name, relationship, occupation, age, notes,
               (embedding <-> %s) AS distance
        FROM persons
        ORDER BY distance ASC
        LIMIT 1;
        """

        cur.execute(sql, (emb.tolist(),))
        row = cur.fetchone()

        cur.close()
        conn.close()

        if row is None:
            return {"match_found": False}

        person_id, name, relationship, occupation, age, notes, distance = row

        # Distance threshold tuning
        # Lower distance = better match
        MATCH_THRESHOLD = 0.75

        if distance > MATCH_THRESHOLD:
            return {"match_found": False}

        return {
            "match_found": True,
            "person_name": name,
            "relationship": relationship,
            "occupation": occupation,
            "age": age,
            "notes": notes
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
