#

# SPDX-License-Identifier: MIT-0
#
# Copyright (C) 2024 nekosanteam <1688092+nekosanteam@users.noreply.github.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

#

module RbIgnore
    class DirEntry
    end

    class Walk
        def initialize(base)
        end
    end

    class ParallelWalk
        def initialize(base)
        end
    end

    class ParallelWalkBuilder
        def initialize(base)
        end
    end

    class WalkBuilder
        def initialize(base)
            @ignores = []
            @ignore_error = true
        end

        def ignored(f)
            @ignores.any do |r|
                r.match(f)
            end
        end

        def find(*paths)
            block_given? or return each_for(__method__, *paths, ignore_error: @ignore_error)

            paths.map {|i| raise Errno::ENOENT, i unless File.exist?(i); i.dup }.each do |path|
                path = path.to_path if path.respond_to? :to_path
                ps = [path]
                while file = ps.shift do
                    catch (:prune) do
                        begin
                            s = File.lstat(file)
                        rescue Errno::ENOENT, Errno::EACCES, Errno::ENOTDIR, Errno::ELOOP, Errno::ENAMETOOLONG
                            raise unless ignore_error
                            next
                        end
                        if s.directory? then
                            yield file.dup + "/"
                            begin
                                fs = Dir.children(file)
                            rescue Errno::ENOENT, Errno::EACCES, Errno::ENOTDIR, Errno::ELOOP, Errno::ENAMETOOLONG
                                raise unless ignore_error
                                next
                            end
                            fs.sort!
                            fs.reverse_each {|f|
                                next if is_vcs_folder(f)
                                f = File.join(file, f)
                                ps.unshift(f)
                            }
                        else
                            yield file.dup
                        end
                    end
                end
            end
        end
    end

    VCS_FOLDER = Regexp.compile("^(\.svn|\.git|\.hg|\.mtn|CVS|_svn|_git|_MTN)$")

    def self.is_vcs_folder(f)
        if VCS_FOLDER === f then
            return true
        else
            return false
        end
    end

    def self.find(*paths, ignore_error: true)
        block_given? or return each_for(__method__, *paths, ignore_error: ignore_error)

        paths.map {|i| raise Errno::ENOENT, i unless File.exist?(i); i.dup }.each do |path|
            path = path.to_path if path.respond_to? :to_path
            ps = [path]
            while file = ps.shift do
                catch (:prune) do
                    begin
                        s = File.lstat(file)
                    rescue Errno::ENOENT, Errno::EACCES, Errno::ENOTDIR, Errno::ELOOP, Errno::ENAMETOOLONG
                        raise unless ignore_error
                        next
                    end
                    if s.directory? then
                        yield file.dup + "/"
                        begin
                            fs = Dir.children(file)
                        rescue Errno::ENOENT, Errno::EACCES, Errno::ENOTDIR, Errno::ELOOP, Errno::ENAMETOOLONG
                            raise unless ignore_error
                            next
                        end
                        fs.sort!
                        fs.reverse_each {|f|
                            next if is_vcs_folder(f)
                            f = File.join(file, f)
                            ps.unshift(f)
                        }
                    else
                        yield file.dup
                    end
                end
            end
        end
    end

    def self.prune
        throw :prune
    end
end

