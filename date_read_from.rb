require 'test/unit'
require 'minitest/reporters'; MiniTest::Reporters.use!
require 'stringio'
require 'date'

class String
  def string_io
    StringIO.new self
  end
end

class StringIO

  def next_match(pattern)
    current_po = self.pos
    pattern.each_char do |char|
      if self.eof? || self.getc!=char
        self.pos= current_po
        return false
      end
    end

    return true
  end

  def next_to_i
    number_as_string = ''
    possible_digit = self.getc
    while !possible_digit.nil? && possible_digit.match(/\d/)
      number_as_string << possible_digit
      possible_digit = self.getc
    end
    self.ungetc possible_digit unless possible_digit.nil?
    number_as_string.to_i
  end

end

class Date
  def self.read_from(input_stream,pattern)
    (DateParser.new input_stream,pattern).value
  end

end

class DateParser
  #Read a Date from the stream based on the pattern which can include the tokens:
  #
  #y = A year with 1-n digits
  #yy = A year with 2 digits
  #yyyy = A year with 4 digits
  #m = A month with 1-n digits
  #mm = A month with 2 digits
  #d = A day with 1-n digits
  #dd = A day with 2 digits
  #
  #...and any other Strings in between. Representing $y, $m and $d is done using
  #\y, \m and \d and slash itself with \\. Simple example patterns:
  #
  #'yyyy-mm-dd'
  #'yyyymmdd'
  #'yy.mm.dd'
  #'y-m-d'
  #
  #A year given using only two decimals is considered to be >2000.

  def initialize(input_stream,pattern)
    @input_stream = input_stream
    @pattern_stream = StringIO.new pattern
  end

  def value
    @invalid_pattern = false
    parse_next_pattern while not_done_parsing

    return nil if invalid_pattern?
    create_date
  end

  private

  def create_date
    @year = @year + 2000 if @year < 100
    Date.new(@year, @month, @day)
  end

  def invalid_pattern?
    @year.nil? || @month.nil? || @day.nil?
  end

  def parse_next_pattern
    @char = @pattern_stream.getc
    return parse_scape if scape_char?
    return parse_year if year_pattern?
    return parse_month if month_pattern?
    return parse_day if day_pattern?
    parse_same_char
  end

  def day_pattern?
    @char == 'd'
  end

  def month_pattern?
    @char == 'm'
  end

  def year_pattern?
    @char == 'y'
  end

  def scape_char?
    @char == '\\'
  end

  def parse_scape
    @invalid_pattern = true if @input_stream.getc != @pattern_stream.getc
  end

  def parse_same_char
    @invalid_pattern = true unless @input_stream.getc == @char
  end

  def not_done_parsing
    !@pattern_stream.eof? && !@invalid_pattern && !@input_stream.eof?
  end

  def parse_day
    return parse_two_day_digit if two_day_digit?
    parse_many_day_digits

  end

  def two_day_digit?
    @pattern_stream.next_match 'd'
  end

  def parse_many_day_digits
    @day = @input_stream.next_to_i
  end

  def parse_two_day_digit
    @day = @input_stream.read(2).to_i
  end

  def parse_month
    return parse_two_digits_month if two_digits_month?
    parse_many_digits_month
  end

  def two_digits_month?
    @pattern_stream.next_match 'm'
  end

  def parse_many_digits_month
    @month = @input_stream.next_to_i
  end

  def parse_two_digits_month
    @month = @input_stream.read(2).to_i
  end

  def parse_year
    return parse_four_digits_year if four_digit_year?
    return parse_two_digits_year if two_digits_year?
    parse_many_digits_year
    end

  def two_digits_year?
    @pattern_stream.next_match 'y'
  end

  def four_digit_year?
    @pattern_stream.next_match 'yyy'
  end

  def parse_many_digits_year
    @year = @input_stream.next_to_i
  end

  def parse_two_digits_year
    @year = @input_stream.read(2).to_i
  end

  def parse_four_digits_year
    @year = @input_stream.read(4).to_i
  end
end

class DateReadFromTest < Test::Unit::TestCase
  def assert_reading_as_equals(date_as_string,pattern,year,month,day)
    self.assert_equal Date.new(year,month,day),(Date.read_from date_as_string.string_io,pattern)
  end
  def assert_reading_as_fails(date_as_string,pattern)
    self.assert_nil Date.read_from date_as_string.string_io,pattern
  end
  def test01_parse_yyyy_pattern_correctly
    self.assert_reading_as_equals '25-11-2013','dd-mm-yyyy', 2013,11,25
  end
  def test02_parse_yy_pattern_correctly
    self.assert_reading_as_equals '25-11-2013','dd-mm-yy', 2020,11,25
  end
  def test03_parse_y_pattern_correctly
    self.assert_reading_as_equals '25-11-2013','dd-mm-y', 2013,11,25
  end
  def test04_parse_m_pattern_correctly
    self.assert_reading_as_equals '25-1-2013','dd-m-y', 2013,1,25
  end
  def test05_parse_d_pattern_correctly
    self.assert_reading_as_equals '2-1-2013','d-m-y', 2013,1,2
  end
  def test06_two_digits_for_day_are_expected_when_using_dd_pattern
    self.assert_reading_as_fails '2-1-2013','dd-m-y'
  end
  def test07_two_digits_for_month_are_expected_when_using_mm_pattern
    self.assert_reading_as_fails '22-1-2013','dd-mm-y'
  end
  def test08_four_digits_for_year_are_expected_when_using_yyyy_pattern
    self.assert_reading_as_fails '2-11-12','yyyy-dd-mm'
  end
  def test09_can_parse_without_separators
    self.assert_reading_as_equals '02012013','ddmmyyyy', 2013,1,2
  end
  def test10_patterns_can_be_anywhere
    self.assert_reading_as_equals '2013-25-11','yyyy-dd-mm', 2013,11,25
    self.assert_reading_as_equals '2013-11-25','yyyy-mm-dd', 2013,11,25
    self.assert_reading_as_equals '11-2013-25','mm-yyyy-dd', 2013,11,25
    self.assert_reading_as_equals '25-2013-11','dd-yyyy-mm', 2013,11,25
    self.assert_reading_as_equals '11-25-2013','mm-dd-yyyy', 2013,11,25
  end
  def test11_non_digit_separators_can_be_used
    self.assert_reading_as_equals '2013.25.11','yyyy.dd.mm', 2013,11,25
  end
  def test11_more_than_one_char_can_be_used_as_separator
    self.assert_reading_as_equals '2013/-11/-25','yyyy/-mm/-dd', 2013,11,25
  end
  def test12_fails_when_date_stream_is_empty
    self.assert_reading_as_fails '','yyyy-dd-mm'
  end
  def test13_fails_when_pattern_is_empty
    self.assert_reading_as_fails '2013-11-25',''
  end
  def test15_fails_when_year_is_not_provided
    self.assert_reading_as_fails '11-25','mm-dd'
  end
  def test16_fails_when_month_is_not_provided
    self.assert_reading_as_fails '2013-25','yyyy-dd'
  end
  def test16_fails_when_day_is_not_provided
    self.assert_reading_as_fails '2013-11','yyyy-mm'
  end
  def test17_scapes_y_correctly
    self.assert_reading_as_equals 'y2013-11-25','\yyyyy-mm-dd',2013,11,25
  end
  def test18_scapes_m_correctly
    self.assert_reading_as_equals 'm2013-11-25','\myyyy-mm-dd',2013,11,25
  end
  def test19_scapes_d_correctly
    self.assert_reading_as_equals 'd2013-11-25','\dyyyy-mm-dd',2013,11,25
  end
  def test20_add_2000_to_year_when_year_has_two_digits
    self.assert_reading_as_equals '13.25.11','yy.dd.mm', 2013,11,25
  end
end
