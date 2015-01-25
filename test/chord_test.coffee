chord_lib = require '../scripts/chord'


describe 'Test divmod', ->
  console.log chord_lib.divmod(5, 3)
  console.log chord_lib.divmod(-5, 3)


describe 'Test guitar tuning', ->
  for note in chord_lib.guitar.tuning
    console.log note.pitch


describe 'Test note from name', ->
  console.log chord_lib.Note.from_name('E3')
