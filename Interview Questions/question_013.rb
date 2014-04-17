#!/usr/bin/env ruby


# Write code to search and return all those file names present in a given directory 
# (for e.g. C:\>) where the string "Amazon" is present. All the files will be located 
# at different folder levels. Also discuss your approach, time and space complexities 
# for your solution.
#
# ref: http://www.careercup.com/page?pid=software-engineer-in-test-interview-questions

# I interpret this to mean "Recursively find all files and directories containing a 
# particular case sensitive substring in their names."

def find_files(fdir,name,options = {})
  a = []
  defaults = {case_sensitive: true, ignore_hidden: true}.freeze
  options = defaults.merge(options)
  Dir.entries(fdir).each do |e|
    next if defaults[:ignore_hidden] && e =~ /^\..*?/
    f = fdir + File::SEPARATOR + e
    m = options[:case_sensitive] ? (e =~ /.*?(#{name}).*?/) : (e =~ /.*?(#{name}).*?/i)
    if m
      a << f 
    end
    if File.directory?(f) && !(f =~ /\.{1,2}/)
      a += find_files(f,name,options)
      next
    end
  end
  a
end


fdir = ENV["HOME"]

p find_files(fdir,"mp4",case_sensitive: true)

