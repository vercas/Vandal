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

local Ctx, Exp, ConExp, VarExp, CmdExp, SeqExp, SubExp

--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --
--  Expressions --
--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --

do
    local cl = {
        Name = "Expression",
    }

    function cl:__init()
        self.start, self.finish = -1, -1
    end

    function cl:__tostring()
        error "Vandal commands error: `__tostring` not implemented for expression class."
    end

    Exp = classes.create(cl)
end

do
    local cl = {
        Name = "ConstantExpression",
        ParentName = "Expression",
    }

    function cl:__init(val)
        __super(self)

        self.val = val
    end

    function cl:__tostring()
        return string.quotify(self.val)
    end

    function cl:eq(other)
        return self.val == other and #other == (self.finish - self.start + 1)
    end

    ConExp = classes.create(cl)
end

do
    local cl = {
        Name = "VariableExpression",
        ParentName = "Expression",
    }

    function cl:__init(name)
        __super(self)

        self.name = name
    end

    function cl:__tostring()
        return "$" .. string.quotify(self.name)
    end

    VarExp = classes.create(cl)
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
        local components = { self.command_name and tostring(self.command_name) or "~INVALID~" }

        for i = 1, #self.args do
            local arg = self.args[i]

            if types.match(arg, "CommandExpression") then
                components[i + 1] = '[' .. tostring(arg) .. ']'
            elseif types.match(arg, "Subexpression") or types.match(arg, "ConstantExpression") or types.match(arg, "VariableExpression") then
                components[i + 1] = tostring(arg)
            else
                components[i + 1] = "~INVALID~" .. types.get(arg) .. "~"
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
        local wordStart, quoteStart, c = i

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

        local exp = ConExp(res)
        exp.start, exp.finish = wordStart, math.min(i, linelen)

        return exp, i
    end

    local exty_names = { main = "main/outer", cmdarg = "command argument", subexp = "sub-expression" }

    local function _parse(line, linelen, i, exty)
        local exp, start, res, err, seq = CmdExp(), (exty == "main") and i or (i - 1)
        local subStart, inLineComment, inBlockComment, blockCommentStart = start, false, false
        exp.start = start

        local firstWord = true

        while i <= linelen do
            local c = line:sub(i, i)

            if inLineComment then
                if c == '\n' then
                    inLineComment = false
                elseif c == '[' and i - 1 == inLineComment then
                    --  #[ means this is a block comment.

                    blockCommentStart = inLineComment
                    inLineComment, inBlockComment = false, true
                end

                --  Everything else is ignored.
            elseif inBlockComment then
                if c == '#' then
                    inBlockComment = i
                elseif c == ']' and i - 1 == inBlockComment then
                    --  #] means this block comment has ended!.

                    inBlockComment = false
                end

                --  Everything else is ignored.
            elseif string.find(" \t\n", c, 1, true) then
                --  Whitespaces are completely ignored here.
            elseif c == '#' then
                --  Means the beginning of a line comment.

                inLineComment = i
            elseif c == '[' then
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

                exp.finish = i

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

                if exp.finish == -1 then
                    exp.finish = i
                end

                --  This seems to be the end.
                --  Note: An empty subexpression is completely fine!

                if not seq then
                    seq = SubExp()
                    seq.start = exp.start
                end

                if not firstWord then
                    seq:add_expression(exp)
                end

                seq.finish = i

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

                    seq.start = exp.start
                end

                seq:add_expression(exp)

                exp, firstWord, start, res, err = CmdExp(), true, i + 1, nil, nil
                exp.start = start
            elseif c == "$" then
                if firstWord then
                    return exp, i, "Variable name encountered where a command name was expected"
                end

                local oi = i + 1
                res, i, err = parse_word(line, linelen, oi)

                if i < oi then
                    return exp, i, "Illegal character encountered at #" .. i .. ": " .. c .. " - expected word"
                elseif res.val == "" then
                    return exp, i, "Expected identifier for variable name at #" .. i
                end

                local var = VarExp(res.val)
                var.start, var.finish = res.start, res.finish

                res = var
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
                res = nil
            end

            if err then
                return exp, i, err
            end

            i = i + 1
        end

        if firstWord and not seq then
            err = "Command beginning at character #" .. start .. " is empty"
        elseif exty == "cmdarg" then
            err = "Command substitution beginning at character #" .. subStart .. " lacks a closing ']'"
        elseif exty == "subexp" then
            err = "Subexpression beginning at character #" .. subStart .. " lacks a closing '}'"
        elseif inBlockComment then
            err = "Block comment started at character #" .. blockCommentStart .. " lacks closing '#]'"
        end

        if seq then
            if not firstWord then
                seq:add_expression(exp)
                exp.finish = i - 1
            end

            exp = seq
        end

        exp.finish = i - 1

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
    TESTPARSE "asd#" CHECKLAST "asd"
    TESTPARSE "asd%" FAILLAST()
    TESTPARSE "a {b}" CHECKLAST "a { b; }"
    TESTPARSE "a { b; c; }" CHECKLAST()
    TESTPARSE "a b [c { d; e [f g]; }]" CHECKLAST()
    TESTPARSE "a $b" CHECKLAST()
    TESTPARSE "a $b c" CHECKLAST()
    TESTPARSE "a $b\\ c" CHECKLAST('a $"b c"')
    TESTPARSE "a $" FAILLAST()
    TESTPARSE "a $ " FAILLAST()
    TESTPARSE "a $ b" FAILLAST()
    TESTPARSE "$" FAILLAST()
    TESTPARSE "$a" FAILLAST()
    TESTPARSE "$a b" FAILLAST()

    --------------------------------------------------------------------------------
end

--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --
--  Compiler    --
--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --

local compile

do
    local _compile, compSubExp, compSeqExp, compCmdExp, compVarExp

    local conditional_keywords = { ["if"] = "if", ["elif"] = "elseif", ["else"] = "else" }
    local constant_names = { ["NIL"] = "nil", ["TRUE"] = "true", ["FALSE"] = "false", }

    function compVarExp(comp, exp)
        local oldIS = comp.in_statement

        if oldIS then
            comp.exp, comp.err = exp, "Variable access is not a valid statement, it is an expression"
            return
        end

        local name = exp.name
        local const = constant_names[name:upper()]

        if const then
            comp[#comp + 1] = const
        else
            if not name:match "^[a-zA-Z_][0-9a-zA-Z_]*$" then
                comp.exp, comp.err = exp, "Variable name may only contain letters, digits, and underscores; first character may not be a digit"
                return
            end

            if not comp.scope[name] then
                comp.exp, comp.err = exp, "No local defined with the name \"" .. name .. "\""
                return
            end

            comp[#comp + 1] = name
        end
    end

    function compCmdExp(comp, exp)
        local cn, ca = exp.command_name, exp.args

        if types.get(cn) == "ConstantExpression" then
            local oldT, oldIS, oldI = comp.tail, comp.in_statement, comp.indent

            if cn:eq "if" then
                local done, keyword, i = false, "if", 1

                if not oldIS then
                    if oldT then
                        comp[#comp + 1] = "return (function()\n"
                    else
                        comp[#comp + 1] = "(function()\n"
                    end

                    if oldI then
                        comp.indent = oldI .. "    "
                    else
                        comp.indent = "    "
                    end
                end

                repeat
                    if not conditional_keywords[keyword] then
                        comp.exp, comp.err = exp, "Conditional statement contains an unknown keyword `" .. keyword .. "`"
                        return
                    elseif keyword == "else" then
                        done = true
                    end

                    if i > #ca then
                        comp.exp, comp.err = exp, "Conditional statement needs at least a subexpression, possibly preceeded by a condition, to execute after the keyword `" .. keyword .. "`"
                        return
                    end

                    if done then
                        --  Means this is the `else`.

                        local sub = ca[i]
                        i = i + 1

                        local sType = types.get(sub)

                        if comp.indent then comp[#comp + 1] = comp.indent end
                        comp[#comp + 1] = "else\n"

                        comp.tail = oldT or not oldIS

                        if sType == "Subexpression" then
                            compSubExp(comp, sub)
                        elseif sType == "VariableExpression" then
                            if not comp.tail then
                                comp.exp, comp.err = exp, "Conditional statement accepts a variable access after the keyword `else` only when the statement value's is returned"
                                return
                            end

                            compVarExp(comp, sub)
                        else
                            comp.exp, comp.err = exp, "Conditional statement needs a subexpression after the keyword `else`"

                            if types.match(sub, "Expression") then comp.exp = sub end

                            return
                        end

                        if comp.err then return end
                    else
                        local cond, sub = ca[i], ca[i + 1]
                        i = i + 2

                        local cType, sType = types.get(cond), types.get(sub)

                        if comp.indent then comp[#comp + 1] = comp.indent end
                        comp[#comp + 1] = conditional_keywords[keyword]
                        comp[#comp + 1] = " "

                        comp.tail, comp.in_statement = false, false

                        if cType == "VariableExpression" then
                            compVarExp(comp, cond)
                        elseif cType == "CommandExpression" then
                            compCmdExp(comp, cond)
                        else
                            comp.exp, comp.err = exp, "Conditional statement condition after the keyword `" .. keyword .. "` needs to be a command substitution or variable access"
                            if types.match(cond, "Expression") then comp.exp = cond end
                            return
                        end

                        if comp.err then return end

                        comp[#comp + 1] = " then\n"

                        comp.tail = oldT or not oldIS

                        if sType == "Subexpression" then
                            compSubExp(comp, sub)
                        elseif sType == "VariableExpression" then
                            if not comp.tail then
                                comp.exp, comp.err = exp, "Conditional statement accepts a variable access after the keyword `" .. keyword .. "` and the condition only when the statement value's is returned"
                                return
                            end

                            compVarExp(comp, sub)
                        else
                            comp.exp, comp.err = exp, "Conditional statement needs a subexpression after the keyword `" .. keyword .. "` and the condition"
                            if types.match(sub, "Expression") then comp.exp = sub end
                            return
                        end

                        if comp.err then return end
                    end

                    if i > #ca then
                        break
                    elseif done then
                        comp.exp, comp.err = ca[i + 1], "Conditional statement contains a stray expression after else clause's subexpression"
                    else
                        keyword = ca[i]
                        i = i + 1

                        if types.get(keyword) ~= "ConstantExpression" then
                            comp.exp, comp.err = keyword, "Conditional statement contains invalid expression after a subexpression; a keyword is expected, or nothing; got \"" .. types.get(keyword) .. "\""
                            return
                        end

                        keyword = keyword.val
                    end
                until done

                if comp.indent then comp[#comp + 1] = comp.indent end
                comp[#comp + 1] = "end"

                if not oldIS then
                    comp[#comp + 1] = "\n"
                    if oldI then comp[#comp + 1] = oldI end
                    comp[#comp + 1] = "end)()"
                end
            elseif cn:eq "return" then
                if not oldIS then
                    comp.exp, comp.err = exp, "Return statement is not a valid expression, it is a statement"
                    return
                end

                if oldIS and oldI then comp[#comp + 1] = oldI end

                if oldT then
                    comp[#comp + 1] = "return "
                else
                    comp[#comp + 1] = "do return "
                end

                for i = 1, #ca do
                    local arg = ca[i]
                    local aType = types.get(arg)

                    if i > 1 then
                        comp[#comp + 1] = ", "
                    end

                    comp.tail, comp.in_statement = false, false

                    if aType == "ConstantExpression" then
                        comp[#comp + 1] = string.format("%q", arg.val)
                    elseif aType == "VariableExpression" then
                        compVarExp(comp, arg)
                    elseif aType == "CommandExpression" then
                        compCmdExp(comp, arg)
                    elseif aType ~= "nil" then
                        error "TODO"
                    end

                    if comp.err then return end
                end

                if not oldT then
                    comp[#comp + 1] = " end"
                end
            elseif cn:eq "local" then
                if not oldIS then
                    comp.exp, comp.err = exp, "Local declaration is not a valid expression, it is a statement"
                    return
                end

                if #ca > 2 then
                    comp.exp, comp.err = exp, "Local declaration contains too many arguments"
                    return
                end

                if oldI then comp[#comp + 1] = oldI end

                comp[#comp + 1] = "local "

                local name, val = ca[1], ca[2]

                if types.get(name) ~= "ConstantExpression" then
                    comp.exp, comp.err = exp, "Local declaration needs a name as first argument"
                    if types.match(name, "Expression") then comp.exp = name end
                    return
                elseif not name.val:match "^[a-zA-Z_][0-9a-zA-Z_]*$" then
                    comp.exp, comp.err = exp, "Local variable name may only contain letters, digits, and underscores; first character may not be a digit"
                    return
                end

                comp[#comp + 1] = name.val

                if val ~= nil then
                    local vType = types.get(val)

                    comp[#comp + 1] = " = "
                    comp.tail, comp.in_statement = false, false

                    if vType == "CommandExpression" then
                        compCmdExp(comp, val)
                    elseif vType == "ConstantExpression" then
                        comp[#comp + 1] = string.format("%q", val.val)
                    elseif vType == "VariableExpression" then
                        compVarExp(comp, val)
                    else
                        comp.exp, comp.err = exp, "Local variable value, if present, must be a constant or a command substitution"
                        if types.match(val, "Expression") then comp.exp = val end
                        return
                    end

                    if comp.err then return end
                end

                comp.scope[name.val] = exp
            elseif cn:eq "get" then
                if oldIS and not oldT then
                    comp.exp, comp.err = exp, "Local reading is not a valid statement, it is an expression; however it may be an implicit return"
                    return
                end

                --if #ca < 1 then
                --    comp.exp, comp.err = exp, "Local reading must receive at least one argument; all arguments are names of local variables"
                if #ca ~= 1 then
                    comp.exp, comp.err = exp, "Local reading must receive exactly one argument: name of a local variables"
                    return
                end

                if oldIS and oldI then comp[#comp + 1] = oldI end
                if oldT then comp[#comp + 1] = "return " end

                --for i = 1, #ca do
                --    local name = ca[i]
                local name = ca[1]

                if types.get(name) ~= "ConstantExpression" then
                    --comp.exp, comp.err = exp, "Local reading needs a name for each argument; argument #" .. i .. " is not a name"
                    comp.exp, comp.err = exp, "Local reading needs a name"
                    if types.match(name, "Expression") then comp.exp = name end
                    return
                elseif not name.val:match "^[a-zA-Z_][0-9a-zA-Z_]*$" then
                    --comp.exp, comp.err = exp, "Local variable name may only contain letters, digits, and underscores; first character may not be a digit; name #" .. i .. " is invalid"
                    comp.exp, comp.err = exp, "Local variable name may only contain letters, digits, and underscores; first character may not be a digit"
                    return
                end

                if not comp.scope[name.val] then
                    comp.exp, comp.err = exp, "No local defined with the name " .. name
                    return
                end

                --if i > 1 then
                --    comp[#comp + 1] = ", "
                --end

                comp[#comp + 1] = name.val
                --end
            elseif cn:eq "set" then
                if not oldIS then
                    comp.exp, comp.err = exp, "Local writing is not a valid expression, it is a statement"
                    return
                end

                if #ca < 2 then
                    comp.exp, comp.err = exp, "Local writing must receive at least two arguments; last argument is a value and the rest are names of local variables"
                    return
                end

                if oldI then comp[#comp + 1] = oldI end

                for i = 1, #ca - 1 do
                    local name = ca[i]

                    if types.get(name) ~= "ConstantExpression" then
                        comp.exp, comp.err = exp, "Local writing needs a name for each argument; argument #" .. i .. " is not a name"
                        if types.match(name, "Expression") then comp.exp = name end
                        return
                    elseif not name.val:match "^[a-zA-Z_][0-9a-zA-Z_]*$" then
                        comp.exp, comp.err = exp, "Local variable name may only contain letters, digits, and underscores; first character may not be a digit; name #" .. i .. " is invalid"
                        return
                    end

                    if not comp.scope[name.val] then
                        comp.exp, comp.err = exp, "No local defined with the name " .. name
                        return
                    end

                    if i > 1 then
                        comp[#comp + 1] = ", "
                    end

                    comp[#comp + 1] = name.val
                end

                local val = ca[#ca]
                local vType = types.get(val)

                comp[#comp + 1] = " = "
                comp.tail, comp.in_statement = false, false

                if vType == "CommandExpression" then
                    compCmdExp(comp, val)
                elseif vType == "ConstantExpression" then
                    comp[#comp + 1] = string.format("%q", val.val)
                elseif vType == "VariableExpression" then
                    compVarExp(comp, val)
                else
                    comp.exp, comp.err = exp, "Local writing value must be a constant or a command substitution"
                    if types.match(val, "Expression") then comp.exp = val end
                    return
                end

                if comp.err then return end
            elseif cn:eq "const" then
                if oldIS and not oldT then
                    comp.exp, comp.err = exp, "Constant value is not a valid statement, it is an expression; however it may be an implicit return"
                    return
                end

                --if #ca < 1 then
                --    comp.exp, comp.err = exp, "Constant value must receive at least one argument: names of constants"
                if #ca ~= 1 then
                    comp.exp, comp.err = exp, "Constant value must receive exactly one argument: names of constants"
                    return
                end

                if oldIS and oldI then comp[#comp + 1] = oldI end
                if oldT then comp[#comp + 1] = "return " end

                --for i = 1, #ca do
                --    local name = ca[i]
                local name = ca[1]

                if types.get(name) ~= "ConstantExpression" then
                    --comp.exp, comp.err = exp, "Constant value needs a name for each argument; argument #" .. i .. " is not a name"
                    comp.exp, comp.err = exp, "Constant value needs a name for the first argument"
                    if types.match(name, "Expression") then comp.exp = name end
                    return
                end

                --if i > 1 then
                --    comp[#comp + 1] = ", "
                --end

                local const = constant_names[name.val:upper()]

                if const then
                    comp[#comp + 1] = const
                else
                    --  TODO: Retreive more constants from the compiler, perhaps?
                    --comp.exp, comp.err = exp, "Constant value name #" .. i .. " is invalid or unknown"
                    comp.exp, comp.err = exp, "Constant value name is invalid or unknown: " .. name
                    return
                end
                --end
            else    --  Generic function call.
                if oldIS and oldI then comp[#comp + 1] = oldI end

                if oldT then
                    comp.tail = false
                    comp[#comp + 1] = "return "
                end

                comp[#comp + 1] = string.format("__funcs[%q](", cn.val)

                for i = 1, #ca do
                    local arg = ca[i]
                    local aType = types.get(arg)

                    if i > 1 then
                        comp[#comp + 1] = ", "
                    end

                    comp.in_statement = false

                    if aType == "ConstantExpression" then
                        comp[#comp + 1] = string.format("%q", arg.val)
                    elseif aType == "VariableExpression" then
                        compVarExp(comp, arg)
                    elseif aType == "CommandExpression" then
                        compCmdExp(comp, arg)
                    else
                        error "TODO"
                    end

                    if comp.err then return end
                end

                comp[#comp + 1] = ")"
            end

            comp.tail = oldT
            comp.in_statement = oldIS
            comp.indent = oldI
        else
            error "TODO"
        end
    end

    function compSeqExp(comp, exp)
        local oldT, oldIS = comp.tail, comp.in_statement

        if not oldT or not oldIS then
            comp.exp, comp.err = exp, "Sequence expression has to be the main expression"
            return
        end

        local last = #exp.subexpressions

        comp:push_scope()

        for i = 1, last do
            local sub = exp.subexpressions[i]
            local sType = types.get(sub)

            if i == last then
                comp.tail = oldT
            else
                comp.tail = false
            end

            comp.in_statement = true

            if sType == "CommandExpression" then
                compCmdExp(comp, sub)

                if comp.err then return end
            else
                error "TODO"
            end

            comp[#comp + 1] = "\n"
        end

        comp:pop_scope()

        comp.tail, comp.in_statement = oldT, oldIS
    end

    function compSubExp(comp, exp)
        local oldT, oldIS, oldI = comp.tail, comp.in_statement, comp.indent
        local last = #exp.subexpressions

        if oldI then
            comp.indent = oldI .. "    "
        else
            comp.indent = "    "
        end

        comp:push_scope()

        for i = 1, last do
            local sub = exp.subexpressions[i]
            local sType = types.get(sub)

            if i == last then
                comp.tail = oldT
            else
                comp.tail = false
            end

            comp.in_statement = true

            if sType == "CommandExpression" then
                compCmdExp(comp, sub)

                if comp.err then return end
            else
                error "TODO"
            end

            comp[#comp + 1] = "\n"
        end

        comp:pop_scope()

        comp.tail, comp.in_statement, comp.indent = oldT, oldIS, oldI
    end

    function _compile(comp, exp)
        local eType = types.get(exp)

        if eType == "CommandExpression" then
            return compCmdExp(comp, exp)
        elseif eType == "SequenceExpression" then
            return compSeqExp(comp, exp)
        else
            error "TODO?"
        end
    end

    local scope_meta = { }

    function scope_meta:__index(key)
        if k == "$parent" then return nil end

        local p = rawget(self, "$parent")

        if p then
            return p[key]
        end
    end

    local function generate_scope(parent)
        local res = setmetatable({
            ["$parent"] = false,
            ["$previous"] = false,
            ["$last"] = false,
        }, scope_meta)

        if parent then
            res["$parent"] = parent
            res["$previous"] = parent["$last"]
            parent["$last"] = res
        end

        return res
    end

    local comp_index = { }
    local comp_meta = {
        __index = function(self, key)
            if key == "scope" then
                local s = self["$scopes"]

                return s[#s]
            else
                return comp_index[key]
            end
        end,
    }

    function comp_index:push_scope()
        local s = self["$scopes"]

        s[#s + 1] = generate_scope(s[#s])
    end

    function comp_index:pop_scope()
        local s = self["$scopes"]

        s[#s] = nil
    end

    function compile(exp)
        local eType, comp = types.get(exp), setmetatable({
            in_statement = true,
            tail = true,
            ["$scopes"] = { }
        }, comp_meta)

        comp:push_scope()

        if eType == "CommandExpression" then
            compCmdExp(comp, exp, true)
        elseif eType == "SequenceExpression" then
            compSeqExp(comp, exp)
        else
            error "TODO?"
        end

        if comp.err then
            return false, comp.err, comp.exp
        end

        return table.concat(comp), false, false
    end

    --------------------------------------------------------------------------------

    local LASTRES, LASTSTR

    local function TESTCOMP(str)
        LASTSTR = str
        ERR("Compiling\n", str)

        local res, i, err, exp = parse(str)

        if err then
            ERR("ERROR:\n", err)
            LASTRES = false
        else
            res, err, exp = compile(res)

            if res then
                LASTRES = tostring(res)
                ERR("\n", res)
            else
                ERR("ERROR:\n", err)
                ERR("SITE ", exp.start, "-", exp.finish, ":\n", exp)
                LASTRES = false
            end
        end
    end

    TESTCOMP "func"
    TESTCOMP "func arg"
    TESTCOMP "func arg1 arg2"
    TESTCOMP "func1; func2"
    TESTCOMP "func1 [func2]"
    TESTCOMP "if [a] {b}"
    TESTCOMP "if [a] {b} else {c}"
    TESTCOMP "if [a] {b} elif [c] {d}"
    TESTCOMP "if [a] {b} elif [c] {d} else {e f; g}"
    TESTCOMP "outer [if [a] {b} elif [c] {d} else {e f; g}]"
    TESTCOMP "if [a] {b} else { if [c] {d} }"
    TESTCOMP "if [a] {b} else { if [c] {d}; e }"
    TESTCOMP "if a {b}"
    TESTCOMP "if [a] b"
    TESTCOMP [=[
a [if [b] {
    c [if [d] {
        e [if [f] {
            g h [i j] k;
            l
        }] m
    }
    elif [n] { o }
    else { p }]
}]]=]
    TESTCOMP "if [a] { return b }; c; d; return e [f]"
    TESTCOMP [=[
local foo [do something];
if ['some check' [get foo]]
{
    local bar default\ value;
    set bar foo [baz $bar [const false]];
    # no return here
}
elif ["another check" $'foo']
{
    return [const #[false#]nil] baaaaad
};
work with [get foo]]=]
end

return {
    parse = parse,
    compile = compile,
}

