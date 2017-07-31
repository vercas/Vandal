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

if vandal.log then error "wut?" end

function vandal.log(lvl, ...)
    if (vandal.log_level or 0) < lvl then
        return
    end

    local stream = io.stdout

    if lvl <= 0 then
        stream = io.stderr
    end

    --  TODO: More sensible stream selection, perhaps to show log output to the user itself.

    stream:write(os.date("[%Y-%m-%d %H:%M:%S] ", os.time()))

    local items = {...}

    for i = 1, #items do
        stream:write(tostring(items[i]))
    end

    stream:write "\n"
    stream:flush()
end

function MSG(...)
    return vandal.log(3, ...)
end

function INF(...)
    return vandal.log(2, ...)
end

function WRN(...)
    return vandal.log(1, ...)
end

function ERR(...)
    return vandal.log(0, ...)
end

