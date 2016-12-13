require_relative "./fuxProblem.rb"

key = ARGV[1]
input_sequence = ARGV[2..-1].map(&:to_i)
LEN_INPUT = input_sequence.length
testlol = FuxProblem.new(input_sequence, key)
# puts testlol.vars
# puts testlol.constraints
if ARGV[0].include? "b"
	d = testlol.backtrack
elsif ARGV[0].include? "m"
	d = testlol.min_conflicts(true)
elsif ARGV[0].include? "r"
	d = testlol.min_conflicts(false)
end
# puts d
chordList = []
0.upto(LEN_INPUT - 1) { |x| chordList << d[x] }
0.upto(LEN_INPUT - 1) { |x| puts "#{chordList[x].map(&:to_s)}" }

require 'midilib/sequence'
require 'midilib/consts'
include MIDI

seq = Sequence.new()

# Create a first track for the sequence. This holds tempo events and stuff
# like that.
track = Track.new(seq)
seq.tracks << track
track.events << Tempo.new(Tempo.bpm_to_mpq(120))
track.events << MetaEvent.new(META_SEQ_NAME, 'Sequence Name')

# Create a track to hold the notes. Add it to the sequence.
track = Track.new(seq)
seq.tracks << track

# Give the track a name and an instrument name (optional).
track.name = 'My New Track'
# puts GM_PATCH_NAMES[52]
track.instrument = GM_PATCH_NAMES[52]

# Add a volume controller event (optional).
track.events << Controller.new(0, CC_VOLUME, 127)

# Arguments for note on and note off
# constructors are channel, note, velocity, and delta_time. Channel numbers
# start at zero. We use the new Sequence#note_to_delta method to get the
# delta time length of a single quarter note.
track.events << ProgramChange.new(0, 1, 0)
quarter_note_length = seq.note_to_delta('quarter')
chordList.each do |chord|
	chord.each do |note|
		track.events << NoteOn.new(0, note.midiValue, 127, 0)
	end
	length_of_time = quarter_note_length * 2
	chord.each do |note|
		track.events << NoteOff.new(0, note.midiValue, 127, length_of_time)
		length_of_time = 0
	end
end

# Calling recalc_times is not necessary, because that only sets the events'
# start times, which are not written out to the MIDI file. The delta times are
# what get written out.

# track.recalc_times

File.open('real_results.mid', 'wb') { |file| seq.write(file) }