require 'rubygems'


def gem_paths(spec)
  spec.require_paths.collect { |d|
    File.join(spec.full_gem_path,d)
  }
end 

p = (gem_paths(Gem::GemPathSearcher.new.find("sipper")))[0]
p.slice!(/\/sipper$/)

File.open("sh.txt", "w+") do |f|
  f.write(p)
end
