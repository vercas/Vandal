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

local classes = require "vandal/classes"
local types = require "vandal/utils/types"
require "vandal/logging"

local Ctx, Exp, CmdExp, SeqExp, SubExp

--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --
--  Expressions --
--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --

do
    local cl = {
        Name = "Expression",
    }

    function cl:__init()
        --  Nothing.
    end

    function cl:__tostring()
        error "Vandal commands error: `__tostring` not implemented for expression class."
    end

    Exp = classes.create(cl)
end

do
    local cl = {
        Name = "CommandExpression",
        ParentName = "Expression",
    }

    function cl:__init(typ)
        __super(self)

        self.command_name = false
        self.args = {}
    end

    function cl:add_component(comp)
        if self.command_name then
            self.args[#self.args + 1] = comp
        else
            self.command_name = comp
        end
    end

    function cl:__tostring()
        local components = { self.command_name and string.quotify(self.command_name) or "~INVALID~" }

        for i = 1, #self.args do
            local arg = self.args[i]

            if type(arg) == "string" then
                components[i + 1] = string.quotify(arg)
            elseif types.match(arg, "CommandExpression") then
                components[i + 1] = '[' .. tostring(arg) .. ']'
            elseif types.match(arg, "Subexpression") then
                components[i + 1] = tostring(arg)
            end
        end

        return table.concat(components, " ")
    end

    CmdExp = classes.create(cl)
end

do
    local cl = {
        Name = "SequenceExpression",
        ParentName = "Expression",
    }

    function cl:__init()
        __super(self)

        self.subexpressions = { }
    end

    function cl:add_expression(exp)
        types.assert("Expression", exp, "expression")

        self.subexpressions[#self.subexpressions + 1] = exp
    end

    function cl:__tostring()
        local exps = {}

        for i = 1, #self.subexpressions do
            exps[i] = tostring(self.subexpressions[i])
        end

        return table.concat(exps, "; ")
    end

    SeqExp = classes.create(cl)
end

do
    local cl = {
        Name = "Subexpression",
        ParentName = "SequenceExpression",
    }

    function cl:__init()
        __super(self)
    end

    function cl:__tostring()
        local exps = {}

        for i = 1, #self.subexpressions do
            exps[i] = tostring(self.subexpressions[i])
        end

        if #exps > 0 then
            return "{ " .. table.concat(exps, "; ") .. "; }"
        else
            return "{ }"
        end
    end

    SubExp = classes.create(cl)
end

--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --
--  Parser  --
--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --

local parse

do
    local escape_sequences = { n = '\n', t = '\t', b = '\b', }

    local function parse_word(line, linelen, i)
        local res = {}

        local inEscape, inSQ, inDQ = false, false, false
        local quoteStart, c

        while i <= linelen do
            c = line:sub(i, i)

            if not c then break end

            if inEscape then
                res[#res + 1] = escape_sequences[c] or c

                inEscape = false
            elseif quoteStart then
                if c == '\\' then
                    inEscape = true
                elseif inSQ and c == "'" then
                    quoteStart = nil
                    inSQ = false
                elseif inDQ and c == '"' then
                    quoteStart = nil
                    inDQ = false
                else
                    res[#res + 1] = c
                end
            else
                if c == '\\' then
                    inEscape = true
                elseif c == '"' then
                    quoteStart = i
                    inDQ = true
                elseif c == "'" then
                    quoteStart = i
                    inSQ = true
                elseif string.find("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_", c, 1, true) then
                    res[#res + 1] = c
                else
                    --  This character does not belong to this word.

                    i = i - 1

                    break
                end
            end

            i = i + 1
        end

        res = table.concat(res)

        if inEscape then
            return res, i, "Unfinished escape sequence at character #" .. (i - 1)
        end

        if inSQ then
            return res, i, "Unpaired single quotes at character #" .. quoteStart
        end

        if inDQ then
            return res, i, "Unpaired double quotes at character #" .. quoteStart
        end

        return res, i
    end

    local exty_names = { main = "main/outer", cmdarg = "command argument", subexp = "sub-expression" }

    local function _parse(line, linelen, i, exty)
        local exp, start, res, err, seq = CmdExp(), (exty == "main") and i or (i - 1)
        local subStart = start

        local firstWord = true

        while i <= linelen do
            local c = line:sub(i, i)

            if not string.find(" \t\n", c, 1, true) then
                --  Whitespaces are completely ignored here.

                if c == '[' then
                    --  Means the beginning of a sub statement.

                    if firstWord then
                        --  First thing must be a word.

                        return exp, i, "Expected a word (as command name) instead of command substitution at character #" .. i
                    end

                    res, i, err = _parse(line, linelen, i + 1, "cmdarg")
                elseif c == ']' then
                    if exty ~= "cmdarg" then
                        return exp, i, "Stray ']' found in (" .. exty .. ") command at character #" .. i
                    end

                    --  This seems to be the end.

                    if firstWord then
                        return exp, i, "Command beginning at character #" .. start .. " and ending at character #" .. i .. " is empty"
                    end

                    return exp, i
                elseif c == '{' then
                    --  Means the beginning of a sub-expression.

                    if firstWord then
                        --  First thing must be a word.

                        return exp, i, "Expected a word (as command name) instead of sub-expression at character #" .. i
                    end

                    res, i, err = _parse(line, linelen, i + 1, "subexp")
                elseif c == '}' then
                    if exty ~= "subexp" then
                        return exp, i, "Stray '}' found in (" .. exty .. ") command at character #" .. i
                    end

                    --  This seems to be the end.
                    --  Note: An empty subexpression is completely fine!

                    if not seq then
                        seq = SubExp()
                    end

                    if not firstWord then
                        seq:add_expression(exp)
                    end

                    return seq, i
                elseif c == ';' then
                    if exty == "cmdarg" then
                        return exp, i, "Sequence separator at character #" .. i .. " should not appear inside a command substitution"
                    end

                    if not seq then
                        if exty == "main" then
                            seq = SeqExp()
                        else
                            seq = SubExp()
                        end
                    end

                    seq:add_expression(exp)

                    exp, firstWord, start, res, err = CmdExp(), true, i + 1, nil, nil
                else
                    --  Must be a word.

                    local oi = i

                    res, i, err = parse_word(line, linelen, i)

                    if i < oi then
                        --  Parser couldn't advance because this character doesn't belong anywhere.
                        return exp, i, "Illegal character encountered at #" .. i .. ": " .. c
                    end

                    firstWord = false
                end

                if res ~= nil then
                    exp:add_component(res)
                end

                if err then
                    return exp, i, err
                end
            end

            i = i + 1
        end

        if firstWord and not seq then
            err = "Command beginning at character #" .. start .. " is empty"
        end

        if exty == "cmdarg" then
            err = "Command substitution beginning at character #" .. subStart .. " lacks a closing ']'"
        elseif exty == "subexp" then
            err = "Subexpression beginning at character #" .. subStart .. " lacks a closing '}'"
        end

        if seq then
            if not firstWord then
                seq:add_expression(exp)
            end

            exp = seq
        end

        return exp, i, err
    end

    function parse(str, i)
        return _parse(str, #str, i or 1, "main")
    end

    --------------------------------------------------------------------------------

    local LASTRES, LASTSTR

    local function TESTPARSE(str)
        LASTSTR = str
        ERR("Parsing <<<", str, ">>>")

        local res, i, err = parse(str)

        if err then
            ERR("ERROR: ", err)
            LASTRES = false
        else
            LASTRES = tostring(res)
        end

        ERR(res)
    end

    local function CHECKLAST(val)
        if LASTRES ~= (val or LASTSTR) then
            error(string.format("Test failure: Expected %q! Got %q instead.", val or LASTSTR, LASTRES))
        end
    end

    local function FAILLAST()
        if LASTRES then
            error(string.format("Test failure: Expected error, got %q instead.", LASTRES))
        end
    end

    TESTPARSE "rada" CHECKLAST()
    TESTPARSE "blah yada" CHECKLAST()
    TESTPARSE "a b c d e f g h" CHECKLAST()
    TESTPARSE "ra\\da" CHECKLAST "rada"
    TESTPARSE "r'ad'a" CHECKLAST "rada"
    TESTPARSE "ra\"da\"" CHECKLAST "rada"
    TESTPARSE "ra\"d'aa'a\"" CHECKLAST [=["rad'aa'a"]=]
    TESTPARSE "should error\\" FAILLAST()
    TESTPARSE "should 'also error" FAILLAST()
    TESTPARSE "should also\" error" FAILLAST()
    TESTPARSE "[should not be allowed]" FAILLAST()
    TESTPARSE " command [ substitution ]  " CHECKLAST "command [substitution]"
    TESTPARSE "  command [  ]" FAILLAST()
    TESTPARSE "1[2[3[4[5[6[7[8[9]]]]]]]]" CHECKLAST "1 [2 [3 [4 [5 [6 [7 [8 [9]]]]]]]]"
    TESTPARSE "1 a[2 b[3 c[4 d[5 e[6 f[7 g[8\th[9\ni]]]]]]]]" CHECKLAST "1 a [2 b [3 c [4 d [5 e [6 f [7 g [8 h [9 i]]]]]]]]"
    TESTPARSE "cmd [" FAILLAST()
    TESTPARSE "cmd [sub] ]" FAILLAST()
    TESTPARSE "cmd [a][b][c] [d] [e [f]]" CHECKLAST "cmd [a] [b] [c] [d] [e [f]]"
    TESTPARSE "a;b" CHECKLAST "a; b"
    TESTPARSE "a ;b" CHECKLAST "a; b"
    TESTPARSE "a; b" CHECKLAST()
    TESTPARSE "a [b;c]" FAILLAST()
    TESTPARSE "x y z;" CHECKLAST "x y z"
    TESTPARSE "asd#" FAILLAST()
    TESTPARSE "a {b}" CHECKLAST "a { b; }"
    TESTPARSE "a { b; c; }" CHECKLAST()
    TESTPARSE "a b [c { d; e [f g]; }]" CHECKLAST()

    --------------------------------------------------------------------------------
end

--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --
--  Compiler    --
--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --

local compile

do
    local _compile

    local function compCmdExp(comp, exp)
        local cn, ca = exp.command_name, exp.args

        if type(cn) == "string" then
            local oldT, oldIS = comp.tail, comp.in_statement

            if cn == "if" then
                if #ca < 3 or ca % 2 == 0 then
                    comp.err = "Woah dude."
                    return
                end
            else
                if oldT then
                    comp.tail = false
                    comp[#comp + 1] = "return "
                end

                comp[#comp + 1] = string.format("__funcs[%q](", cn)
                comp.in_statement = false

                for i = 1, #ca do
                    local arg = ca[i]
                    local aType = types.get(arg)

                    if i > 1 then
                        comp[#comp + 1] = ", "
                    end

                    if aType == "string" then
                        comp[#comp + 1] = string.format("%q", arg)
                    elseif aType == "CommandExpression" then
                        compCmdExp(comp, arg)

                        if comp.err then return end
                    else
                        error "TODO"
                    end
                end

                comp[#comp + 1] = ")"
            end

            comp.tail = oldT
            comp.in_statement = oldIS
        else
            error "TODO"
        end
    end

    local function compSeqExp(comp, exp)
        local oldT, oldIS = comp.tail, comp.in_statement

        if oldT then
            comp.tail = false
            comp[#comp + 1] = "return "
        end

        comp[#comp + 1] = "{ "
        comp.in_statement = false

        for i = 1, #exp.subexpressions do
            local sub = exp.subexpressions[i]
            local sType = types.get(sub)

            if i > 1 then
                comp[#comp + 1] = ", "
            end

            if sType == "CommandExpression" then
                compCmdExp(comp, sub)
            else
                error "TODO"
            end
        end

        comp[#comp + 1] = " }"
        comp.tail = oldT
        comp.in_statement = old
    end

    function _compile(comp, exp, ...)
        local eType = types.get(exp)

        if eType == "CommandExpression" then
            return compCmdExp(comp, exp, ...)
        elseif eType == "SequenceExpression" then
            return compSeqExp(comp, exp, ...)
        else
            error "TODO?"
        end
    end

    function compile(exp)
        local eType, comp = types.get(exp), { in_statement = true, tail = true }

        if eType == "CommandExpression" then
            compCmdExp(comp, exp, true)
        elseif eType == "SequenceExpression" then
            compSeqExp(comp, exp)
        else
            error "TODO?"
        end

        return table.concat(comp)
    end

    --------------------------------------------------------------------------------

    local LASTRES, LASTSTR

    local function TESTCOMP(str)
        LASTSTR = str
        ERR("Compiling <<<", str, ">>>")

        local res, i, err = parse(str)

        if err then
            ERR("ERROR: ", err)
            LASTRES = false
        else
            res = compile(res)

            LASTRES = tostring(res)
            ERR(res)
        end
    end

    TESTCOMP "func"
    TESTCOMP "func arg"
    TESTCOMP "func arg1 arg2"
    TESTCOMP "func1; func2"
    TESTCOMP "func1 [func2]"
end

return {
    parse = parse,
    compile = compile,
}

