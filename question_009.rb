#!/usr/bin/env ruby

#Assume: 0 <= n < 1000000000
#1 -> "1"
#10 -> "10"
#100 -> "100"
#1000 -> "1,000"
#10000 -> "10,000"
#100000 -> "100,000"
#1000000 -> "1,000,000"
#35235235 -> "35,235,235"


class Fixnum
  include Math
  def to_s_commas
    x = self
    n = (log10(x)/3.0).floor
    s = ""
    if n > 0
      1.upto(n) do |i|
        x = x/1000
        a = (x - x.floor)*1000
        s << sprintf("%03i",a).reverse << ","
        x = x.floor
      end
      s << x.to_s.reverse if x > 0
      s = s.reverse
    else
      s = x.to_s
    end
    s
  end
end

x = [1,10,100,1000,10000,100000,1000000,35235235]
x.each do |v|
  puts "#{v} -> \"#{v.to_s_commas}\""
end

