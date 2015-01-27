chord_lib = require '../scripts/chord'
assert = require 'assert'


describe 'utils', ->
  it 'divmod', ->
    assert.deepEqual(chord_lib.utils.divmod(5, 3), [1, 2])
    assert.deepEqual(chord_lib.utils.divmod(-5, 3), [-2, 1])

  it 'sum', ->
    assert.equal(chord_lib.utils.sum([1, 2, 3]), 6)
    assert.equal(chord_lib.utils.sum([1]), 1)
    assert.equal(chord_lib.utils.sum([]), 0)


describe 'note_from_name', ->
  it 'E3', ->
    note = chord_lib.Note.from_name('E3')
    assert.equal(note.pitch, 40)
    assert.equal(note.name, 'E')
    assert.equal(note.alter, 0)
    assert.equal(note.group, 3)


describe 'chord', ->
  it 'chord_from_name', ->
    assert.deepEqual(chord_lib.Chord.from_name('C').pitch_indices, [0, 4, 7])
    assert.deepEqual(chord_lib.Chord.from_name('D').pitch_indices, [2, 6, 9])
    assert.deepEqual(chord_lib.Chord.from_name('G').pitch_indices, [7, 11, 2])
    assert.deepEqual(chord_lib.Chord.from_name('Dm').pitch_indices, [2, 5, 9])
    assert.deepEqual(chord_lib.Chord.from_name('D+').pitch_indices, [2, 6, 10])
    assert.deepEqual(chord_lib.Chord.from_name('D-').pitch_indices, [2, 5, 8])
    assert.deepEqual(chord_lib.Chord.from_name('C7').pitch_indices, [0, 4, 7, 10])
    assert.deepEqual(chord_lib.Chord.from_name('CM7').pitch_indices, [0, 4, 7, 11])
    assert.deepEqual(chord_lib.Chord.from_name('C-d7').pitch_indices, [0, 3, 6, 9])


describe 'gen_chords', ->
  console.log (c.note_positions for c in chord_lib.gen_chords('C')[0])


describe 'test_tuning', ->
  it 'guitar', ->
    notes = chord_lib.guitar.tuning
    pitch_distances = (notes[i].pitch - notes[i - 1].pitch for i in [1..5])
    assert.deepEqual(pitch_distances, [-5, -4, -5, -5, -5])

  it 'ukulele', ->
    notes = chord_lib.ukulele.tuning
    pitch_distances = (notes[i].pitch - notes[i - 1].pitch for i in [1..3])
    assert.deepEqual(pitch_distances, [-5, -4, 7])
