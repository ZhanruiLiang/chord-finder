utils = 
  divmod: (x, m) ->
    r = if x >= 0 then x % m else m - (-x) % m
    return [(x - r) / m, r]

  sum: (xs) ->
    s = 0
    for x in xs
      s += x
    s

  compare: (a, b) ->
    if a < b then -1
    else if a == b then 0
    else 1


# For the pitch number, we map C0 to 0, C#0 to 1, etc.
class Instrument
  constructor: (@name, @tuning, @n_frets) ->
    @n_strings = @tuning.length

  get_pitch: (string, fret) ->
    @tuning[string].pitch + fret


class UnknownAlterError
  constructor: (@alter) ->


_parse_alter = (alter) ->
  if alter in ['#', 'b', '']
    if alter == '#'
      1
    else if alter == 'b'
      -1
    else
      0
  else if alter in [0, -1, 1]
    alter
  else
    throw new UnknownAlterError(alter)


OCTAVE = 'C D EF G A B'


_get_index_in_octave = (name, alter) ->
  OCTAVE.indexOf(name) + alter


_get_pitch_index_in_octave = (pitch) ->
  utils.divmod(pitch, 12)[1]


class Note
  constructor: (@pitch, @name, @alter, @group) ->

  @from_pitch: (pitch, alter=1) ->
    [group, index] = utils.divmod(pitch, 12)
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


class NotePosition
  constructor: (@string, @fret) ->


class ChordOnInstrument
  constructor: (@chord, @note_positions) ->


class UnknownChordError
  constructor: (@name) ->


class Chord
  constructor: (@name, @pitch_indices) ->

  @from_name: (name) ->
    #  TODO: add 5 and 9 support.
    regex = /([A-G][#b]?)([m+-]?)(7|M7|d7)?/
    matched = regex.exec(name)
    if not matched?
      throw new UnknownChordError(name)
    [root_name, type, special] = matched.slice(1, 4)
    root_index = (
      Note.from_name(root_name + '0').pitch - Note.from_name('C0').pitch)
    deltas = switch type
      when 'M', '' then [0, 4, 7]
      when 'm' then [0, 3, 7]
      when '+' then [0, 4, 8]
      when '-' then [0, 3, 6]
    switch special
      when '7' then deltas.push(10)
      when 'M7' then deltas.push(11)
      when 'd7' then deltas.push(9)

    return new Chord(name, ((root_index + i) % 12 for i in deltas))


default_gen_chords_config =
  min_fret: 0
  max_span: 4
  allow_empty_string: true
  instrument: 'Guitar'

# @param name: chord name.
# @param config: {
#   instrument: Instrument,
#   allow_empty_string: Bool,
#   min_fret: Number
#   max_span: Number
# }
# @return: ([ChordOnInstrument], [ChordOnInstrument]), results and partitial results
gen_chords = (name, config={}) ->
  chord = Chord.from_name(name)
  config.instrument ?= default_gen_chords_config.instrument
  config.allow_empty_string ?= default_gen_chords_config.instrument
  config.min_fret ?= default_gen_chords_config.min_fret
  config.max_span ?= default_gen_chords_config.max_span

  inst = (
    inst for inst in instruments when config.instrument.toLowerCase() == inst.name.toLowerCase())[0]
  results = []
  partitial_results = []

  used_pitches = (0 for _ in [1..chord.pitch_indices.length])

  all_used = () ->
    for c in used_pitches
      if c == 0
        return false
    return true

  search = (string, note_positions) ->
    if string == inst.n_strings
      result = new ChordOnInstrument(chord, note_positions.slice())
      if all_used()
        results.push(result)
      else
        partitial_results.push(result)
      return
    max_fret = Math.min(config.min_fret + config.max_span, inst.n_frets)
    # Use this string
    fret_trails = [config.min_fret..max_fret]
    if config.min_fret > 0 and config.allow_empty_string
      fret_trails.unshift(0)
    for fret in fret_trails
      pitch = inst.get_pitch(string, fret)
      pitch_index = _get_pitch_index_in_octave(pitch)
      index_in_used = chord.pitch_indices.indexOf(pitch_index)
      if index_in_used >= 0
        used_pitches[index_in_used] += 1
        note_positions.push(new NotePosition(string, fret))
        a = index_in_used
        search(string + 1, note_positions)
        b = index_in_used
        note_positions.pop()
        used_pitches[index_in_used] -= 1
    # Do not use this string
    search(string + 1, note_positions)

  search(0, [])
  sort_chords(results)
  sort_chords(partitial_results)
  return [results, partitial_results]


sort_chords = (chords_on_instrument) ->
  chords_on_instrument.sort (c1, c2) ->
    utils.compare(-c1.note_positions.length, -c2.note_positions.length)


guitar = new Instrument(
  'Guitar', ['E4', 'B3', 'G3', 'D3', 'A2', 'E2'].map(Note.from_name), 19
)

ukulele = new Instrument(
  'Ukulele', ['A4', 'E4', 'C4', 'G4'].map(Note.from_name), 12
)

instruments = [guitar, ukulele]

# Exports
root = exports ? window
root.utils = utils
root.Instrument = Instrument
root.Note = Note
root.Chord = Chord
root.gen_chords = gen_chords
root.guitar = guitar
root.ukulele = ukulele
