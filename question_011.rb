#!/usr/bin/env ruby

#Remove common characters from two strings and print the common characters and test cases

require 'set'

s1 = "alkdflkj"
s2 = "hello world"

s1 = s1.split("")
s2 = s2.split("")
c1 = Set.new(s1)
c2 = Set.new(s2)

c3 = c1.intersection(c2)
s3 = c3.to_a
s1 = (s1 - s3).join
s2 = (s2 - s3).join
s3 = s3.join

p s1
p s2
p s3
