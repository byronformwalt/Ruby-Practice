#!/usr/bin/env ruby

#Print the actual phone number when given an alphanumeric phone number. 
#For e.g. an input of 1-800-COM-CAST should give output as 18002662278 
#(note: output also does not contain any special characters like "-").

class String
  def alphanum_to_num
    @pad ||= 
    begin
      pad = Hash.new("")
      groups = ["+","","ABC","DEF","GHI","JKL","MNO","PQRS","TUV","WXYZ"]
      groups.each_with_index do |g,i|
        a = g.split("")
        a.each do |k|
          pad[k] = i
        end
      end
      (0..9).each{|v| pad[v.to_s] = v}
      pad["-"] = ""
      pad
    end
    
    s = self.split("-").join.split("")
    s.collect{|v| @pad[v.upcase]}.join
  end
end

numbers = ["1-800-COM-CAST","1-800-comcast","321-fiddley","a really stupid number"]

numbers.each do |n|
  puts "#{n} -> #{n.alphanum_to_num}"
end

