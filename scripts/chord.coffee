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

  get_note: (string, fret) ->
    pitch = @get_pitch(string, fret)
    note = Note.from_pitch(pitch)


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
  constructor: (@chord, @instrument, @note_positions) ->

  is_covered_by: (other) ->
    a = {}
    for p in other.note_positions
      a[p.string] = p.fret
    for p in @note_positions
      if not a[p.string]? or a[p.string] != p.fret
        return false
    return true


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
  instrument: 'guitar'

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
  for key, value of default_gen_chords_config
    config[key] = config[key] ? value

  inst = (
    inst for inst in instruments when config.instrument.toLowerCase() == inst.name.toLowerCase())[0]
  results = []

  used_pitches = (0 for _ in [1..chord.pitch_indices.length])

  all_pitches_used = () ->
    for c in used_pitches
      if c == 0
        return false
    return true

  is_covered = (result) ->
    for other in results
      if result.is_covered_by(other)
        return true
    return false

  search = (string, note_positions) ->
    if string == inst.n_strings
      result = new ChordOnInstrument(chord, inst, note_positions.slice())
      if all_pitches_used()
        if not is_covered(result)
          results.push(result)
      return
    min_fret = config.min_fret
    for p in note_positions
      if p.fret > 0 and p.fret < min_fret
        min_fret = p.fret

    if note_positions.length > 0
      max_fret = Math.min(inst.n_frets, min_fret + config.max_span)
    else
      max_fret = inst.n_frets
    # Use this string
    fret_trails = [min_fret..max_fret]
    if min_fret > 0 and config.allow_empty_string
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
  return results


default_render_metric = 
  color: '#000000'
  string_width: 3
  string_distance: 16
  fret_width: 3
  fret_distance: 30
  margin_h: 10
  margin_v: 20
  label_margin_h: 15
  label_margin_v: 20
  note_radius: 6
  fontSize: 11
  fontFamily: 'arial'
  min_span: 3


render_chord = (chord_on_instrument, raphael, container, metric={}) ->
  # metric = {
  #   color: '#0c0c0c'
  #   string_width
  #   string_distance
  #   fret_width
  #   fret_distance
  #   margin_h
  #   margin_v
  #   label_margin_v
  #   label_margin_h
  #   note_radius
  #   fontSize
  #   fontFamily
  # }
  for name, value of default_render_metric
    metric[name] = metric[name] ? value

  ci = chord_on_instrument
  inst = ci.instrument
  frets = (p.fret for p in ci.note_positions)
  # Math.min([]) = 0
  min_fret_display = Math.min(frets...)
  min_fret = Math.min(frets...)
  max_fret = Math.max(frets...)
  max_fret_display = Math.max(max_fret, min_fret_display + 3)
  n_frets_display = max_fret_display - min_fret_display + 1
  width = (metric.margin_h \
    + metric.string_distance * (inst.n_strings - 1) \
    + metric.label_margin_h + metric.margin_h)
  height = (metric.margin_v + metric.label_margin_v \
    + metric.fret_distance * (n_frets_display - 1) \
    + metric.margin_v)
  paper = raphael container, width, height
  x0 = metric.margin_h
  y0 = metric.margin_v + metric.label_margin_v
  # Render strings
  get_string_path = () ->
    x = x0
    y = y0
    path = []
    h = (n_frets_display - 1) * metric.fret_distance
    for i in [1..inst.n_strings]
      path.push ['M', x, y]
      path.push ['L', x, y + h]
      x += metric.string_distance
    path

  get_frets_path = () ->
    x = x0
    y = y0
    w = (inst.n_strings - 1) * metric.string_distance
    path = []
    for i in [1..n_frets_display]
      path.push ['M', x, y]
      path.push ['L', x + w, y]
      y += metric.fret_distance
    path

  get_string_x = (string) ->
    x0 + (inst.n_strings - 1 - string) * metric.string_distance

  get_notes = () ->
    notes = paper.set()
    for p in ci.note_positions
      x = get_string_x(p.string)
      y = y0 + (p.fret - min_fret_display - 0.5) * metric.fret_distance
      if y > y0
        notes.push paper.circle(x, y, metric.note_radius)
    notes.attr
      fill: metric.color

  put_top_label = (string, label) ->
    paper.text(
      get_string_x(string),
      y0 - metric.label_margin_v,
      label
    )

  get_labels = () ->
    labels = paper.set()
    string_used = (false for _ in [1..inst.n_strings])
    for p in ci.note_positions
      string_used[p.string] = true
      labels.push put_top_label(p.string, inst.get_note(p.string, p.fret).toString()) 
    for string in [0..inst.n_strings - 1]
      if not string_used[string]
        labels.push put_top_label(string, 'x')
    if min_fret_display > 1
      labels.push paper.text(
        x0 + (inst.n_strings - 1) * metric.string_distance + metric.label_margin_h,
        y0 + metric.fret_distance * 0.5,
        min_fret_display.toString()
      )
    labels.attr
      'font-family': metric.fontFamily
      'font-size': metric.fontSize

  strings = paper.path(get_string_path()).attr
    fill: metric.color
    width: metric.string_width
  # Render frets
  fret_bars = paper.path(get_frets_path()).attr
    fill: metric.color
    width: metric.fret_width
  # Render notes
  notes = get_notes()
  # Render labels
  labels = get_labels()

  all = paper.set()
  all.push strings, fret_bars, notes, labels


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
root.render_chord = render_chord
