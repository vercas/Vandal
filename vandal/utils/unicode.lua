--[[
    Copyright (c) 2017 Alexandru-Mihai Maftei. All rights reserved.


    Developed by: Alexandru-Mihai Maftei
    aka Vercas
    http://vercas.com | https://github.com/vercas/Vandal

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to
    deal with the Software without restriction, including without limitation the
    rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
    sell copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

      * Redistributions of source code must retain the above copyright notice,
        this list of conditions and the following disclaimers.
      * Redistributions in binary form must reproduce the above copyright
        notice, this list of conditions and the following disclaimers in the
        documentation and/or other materials provided with the distribution.
      * Neither the names of Alexandru-Mihai Maftei, Vercas, nor the names of
        its contributors may be used to endorse or promote products derived from
        this Software without specific prior written permission.


    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    CONTRIBUTORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    WITH THE SOFTWARE.

    ---

    You may also find the text of this license in "LICENSE.md".
]]

local types = require "vandal/utils/types"

if not vandal.utils.unicode then vandal.utils.unicode = { } end
local unicode = vandal.utils.unicode

function unicode.alternatives(a, b)
    if type(a) ~= "string" then
        error("Vandal error: Unicode alternative must be a string.")
    end

    if b ~= nil then
        if type(b) ~= "string" then
            error("Vandal error: Non-unicode alternative must be a string.")
        end

        if vandal.utf8 then
            _G.UNIC = unicode.alternative_1

            return a
        else
            _G.UNIC = unicode.alternative_2

            return b
        end
    else
        --  Means both alternatives are in the main string.

        local sep = a:find("|", 1, true)

        if not sep then
            error("Vandal error: Unicode alternative must contain a '|' to separate the unicode-enabled string on the left from the non-unicode string on the right. Alternatively, call the function with two arguments.")
        end

        if vandal.utf8 then
            _G.UNIC = unicode.alternative_1

            return a:sub(1, sep - 1)
        else
            _G.UNIC = unicode.alternative_2

            return a:sub(sep + 1)
        end
    end
end
_G.UNIC = unicode.alternatives

function unicode.alternative_1(a, b)
    if type(a) ~= "string" then
        error("Vandal error: Unicode alternative must be a string.")
    end

    if b ~= nil then
        if type(b) ~= "string" then
            error("Vandal error: Non-unicode alternative must be a string.")
        end

        return a
    else
        local sep = a:find("|", 1, true)

        if not sep then
            error("Vandal error: Unicode alternative must contain a '|' to separate the unicode-enabled string on the left from the non-unicode string on the right. Alternatively, call the function with two arguments.")
        end

        return a:sub(1, sep - 1)
    end
end

function unicode.alternative_2(a, b)
    if type(a) ~= "string" then
        error("Vandal error: Unicode alternative must be a string.")
    end

    if b ~= nil then
        if type(b) ~= "string" then
            error("Vandal error: Non-unicode alternative must be a string.")
        end

        return b
    else
        local sep = a:find("|", 1, true)

        if not sep then
            error("Vandal error: Unicode alternative must contain a '|' to separate the unicode-enabled string on the left from the non-unicode string on the right. Alternatively, call the function with two arguments.")
        end

        return a:sub(sep + 1)
    end
end

return unicode

