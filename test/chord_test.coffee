chord_lib = require '../scripts/chord'
assert = require 'assert'


describe 'divmod', ->
  it 'divmod', ->
    assert.deepEqual(chord_lib.divmod(5, 3), [1, 2])
    assert.deepEqual(chord_lib.divmod(-5, 3), [-2, 1])


describe 'note_from_name', ->
  it 'E3', ->
    note = chord_lib.Note.from_name('E3')
    assert.equal(note.pitch, 40)
    assert.equal(note.name, 'E')
    assert.equal(note.alter, 0)
    assert.equal(note.group, 3)


describe 'test_tuning', ->
  it 'guitar', ->
    notes = chord_lib.guitar.tuning
    pitch_distances = (notes[i].pitch - notes[i - 1].pitch for i in [1..5])
    assert.deepEqual(pitch_distances, [-5, -4, -5, -5, -5])

  it 'ukulele', ->
    notes = chord_lib.ukulele.tuning
    pitch_distances = (notes[i].pitch - notes[i - 1].pitch for i in [1..3])
    assert.deepEqual(pitch_distances, [-5, -4, 7])
