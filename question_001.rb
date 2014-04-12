#!/usr/bin/env ruby

example = "Mircrosoft"

class String
  
  def <<(n)
    self.split("").rotate(-n).join
  end
  
  def >>(n)
    self.split("").rotate(n).join
  end
  
end

print "\"#{example}\" << 2 results in #{example << 2}\n"
print "\"#{example}\" >> 2 results in #{example >> 2}\n"
