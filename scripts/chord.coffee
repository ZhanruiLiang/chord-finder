# For the pitch number, we map C0 to 0, C#0 to 1, etc.
class Instrument
  constructor: (@name, @tuning) ->
    @n_strings = @tuning.length


_parse_alter = (alter) ->
  if alter in ['#', 'b']
    if alter == '#'
      1
    else if alter == 'b'
      -1
  else if alter in [0, -1, 1]
    alter
  else
    console.error 'Unknown alter', alter


OCTAVE = 'C D EF G A B'


_get_index_in_octave = (name, alter) ->
  OCTAVE.indexOf(name) + alter


divmod = (x, m) ->
  r = if x >= 0 then x % m else m - (-x) % m
  return [(x - r) / m, r]


class Note
  constructor: (@pitch, @name, @alter, @group) ->

  @from_pitch: (pitch, alter=1) ->
    [group, index] = divmod(pitch, 12)
    if OCTAVE[index] == ' '
      name = OCTAVE[index - alter]
    else
      name = OCTAVE[index]
      alter = 0
    new Note(pitch, name, alter, group)

  @from_name: (name) ->
    regex = /([A-G])([#b]?)([0-9]+)/
    matched = regex.exec(name)
    name = matched[1]
    alter = _parse_alter(matched[2])
    group = parseInt(matched[3])
    pitch = _get_index_in_octave(name, alter) + group * 12
    new Note(pitch, name, alter, group)

  toString: () ->
    @name + @group.toString()


guitar = new Instrument(
  'Guitar', ['E4', 'B4', 'G3', 'D3', 'A2', 'E2'].map(Note.from_name)
)

root = exports ? window
root.Instrument = Instrument
root.Note = Note
root.guitar = guitar
root.divmod = divmod
