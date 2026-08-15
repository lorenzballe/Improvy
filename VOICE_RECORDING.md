# Pocket Mode — recording the voice

Pocket Mode speaks every question out of `assets/audio/voice/`. A question is
two or three clips played back to back with a 110 ms gap: the degree, the key,
the answer note. **57 words** cover everything the trainer can ever say.

The current 45 files are complete — nothing the app can ask is silent today,
double flats included. This is here for re-recording them.

---

## What matters

The clips are heard **inside one sentence**, not one at a time. That makes
consistency between clips matter far more than the polish of any single one.
A word recorded closer to the microphone, or on another day, or in another
room, is heard as a jump in the middle of the question — which is exactly what
"the audio quality wasn't magic" sounds like.

So: **record all 57 in one continuous take**, one microphone position, one gain
setting, one sitting. Read the list below, leave about a second of silence
between words, don't stop to fix anything — if you fumble a word, pause, and
say it again cleanly; you can cut the bad one afterwards.

Then let the splitter cut it up:

```bash
dart tool/sync_voice_clips.dart --list          # the script, in order
dart tool/split_voice_take.dart take.wav all --dry-run
dart tool/split_voice_take.dart take.wav all --force
dart tool/sync_voice_clips.dart                 # regenerate the timing table
flutter test test/pocket_voice_test.dart
```

`--dry-run` prints what each slice would be named and how long it is. Check
that list before writing — if a word landed on the wrong name, everything after
it is wrong too.

You can also do it in three passes (`degrees`, `notes`, `spare`) if 57 words in
one breath is too much; just keep the microphone where it is between them.

**Format:** mono, 44.1 kHz, 16-bit PCM WAV — the same as the current files.
Nothing else needs doing: the splitter trims the silence, and the app plays the
clips at their own level.

**Don't** add trailing silence by hand. The app already inserts 110 ms between
words; extra silence baked into a file makes the phrase drag.

**Delivery:** flat and even, same tempo and same energy on every word. These
get concatenated, so a rushed "C" next to a drawn-out "flat thirteen" reads as
a stutter. It is a label being read, not a sentence being performed.

---

## The script

`*` marks a file that does not exist yet.

### Degrees — 22

| # | file | say |
|---|------|-----|
| 1 | `d_1.wav` | one |
| 2 | `d_b2.wav` | flat two |
| 3 | `d_2.wav` | two |
| 4 | `d_s2.wav` | sharp two |
| 5 | `d_b3.wav` | flat three |
| 6 | `d_3.wav` | three |
| 7 | `d_4.wav` | four |
| 8 | `d_s4.wav` | sharp four |
| 9 | `d_b5.wav` | flat five |
| 10 | `d_5.wav` | five |
| 11 | `d_s5.wav` | sharp five |
| 12 | `d_b6.wav` | flat six |
| 13 | `d_6.wav` | six |
| 14 | `d_b7.wav` | flat seven |
| 15 | `d_7.wav` | seven |
| 16 | `d_b9.wav` | flat nine |
| 17 | `d_9.wav` | nine |
| 18 | `d_s9.wav` | sharp nine |
| 19 | `d_11.wav` | eleven |
| 20 | `d_s11.wav` | sharp eleven |
| 21 | `d_b13.wav` | flat thirteen |
| 22 | `d_13.wav` | thirteen |

There is no `♭4`, `♯3`, `♯6`, `♯7`, `♭11` or `♯13` — the trainer never spells a
degree that way, so those words are never needed.

### Notes — 23, all reachable today

Every one of these is used as an answer, or as the key being announced.

| # | file | say |
|---|------|-----|
| 1 | `n_C.wav` | C |
| 2 | `n_Cb.wav` | C flat |
| 3 | `n_Cs.wav` | C sharp |
| 4 | `n_D.wav` | D |
| 5 | `n_Db.wav` | D flat |
| 6 | `n_Ds.wav` | D sharp |
| 7 | `n_E.wav` | E |
| 8 | `n_Eb.wav` | E flat |
| 9 | `n_Ebb.wav` | E double flat |
| 10 | `n_Es.wav` | E sharp |
| 11 | `n_F.wav` | F |
| 12 | `n_Fb.wav` | F flat |
| 13 | `n_Fs.wav` | F sharp |
| 14 | `n_G.wav` | G |
| 15 | `n_Gb.wav` | G flat |
| 16 | `n_Gs.wav` | G sharp |
| 17 | `n_A.wav` | A |
| 18 | `n_Ab.wav` | A flat |
| 19 | `n_As.wav` | A sharp |
| 20 | `n_B.wav` | B |
| 21 | `n_Bb.wav` | B flat |
| 22 | `n_Bbb.wav` | B double flat |
| 23 | `n_Bs.wav` | B sharp |

The two double flats are real questions, not theory:

- **E𝄫** is the ♭2 of D♭.
- **B𝄫** is the ♭2 of A♭, and the ♭6 / ♯5 of D♭.

### Notes — 12 spare

Nothing asks for these. They complete the seven-letters-by-five-accidentals
grid, so any spelling a future mode invents already has a voice.

| # | file | say |
|---|------|-----|
| 1 | `n_Cbb.wav` * | C double flat |
| 2 | `n_Css.wav` * | C double sharp |
| 3 | `n_Dbb.wav` * | D double flat |
| 4 | `n_Dss.wav` * | D double sharp |
| 5 | `n_Ess.wav` * | E double sharp |
| 6 | `n_Fbb.wav` * | F double flat |
| 7 | `n_Fss.wav` * | F double sharp |
| 8 | `n_Gbb.wav` * | G double flat |
| 9 | `n_Gss.wav` * | G double sharp |
| 10 | `n_Abb.wav` * | A double flat |
| 11 | `n_Ass.wav` * | A double sharp |
| 12 | `n_Bss.wav` * | B double sharp |

---

## Why the tools exist

`lib/services/voice_service.dart` holds `_ms`, the exact length of every clip.
Pocket Mode waits that long before saying the next word — it does not listen for
the audio to finish. Replace a file without updating the number and the voice
either talks over itself or leaves a hole.

`dart tool/sync_voice_clips.dart` rewrites `_ms` from the files, and
`test/pocket_voice_test.dart` fails if the two ever disagree, so this cannot be
forgotten quietly.
