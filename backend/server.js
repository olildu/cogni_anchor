import express from "express";
import multer from "multer";
import bodyParser from "body-parser";
import cors from "cors";
import dotenv from "dotenv";
import { supabase } from "./supabaseClient.js";

dotenv.config();

const app = express();
const upload = multer();

app.use(cors());
app.use(bodyParser.json({ limit: "20mb" }));

// Upload image to Supabase Storage
async function uploadImage(pair_id, file) {
  const filePath = `${pair_id}/${Date.now()}_${file.originalname}`;
  const { data, error } = await supabase.storage
    .from("face-images")
    .upload(filePath, file.buffer, {
      contentType: file.mimetype,
    });

  if (error) throw error;

  const { data: urlData } = supabase.storage
    .from("face-images")
    .getPublicUrl(filePath);

  return urlData.publicUrl;
}

// ⭐ ADD PERSON
app.post("/api/addPerson", upload.single("image"), async (req, res) => {
  try {
    const { pair_id, name, relationship, occupation, age, notes, embedding } =
      req.body;

    if (!req.file) {
      return res.status(400).json({ error: "Image file is required" });
    }

    const imageUrl = await uploadImage(pair_id, req.file);

    const { data: person, error: personError } = await supabase
      .from("people")
      .insert([
        {
          pair_id,
          name,
          relationship,
          occupation,
          age: age ? Number(age) : null,
          notes,
          image_url: imageUrl,
        },
      ])
      .select()
      .single();

    if (personError) throw personError;

    if (embedding) {
      const parsedEmbedding = JSON.parse(embedding);
      await supabase.from("face_embeddings").insert([
        {
          person_id: person.id,
          embedding: parsedEmbedding,
        },
      ]);
    }

    res.json({ ok: true, person });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// ⭐ GET PEOPLE
app.get("/api/getPeople", async (req, res) => {
  try {
    const { pair_id } = req.query;

    const { data, error } = await supabase
      .from("people")
      .select("*, face_embeddings(embedding)")
      .eq("pair_id", pair_id);

    if (error) throw error;

    res.json({ ok: true, people: data });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ⭐ SCAN PERSON
app.post("/api/scan", async (req, res) => {
  try {
    const { pair_id, embedding } = req.body;

    const { data: people } = await supabase
      .from("people")
      .select(
        "id, name, relationship, occupation, age, notes, image_url, face_embeddings(embedding)"
      )
      .eq("pair_id", pair_id);

    function cosine(a, b) {
      const dot = a.reduce((sum, v, i) => sum + v * b[i], 0);
      const magA = Math.sqrt(a.reduce((s, v) => s + v * v, 0));
      const magB = Math.sqrt(b.reduce((s, v) => s + v * v, 0));
      return dot / (magA * magB + 1e-9);
    }

    let best = { score: -1, person: null };

    for (const p of people) {
      for (const fe of p.face_embeddings) {
        const score = cosine(embedding, fe.embedding);
        if (score > best.score) {
          best = { score, person: p };
        }
      }
    }

    if (best.score < 0.6) {
      return res.json({ matched: false });
    }

    res.json({ matched: true, score: best.score, person: best.person });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// ⭐⭐⭐⭐ EDIT PERSON (UPDATE) — PUT /api/updatePerson
app.put("/api/updatePerson", upload.single("image"), async (req, res) => {
  try {
    const { person_id, name, relationship, occupation, age, notes } = req.body;

    let newImageUrl = null;

    // If new image uploaded → upload to Storage
    if (req.file) {
      const { data: person } = await supabase
        .from("people")
        .select("pair_id")
        .eq("id", person_id)
        .single();

      if (!person) throw new Error("Person not found");

      newImageUrl = await uploadImage(person.pair_id, req.file);

      await supabase
        .from("people")
        .update({ image_url: newImageUrl })
        .eq("id", person_id);
    }

    // Update text fields
    const { error } = await supabase
      .from("people")
      .update({
        name,
        relationship,
        occupation,
        age: age ? Number(age) : null,
        notes,
      })
      .eq("id", person_id);

    if (error) throw error;

    res.json({
      ok: true,
      image_url: newImageUrl,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});


// ⭐⭐⭐⭐ DELETE PERSON — DELETE /api/deletePerson
app.delete("/api/deletePerson", async (req, res) => {
  try {
    const { person_id } = req.body;

    if (!person_id) return res.status(400).json({ error: "person_id required" });

    // Delete embeddings first
    await supabase.from("face_embeddings").delete().eq("person_id", person_id);

    // Delete person
    const { error } = await supabase
      .from("people")
      .delete()
      .eq("id", person_id);

    if (error) throw error;

    res.json({ ok: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});


// ⭐ START SERVER
app.listen(process.env.PORT, "0.0.0.0", () => {
  console.log("Backend running on port", process.env.PORT);
});
