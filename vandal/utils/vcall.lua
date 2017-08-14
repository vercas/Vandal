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
if vandal.utils.vcall then error "wut?" end

local types = require "vandal/utils/types"

local function prettyString(val)
    if type(val) == "string" then
        return string.format("%q", val)
    else
        return tostring(val)
    end
end

local function printTable(t, append, indent, done)
    local myIndent = string.rep("\t", indent)

    for key, value in pairs(t) do
        append(myIndent)
        append(prettyString(key))

        if types.get(value) == "table" and not done[value] then
            done[value] = true

            local ts = tostring(value)

            if ts:sub(1, 9) == "table: 0x" then
                append ": "
                append(ts)
                append "\n"
                printTable(value, append, indent + 1, done)
            else
                append " = "
                append(ts)
                append "\n"
            end
        else
            append " = "
            append(prettyString(value))
            append "\n"
        end
    end
end

local function printEndData(self, indent, out)
    indent = indent or 0

    local myIndent = string.rep("\t", indent)

    local res = { myIndent, "ERROR:\t", self.Error, "\n" }
    local function append(val, blergh, ...)
        res[#res + 1] = val

        if blergh then
            append(blergh, ...)
        end
    end

    myIndent = myIndent .. "\t"

    for i = 1, #self.Stack do
        local info, appendSource = self.Stack[i]

        append(myIndent)
        append(tostring(i))
        append "\t"

        if vandal.verbose or vandal.debug then
            function appendSource()
                append "\n"
                append(myIndent)
                append "\t  location: "

                if info.what ~= "C" then
                    append(info.short_src or info.source)

                    if info.currentline then
                        append ":"
                        append(tostring(info.currentline))
                    end

                    append "\n"

                    if info.what == "Lua" and info.linedefined and (info.linedefined ~= info.currentline or info.lastlinedefined ~= info.currentline) then
                        --  This hides the definition of inline functions that will contain the erroneous line of code anyway.
                        --  Also excludes C code and main chunks, which show placeholder values there.

                        append(myIndent)
                        append "\t  definition at "

                        append(tostring(info.linedefined))

                        if info.lastlinedefined then
                            append "-"
                            append(tostring(info.lastlinedefined))
                        end

                        append "\n"
                    end
                else
                    append "C\n"
                end
            end
        else
            function appendSource()
                append "\t"

                if info.what ~= "C" then
                    append "  "
                    append(info.short_src or info.source)

                    if info.currentline then
                        append ":"
                        append(tostring(info.currentline))
                    end

                    if info.what == "Lua" and info.linedefined and (info.linedefined ~= info.currentline or info.lastlinedefined ~= info.currentline) then
                        --  This hides the definition of inline functions that will contain the erroneous line of code anyway.
                        --  Also excludes C code and main chunks, which show placeholder values there.

                        append "\t  def. at "

                        append(tostring(info.linedefined))

                        if info.lastlinedefined then
                            append "-"
                            append(tostring(info.lastlinedefined))
                        end
                    end

                    append "\n"
                else
                    append "  [C]\n"
                end
            end
        end

        if info.istailcall then
            append "tail calls..."

            if info.short_src or info.source then
                appendSource()
            else
                append "\n"
            end
        elseif info.name then
            --  This is a named function!

            append(info.namewhat)
            append "\t"
            append(info.name)
            appendSource()
        elseif info.what == "Lua" then
            --  Unnamed Lua function = anonymous

            append "anonymous function"
            appendSource()
        elseif info.what == "main" then
            --  This is the main chunk of code that is executing.

            append "main chunk"
            appendSource()
        elseif info.what == "C" then
            --  This might be what invoked the main chunk.

            append "unknown C code\n"
        end

        --  Now, upvalues, locals, parameters...

        if info.what ~= "C" and (vandal.verbose or vandal.debug) then
            --  Both main chunk and Lua functions can haz these.

            append(myIndent)
            append "\t  "

            if info.nparams == 1 then
                append "1 parameter; "
            else
                append(tostring(info.nparams))
                append " parameters; "
            end

            if #info._locals - info.nparams == 1 then
                append "1 local; "
            else
                append(tostring(#info._locals - info.nparams))
                append " locals; "
            end

            if info.nups == 1 then
                append "1 upvalue\n"
            else
                append(tostring(info.nups))
                append " upvalues\n"
            end

            local extraIndent = myIndent .. "\t\t"
            local done = { [_G] = true, [vandal] = true, [self] = true }

            for j = 1, #info._locals do
                local key, value = info._locals[j].name, info._locals[j].value

                append(extraIndent)
                append(prettyString(key))

                if types.get(value) == "table" and not done[value] then
                    done[value] = true

                    local ts = tostring(value)

                    if ts:sub(1, 9) == "table: 0x" then
                        append ": "
                        append(ts)
                        append "\n"
                        printTable(value, append, indent + 4, done)
                    else
                        append " = "
                        append(ts)
                        append "\n"
                    end
                else
                    append " = "
                    append(prettyString(value))
                    append "\n"
                end
            end

            if info._upvalues then
                for j = 1, #info._upvalues do
                    local key, value = info._upvalues[j].name, info._upvalues[j].value

                    append(extraIndent)
                    append(prettyString(key))

                    if types.get(value) == "table" and not done[value] then
                        done[value] = true

                        local ts = tostring(value)

                        if ts:sub(1, 9) == "table: 0x" then
                            append ": "
                            append(ts)
                            append "\n"
                            printTable(value, append, indent + 4, done)
                        else
                            append " = "
                            append(ts)
                            append "\n"
                        end
                    else
                        append " = "
                        append(prettyString(value))
                        append "\n"
                    end
                end
            end
        end
    end

    res = table.concat(res)

    if out then
        return out(res)
    else
        return res
    end
end

local function queuefunc(fnc, functionlist, donefunctions)
    if donefunctions[fnc] then return end

    functionlist[#functionlist+1] = fnc
    donefunctions[fnc] = true
end

function vandal.utils.gather_end_state(err)
    local functionlist, donefunctions = {}, {}

    local stack, thesaurus = {}, {}

    local i = 2

    while true do
        local info = debug.getinfo(i)

        if not info then
            break
        end

        stack[#stack+1] = info
        info._stackpos = i

        if info.func then
            thesaurus[info.func] = info
            queuefunc(info.func, functionlist, donefunctions)
            info.func = tostring(info.func)
        end

        --if info.what == "Lua" then
        info._locals = {}
        local locals = info._locals

        local j = 1

        while true do
            local n, v = debug.getlocal(i, j)

            if not n then break end

            locals[#locals+1] = {name=n,value=v}

            if type(v) == "function" then
                queuefunc(v, functionlist, donefunctions)
                locals[#locals].value = tostring(locals[#locals].value)
            end

            j = j + 1
        end
        --end

        i = i + 1
    end

    for i = 1, #functionlist do
        local fnc = functionlist[i]

        local info

        if thesaurus[fnc] then
            info = thesaurus[fnc]
        else
            info = debug.getinfo(fnc)
            thesaurus[fnc] = info
        end

        local ups = {}
        info._upvalues = ups

        for j = 1, info.nups do
            local n, v = debug.getupvalue(fnc, j)

            ups[#ups+1] = {name=n,value=v}

            if type(v) == "function" then
                queuefunc(v, functionlist, donefunctions)
                ups[#ups].value = tostring(ups[#ups].value)
            end
        end
    end

    local newthesaurus = {}

    for k, v in pairs(thesaurus) do
        newthesaurus[tostring(k)] = v
    end

    return { Stack = stack, Thesaurus = newthesaurus, Error = err, ShortTrace = debug.traceback(nil, 2), Print = printEndData }
end
local gather_end_state = vandal.utils.gather_end_state

do
    --  A small workaround around old xpcall versions.

    local foo = 1

    xpcall(
        function(arg)
            if arg == "bar" then
                foo = 2
            else
                foo = 0
            end
        end,
        function(err)
            io.stderr:write("This really shouldn't have happened:\n", err, "\n")
            os.exit(-100)
        end,
        "bar")

    assert(foo ~= 1, "'foo' should have changed!")

    if foo == 0 then
        if MSG then
            --  Do not force a dependency. :(

            MSG("xpcall doesn't seem to support passing arguments; working around it.")
        end

        function vandal.utils.vcall(inner_function, ...)
            local wrapped_args = {...}

            local function wrapper_function()
                return inner_function(unpack(wrapped_args))
            end

            local ret = {xpcall(wrapper_function, gather_end_state)}

            if ret[1] then
                --  Call succeeded.

                table.remove(ret, 1)

                return { Return = ret }
            else
                --  Call failed!

                return ret[2]
            end
        end
    else
        function vandal.utils.vcall(fnc, ...)
            local ret = {xpcall(fnc, gather_end_state, ...)}

            if ret[1] then
                --  Call succeeded.

                table.remove(ret, 1)

                return { Return = ret }
            else
                --  Call failed!

                return ret[2]
            end
        end
    end
end

return vandal.utils.vcall

