#!/usr/bin/env ruby

# Given 2 arrays wrds[] , chars[] as an input to a function such that 
# wrds[] = [ "abc" , "baa" , "caan" , "an" , "banc" ] 
# chars[] = [ "a" , "a" , "n" , "c" , "b"] 
# Function should return the longest word from words[] which can be constructed from the chars in chars[] array. 
# for above example - "caan" , "banc" should be returned 

# Note: Once a character in chars[] array is used, it cant be used again. 
# eg: words[] = [ "aat" ] 
# characters[] = [ "a" , "t" ] 
# then word "aat" can't be constructed, since we've only 1 "a" in chars[].

# ref: http://www.careercup.com/page?pid=software-engineer-in-test-interview-questions

def longest_word(wrds,chars)
  
  wrds = wrds.keep_if do |w|
    (w.split("") - chars).empty?
  end
  
  n = wrds.collect{|w| w.length}.max
  wrds = wrds.keep_if do |w|
    w.length == n
  end
end

wrds = [ "abc" , "baa" , "caan" , "an" , "banc" ] 
chars = [ "a" , "a" , "n" , "c" , "b"]

p longest_word(wrds,chars)