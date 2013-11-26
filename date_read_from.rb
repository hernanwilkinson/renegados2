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

    pattern_stream = StringIO.new pattern
    while !pattern_stream.eof?
      if input_stream.eof?
        return nil
      end
      char = pattern_stream.getc
      if char == '\\'
        return nil if input_stream.getc != pattern_stream.getc
      else
        if char == 'y'
          if pattern_stream.next_match 'yyy'
            year = input_stream.read(4).to_i
          else
            if pattern_stream.next_match 'y'
              year = input_stream.read(2).to_i
            else
              year = input_stream.next_to_i
            end
          end
        else
          if char == 'm'
            if pattern_stream.next_match 'm'
              month = input_stream.read(2).to_i
            else
              month = input_stream.next_to_i
            end
          else
            if char == 'd'
              if pattern_stream.next_match 'd'
                day = input_stream.read(2).to_i
              else
                day = input_stream.next_to_i
              end
            else
              return nil unless input_stream.getc == char
            end
          end
        end
      end
    end

    if year.nil? || month.nil? || day.nil?
      return nil
    end

    return Date.new(year,month,day)

  end
end

