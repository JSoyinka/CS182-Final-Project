require_relative "./FuxProblem.rb"
require "minitest/autorun"
require "minitest/reporters"

reporter_options = { color: true }
Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new(reporter_options)]

class TestFuxChords < MiniTest::Unit::TestCase
	def setup
		@chord = FuxChord.new("A", 6, :lol)
	end

	def test_voices_within_octavee
		cons = VoicesWithinOctave.new(@chord)
		newdomain = @chord.domain.clone
		@chord.domain.each { |x|
			@chord.assignment = x
			unless cons.satisfied?
				newdomain.delete(x)
			end
		}
		newdomain.each do |validChord|
			puts "#{validChord.map(&:to_s)}"
		end
	end
end