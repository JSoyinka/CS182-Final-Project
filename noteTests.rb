# Tests
# Testing Note
require_relative "./note.rb"
require "minitest/autorun"
require "minitest/reporters"

reporter_options = { color: true }
Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new(reporter_options)]

class TestNote < MiniTest::Unit::TestCase
	def setup
		@c4 = Note.new("C4")
		@d3 = Note.new("D3")
		@a4 = Note.new("A4")
		@otherc4 = Note.new("C4")
	end

	def test_badnote
		assert_raises ArgumentError do
			Note.new("H2")
		end
	end

	def test_note_comparison
		refute(@d3 < @d3)
		assert(@c4 == @c4)
		refute(@a4 > @a4)
		assert(@d3 < @c4)
		refute(@d3 == @a4)
		refute(@a4 < @c4)
		refute(@c4 < @d3)
		refute(@a4 == @d3)
		assert(@c4 < @a4)
		assert(@c4 == @otherc4)
	end

	def test_midiValue
		assert(@c4.midiValue == 48 + 12)
		assert(@d3.midiValue == 38 + 12)
		assert(@a4.midiValue == 57 + 12)
	end

	def test_succ
		csharp4 = @c4.succ
		assert(csharp4.to_s == "C#4")
	end

	def test_range
		notes = []
		(@d3..@a4).each do |note|
			notes << note.to_s
		end
		expected = ["D3","D#3","E3","F3","F#3","G3","G#3","A3","A#3","B3","C4","C#4","D4","D#4","E4","F4","F#4","G4","G#4","A4"]
		assert(notes == expected)
	end

	def test_in_triad
		notes = [
			Note.new("C4"),
			Note.new("D4"),
			Note.new("E4"),
			Note.new("F4"),
			Note.new("G4"),
			Note.new("A4"),
			Note.new("B4")
		]
		assert(notes[0].in_triad?("C", 1))
		assert(notes[2].in_triad?("C", 1))
		assert(notes[4].in_triad?("C", 1))
		assert(@c4.in_triad?("C", 4))
		assert(@c4.in_triad?("C", 6))
		refute(@c4.in_triad?("C", 5))
		b4 = Note.new("B4")
		assert(b4.in_triad?("C", 7))
		assert(b4.in_triad?("C", 3))
		assert(b4.in_triad?("C", 5))
		assert(b4.in_triad?("B", 1))

		# Possible failure points:
		# key + chordtype is greater than 8.

		assert(Note.new("C#5").in_triad?("A", 6))
		assert(Note.new("A4").in_triad?("A", 6))
		assert(Note.new("F#2").in_triad?("A", 6))
	end
end