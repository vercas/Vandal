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

if not vandal.utils then vandal.utils = { } end
if not vandal.utils.types then vandal.utils.types = { } else error "wut?" end
local types = vandal.utils.types

local ffi = require "ffi"

function types.get(val)
    local t = type(val)

    if t ~= "table" then
        return t
    else
        local class = val.__class

        if class then
            return vandal.classes[class] or t
            --  This will not work for classes that are not actually declared.
        else
            return t
        end
    end
end

function types.assert_ex(tname, valType, val, vname, errlvl)
    assert(type(valType) == "string", "Vandal internal error: Argument #2 to 'assertType' should be a string.")

    if type(tname) == "string" then
        if valType ~= tname then
            error("Vandal error: Type of " .. vname .. " should be '" .. tname .. "', not '" .. valType .. "'.", errlvl + 1)
        end
    elseif type(tname) == "table" then
        assert(#tname > 0, "Vandal internal error: Argument #1 to 'assertType' should have a length greater than zero.")

        for i = #tname, 1, -1 do
            local tname2 = tname[i]

            assert(type(tname2) == "string", "Vandal internal error: Argument #1 to 'assertType' should be an array of strings.")

            if tname2 == "integer" then
                if valType == "number" and val % 1 == 0 then
                    return valType
                end

                --  Else just move on to the next type. No biggie.
            elseif valType == tname2 then
                return valType
            end
        end

        local tlist = "'" .. tname[1] .. "'"

        for i = 2, #tname - 1 do
            tlist = tlist .. ", '" .. tname[i] .. "'"
        end

        if #tname > 1 then
            tlist = tlist .. ", or '" .. tname[#tname] .. "'"
        end

        error("Vandal error: Type of " .. vname .. " should be " .. tlist .. ", not '" .. valType .. "'.", errlvl + 1)
    else
        error("Vandal internal error: Argument #1 to 'assertType' should be a string or an array of strings, not a '" .. type(tname) .. ".")
    end

    return valType
end

function types.match(val, expected)
    local t = type(val)

    if t == expected then
        --  Yes, will accept tables too.

        return expected
    end

    if t == "table" then
        local class = val.__class

        while class do
            if class.__name == expected then
                return expected
            end

            class = class.__parent
        end

        if expected == "simple table" then
            --  Special type, meaning non-class table.

            return expected
        end
    elseif t == "number" then
        if expected == "integer" or expected == "long" then
            if types.is_integer(val) then
                return expected
            end
        elseif expected == "unsigned integer" or expected == "unsigned long" then
            if types.is_integer(val) and val > 0 then
                return expected
            end
        end
    elseif t == "cdata" then
        if expected == "long long" then
            if ffi.istype("long long", val) or ffi.istype("long", val) or ffi.istype("int", val) then
                return expected
            end
        elseif expected == "long" then
            if ffi.istype("long", val) or ffi.istype("int", val) then
                return expected
            end
        elseif expected == "int" then
            if ffi.istype("int", val) then
                return expected
            end
        elseif expected == "unsigned long long" then
            if ffi.istype("unsigned long long", val) or ffi.istype("unsigned long", val) or ffi.istype("unsigned int", val) then
                return expected
            end
        elseif expected == "unsigned long" then
            if ffi.istype("unsigned long", val) or ffi.istype("unsigned int", val) then
                return expected
            end
        elseif expected == "unsigned int" then
            if ffi.istype("unsigned int", val) then
                return expected
            end
        end
    end

    return false
end

function types.assert(tname, val, vname, errlvl)
    if not errlvl then errlvl = 1 end

    if type(tname) == "string" then
        local valType = types.match(val, tname)

        if valType then
            return valType
        else
            error("Vandal error: Type of '" .. vname .. "' should be '" .. tname .. "', not '" .. valType .. "'.", errlvl + 1)
        end
    elseif type(tname) == "table" then
        assert(#tname > 0, "Vandal internal error: Argument #1 to 'vandal.utils.types.assert' should have a length greater than zero.")

        for i = #tname, 1, -1 do
            local tname2 = tname[i]

            assert(type(tname2) == "string", "Vandal internal error: Argument #1 to 'vandal.utils.types.assert' should be an array of strings.")

            local valType = types.match(val, tname2)

            if valType then
                return valType
            end
        end

        local tlist = "'" .. tname[1] .. "'"

        for i = 2, #tname - 1 do
            tlist = tlist .. ", '" .. tname[i] .. "'"
        end

        if #tname > 1 then
            tlist = tlist .. ", or '" .. tname[#tname] .. "'"
        end

        error("Vandal error: Type of '" .. vname .. "' should be " .. tlist .. ", not '" .. valType .. "'.", errlvl + 1)
    else
        error("Vandal internal error: Argument #1 to 'vandal.utils.types.assert' should be a string or an array of strings, not a '" .. type(tname) .. ".")
    end
end

function types.is_integer(val)
    return (val + 2^52) - 2^52 == val
end

function types.is_int_or_long(val)
    if type(val) == "number" then
        return (val + 2^52) - 2^52 == val
    else
        return ffi.istype("long", val) or ffi.istype("int", val)
    end
end

return types

