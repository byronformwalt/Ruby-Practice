#!/usr/bin/env ruby

# First find out the number 1's in the binary digit of a given integer. Then find out an integer which is greater than the given integer and contains same number of binary 1's

#ref: http://www.careercup.com/question?id=4981417205301248

module DigitMagic
  def magic_shift
    s = self.to_s(2)
    # Find the right most "1" that can shift left one position onto a "0"
    a = s.reverse.split("") << "0"
    j = 0
    i = a.find_index do |v|
      j += 1
      v == "1" && a[j] == "0"
    end
    a[i] = "0"
    a[i+1] = "1"
    a.pop if a[-1] == "0"
    s2 = a.join.reverse
    x2 = s2.to_i(2)
    puts "x = #{self} ==> #{s}b; x = #{x2} ==> #{s2}b\n"
  end
end

class Fixnum
  include DigitMagic
end

class Bignum
  include DigitMagic
end

x = [380,3,24,513]
x.each{|v| v.magic_shift}


        
      

