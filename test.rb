require "rbignore"

RbIgnore.find(*ARGV) do |f|
    print f, "\n"
end
