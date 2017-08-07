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

if table.shallowcopy then error "wut?" end

function table.shallowcopy(tab)
    local res = {}

    for k, v in pairs(tab) do
        res[k] = v
    end

    return res
end

function table.deepcopy(tab, refs)
    if refs and refs[tab] then return refs[tab] end

    local res = { }

    if refs then refs[tab] = res else refs = { [tab] = res } end

    for k, v in pairs(tab) do
        if type(k) == "table" then
            k = table.deepcopy(k, refs)
        end

        if type(v) == "table" then
            v = table.deepcopy(v, refs)
        end

        res[k] = v
    end

    return res
end

function table.copyarray(tab)
    local res, len = {}, #tab

    for i = 1, len do
        res[i] = tab[i]
    end

    return res
end

function table.isarray(tab)
    local len = #tab

    for k, v in pairs(tab) do
        if type(k) ~= "number" or k < 1 or k > len or k % 1 ~= 0 then
            return false
        end
    end

    return true
end

function table.tostring(t, indent)
    indent = indent or 0

    local res = {}
    local function append(val)
        res[#res + 1] = val
    end

    printTable(t, append, indent, { [_G] = true, [vandal] = true })

    return table.concat(res);
end

function table.multipairs(...)
    return function(state, last)
        if last == nil then
            state.i = state.i + 1

            if state.i > #state then
                return
            end

            return next(state[state.i])
        else
            return next(state[state.i], last)
        end
    end, {..., i = 0}, nil
end

do
    local validTrueStrings  = { TRUE  = true, YES = true, ON  = true }
    local validFalseStrings = { FALSE = true, NO  = true, OFF = true }

    function toboolean(val)
        local uVal = string.upper(val)

        if validTrueStrings[uVal] then
            return true
        elseif validFalseStrings[uVal] then
            return false
        end
    end
end

function string.trim(s)
    return s:match("^%s*(.-)%s*$")
end

function string.quotify(str)
    if string.find(str, "[%[%]%s\\\b'\";]") then
        return string.format("%q", str)
    end

    return str
end

function string.split(s, pattern, plain, n)
    --  Borrowed from https://github.com/stevedonovan/Penlight/blob/master/lua/pl/utils.lua#L172

    local i1, res = 1, {}

    if not pattern then pattern = plain and ' ' or "%s+" end
    if pattern == '' then return {s} end

    while true do
        local i2, i3 = s:find(pattern, i1, plain)

        if not i2 then
            local last = s:sub(i1)

            if last ~= '' then
                table.insert(res, last)
            end

            if #res == 1 and res[1] == '' then
                return {}
            else
                return res
            end
        else
            table.insert(res, s:sub(i1, i2 - 1))

            if n and #res == n then
                res[#res] = s:sub(i1)

                return res
            end

            i1 = i3 + 1
        end
    end
end

function string.iteratesplit(s, pattern, plain, n)
    local cnt, i1, i2, i3, res = 0, 1

    if not pattern then pattern = plain and ' ' or "%s+" end
    if pattern == '' then return {s} end

    return function()
        if not i1 then return end
        --  Means the end was reached.

        i2, i3 = s:find(pattern, i1, plain)

        if not i2 then
            local last = s:sub(i1)
            i1 = nil

            return last
        else
            cnt = cnt + 1

            if n and cnt == n then
                return s:sub(i1)
            end

            local res = s:sub(i1, i2 - 1)
            i1 = i3 + 1

            return res, s:sub(i2, i3)
        end
    end
end

local prefixes = { ["-"] = true, ["~"] = true, ["+"] = true }

function string.parsenumber(str)
    local num, prf, start = tonumber(str)
    if num then return num end

    prf = str:sub(1, 1)
    if prefixes[prf] then start = 2 else start = 1 prf = nil end

    if str:sub(start, start) ~= "0" or #str < start + 2 then
        return nil, "Unknown number parsing failure"
    end

    local typ = str:sub(start + 1, start + 1)
    num = 0

    if typ == "x" then
        num = tonumber(str:sub(start + 2), 16)
    elseif typ == "o" then
        for i = start + 2, #str do
            local d = str:sub(i, i):byte() - 48

            if d < 0 or d > 7 then
                return nil, "Octal digit out of range at position " .. i
            end

            num = bit.bor(bit.lshift(num, 3), d)
        end
    elseif typ == "b" then
        for i = start + 2, #str do
            local d = str:sub(i, i):byte() - 48
            num = bit.lshift(num, 1)

            if d == 1 then
                num = bit.bor(num, 1)
            elseif d ~= 0 then
                return nil, "Binary digit out of range at position " .. i
            end
        end
    else
        return nil, "Unknown number base prefix"
    end

    if prf == "-" then
        return -num
    elseif prf == "~" then
        return bit.bnot(num)
    end

    return num
end

function math.clamp(min, val, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

