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

local clVar, clPrt, clOvs, clScp, clCmp

--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --
--  Compiler Variable   --
--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --

do
    local cl = {
        Name = "Variable",
    }

    function cl:__init(name, scope, type, decl)
        --  Here scope means global, local, or parameter.
        self.name, self.scope, self.type, self.decl = name, scope, type, decl
        self.lua_identifier = name  --  NOTE: May change later.
    end

    clVar = classes.create(cl)
end

--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --
--  Compiler Function Prototype --
--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --

do
    local cl = {
        Name = "Prototype",
    }

    function cl:__init(name)
        self.name = name

        self.return_types, self.parameters = { }, { }
    end

    function cl:append_return_type(typ)
        self.return_types[#self.return_types + 1] = typ

        return self
    end

    function cl:set_return_type(ind, typ)
        self.return_types[ind] = typ

        return self
    end

    function cl:get_return_type(ind)
        return self.return_types[ind]
    end

    function cl:get_return_count()
        return #self.return_types
    end

    function cl:append_parameter(prm, typ, decl)
        if prm and typ ~= nil then
            types.assert("string", prm, "parameter name")
            types.assert({ "string", "boolean" }, typ, "parameter type")
            types.assert({ "nil", "Expression" }, decl, "parameter declaration")

            prm = clVar(prm, "parameter", typ, decl)
            typ, decl = nil, nil
        else
            types.assert("Parameter", prm, "parameter")
        end

        if self.parameters[prm.name] then
            error("Parameter name conflict: \"" .. prm.name .. "\"")
        end

        self.parameters[#self.parameters + 1] = prm
        self.parameters[prm.name] = #self.parameters

        return self
    end

    function cl:set_parameter(ind, prm, typ, decl)
        types.assert("integer", ind, "parameter index")

        if prm and typ ~= nil then
            types.assert("string", prm, "parameter name")
            types.assert({ "string", "boolean" }, typ, "parameter type")
            types.assert({ "nil", "Expression" }, decl, "parameter declaration")

            prm = clVar(prm, "parameter", typ, decl)
            typ, decl = nil, nil
        else
            types.assert("Parameter", prm, "parameter")
        end

        local old = self.parameters[ind]

        if old then
            self.parameters[old.name] = nil
        end

        self.parameters[ind] = prm
        self.parameters[prm.name] = ind

        return self
    end

    function cl:get_parameter(ind)
        local iType = types.assert({ "string", "integer" }, ind, "parameter index or name")

        if iType == "integer" then
            return self.parameters[ind]
        else
            return self.parameters[self.parameters[ind]]
        end
    end

    function cl:get_parameter_count()
        return #self.parameters
    end

    clPrt = classes.create(cl)
end

--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --
--  Compiler Overload Set  --
--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --

do
    local cl = {
        Name = "OverloadSet",
    }

    function cl:__init(name)
        self.name = name
        self.set = { }
    end

    function cl:add_overload(prt)
        assert(prt.name == self.name)

        self.set[#self.set + 1] = prt

        return self
    end

    function cl:resolve(ptyps, rtyps)
        local res = { }

        for i = 1, #self.set do
            local prt = self.set[i]

            if prt.get_parameter_count() == #ptyps then
            end
        end

        return res
    end

    clPrt = classes.create(cl)
end

--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --
--  Compiler Scope  --
--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --

do
    local cl = {
        Name = "Scope",
    }

    function cl:__index(key)
        local p = rawget(self, "$parent")

        if p then
            return p[key]
        end
    end

    function cl:__init(parent)
        if parent then
            self["$parent"] = parent
            self["$previous"] = parent["$last"]
            parent["$last"] = res
        else
            self["$parent"] = false
            self["$previous"] = false
        end

        self["$last"] = false
    end

    clScp = classes.create(cl)
end

--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --
--  Compiler    --
--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --

do
    local cl = {
        Name = "Compiler",

        scope = { },
    }

    function cl.scope:get()
        local s = self["$scopes"]

        return s[#s]
    end

    function cl:push_scope()
        local s = self["$scopes"]

        s[#s + 1] = clScp(s[#s])
    end

    function cl:pop_scope()
        local s = self["$scopes"]

        s[#s] = nil
    end

    function cl:add(val)
        if type(val) == "string" then
            self[#self + 1] = val
        else
            error("Tried to append a " .. type(val) .. " to the compiler output.")
        end
    end

    function cl:__init(parent)
        self.in_statement = true
        self.tail = true
        self["$scopes"] = { clScp() }
    end

    clCmp = classes.create(cl)
end

local Ctx, Exp, OprExp, ConExp, VarExp, CmdExp, SeqExp, SubExp

--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --
--  Expressions --
--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --

do
    local cl = {
        Name = "Expression",
    }

    function cl:__init()
        self.start, self.finish = -1, -1
        self.type = false
    end

    function cl:__tostring()
        error "Vandal commands error: `__tostring` not implemented for expression class."
    end

    Exp = classes.create(cl)
end

do
    local cl = {
        Name = "OperatorExpression",
        ParentName = "Expression",
    }

    function cl:__init(opr)
        __super(self)

        self.opr = opr
    end

    function cl:__tostring()
        return self.opr
    end

    function cl:eq(other)
        return self.opr == other
    end

    OprExp = classes.create(cl)
end

do
    local cl = {
        Name = "ConstantExpression",
        ParentName = "Expression",
    }

    function cl:__init(val)
        __super(self)

        self.string = val

        self.number = string.parsenumber(val)
        self.boolean = toboolean(val)
    end

    function cl:__tostring()
        return string.quotify(self.string)
    end

    function cl:eq(other)
        return self.string == other and #other == (self.finish - self.start + 1)
    end

    cl.is_escaped = { get = function(self) return #self.string == self.finish - self.start + 1 end }

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

    local straight_to_string_types = { "OperatorExpression", "ConstantExpression", "VariableExpression", "Subexpression" }

    for i = 1, #straight_to_string_types do
        straight_to_string_types[straight_to_string_types[i]] = true
    end

    function cl:__tostring()
        local components = { self.command_name and tostring(self.command_name) or "~INVALID~" }

        for i = 1, #self.args do
            local arg = self.args[i]
            local aType = types.get(arg)

            if straight_to_string_types[aType] then
                components[i + 1] = tostring(arg)
            elseif aType == "CommandExpression" then
                components[i + 1] = '[' .. tostring(arg) .. ']'
            else
                error("Vandal commands error: Unsupported command argument of type " .. aType .. ".")
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
local escape_sequences = { n = '\n', t = '\t', b = '\b', }
local word_characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"
local operator_characters = "!%^&*-+=<>/|~"
local operator_translation = {
    --  Type 1: Left-associative infix binary operator, translates to Lua operator.
    --  Type 2: Non-associative infix binary operator, translates to Lua operator.
    --  Type 3: Associative infix binary operator, translates to Lua function call.
    --  Type 4: Non-associative transitive infix binary operator, translates to complex expression.

    ["+"]  = { "+",        1, "number",  "number"  },
    ["-"]  = { "-",        1, "number",  "number"  },
    ["*"]  = { "*",        1, "number",  "number"  },
    ["/"]  = { "/",        1, "number",  "number"  },
    ["%"]  = { "%",        2, "number",  "number"  },
    ["&"]  = { "bit.band", 3, "number",  "number"  },
    ["|"]  = { "bit.bor",  3, "number",  "number"  },
    ["^"]  = { "bit.bxor", 3, "number",  "number"  },
    ["~"]  = { "..",       1, "string",  "string"  },
    ["&&"] = { " and ",    1, "boolean", "boolean" },
    ["||"] = { " or ",     1, "boolean", "boolean" },
    ["=="] = { "==",       4, nil,       "boolean" },
    ["!="] = { "~=",       4, nil,       "boolean" },
    ["<="] = { "<=",       4, "number",  "boolean" },
    [">="] = { ">=",       4, "number",  "boolean" },
}

for op, e in pairs(operator_translation) do
    e.lua_infix, e.archetype, e.operands_type, e.return_type = unpack(e)

    if e.archetype == 3 then
        e.lua_function = e[1]
    end
end

local constant_names = {
    ["NIL"  ] = { "nil",   true      },
    ["TRUE" ] = { "true",  "boolean" },
    ["FALSE"] = { "false", "boolean" },
}

for kw, e in pairs(constant_names) do
    e.lua_keyword, e.type = unpack(e)
end

do
    local operator_state_machine = {
        false,

        ["+"] = true,   --  Addition
        ["-"] = true,   --  Subtraction
        ["*"] = true,   --  Multiplication
        ["/"] = true,   --  Division
        ["%"] = true,   --  Modulo
        ["^"] = true,   --  XOR
        ["~"] = true,   --  Concatenation (for strings, maybe arrays?)

        ["&"] = {       --  Bit AND, on its own.
            true,
            ["&"] = true,   --  Boolean AND.
        },

        ["|"] = {       --  Bit OR, on its own.
            true,
            ["|"] = true,   --  Boolean OR.
        },

        ["!"] = {       --  Nothing on its own.
            false,
            ["="] = true,   --  Inequality comparison.
        },

        ["="] = {       --  Assignment, on its own.
            true,
            ["="] = true,   --  Equality comparison.
        },

        ["<"] = {       --  Less than, on its own.
            true,
            ["="] = true,   --  Less than or equal to.
        },

        [">"] = {       --  Greater than, on its own.
            true,
            ["="] = true,   --  Greater than or equal to.
        },
    }

    local function parse_operator(line, linelen, i)
        local res, state, start, c = { }, operator_state_machine, i

        while i <= linelen do
            c = line:sub(i, i)

            if not c then break end

            if state[c] then
                state = state[c]
                res[#res + 1] = c

                if state == true then
                    break
                end
            else
                i = i - 1
                --  The current character is not part of the operator.

                break
            end

            i = i + 1
        end

        res = OprExp(table.concat(res))
        res.start = start

        if state == true or (state and state[1]) then
            --  Means this is a valid state to end in.
            res.finish = i

            return res, math.min(i, linelen)
        else
            --  Means this is an intermediate state, or an invalid end state, but not and a valid end state.
            res.finish = i - 1

            return res, i - 1, "Incomplete operator started at #" .. start
        end
    end

    local function parse_word(line, linelen, i)
        local res = { }

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
                elseif word_characters:find(c, 1, true) then
                    res[#res + 1] = c
                else
                    --  This character does not belong to this word.

                    i = i - 1

                    break
                end
            end

            i = i + 1
        end

        res = ConExp(table.concat(res))
        res.start, res.finish = wordStart, math.min(i, linelen)

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
                local oi = i + 1
                res, i, err = parse_word(line, linelen, oi)

                if i < oi then
                    return exp, i, "Illegal character encountered at #" .. i .. ": " .. c .. " - expected word"
                elseif res.string == "" then
                    return exp, i, "Expected identifier for variable name at #" .. i
                end

                local var = VarExp(res.string)
                var.start, var.finish = res.start, res.finish

                res = var

                firstWord = false
            elseif operator_characters:find(c, 1, true) then
                res, i, err = parse_operator(line, linelen, i)

                firstWord = false
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
    TESTPARSE "asd@" FAILLAST()
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
    TESTPARSE "$a" CHECKLAST()
    TESTPARSE "$a b" CHECKLAST()
    TESTPARSE "+ a b" CHECKLAST()
    TESTPARSE "+-" CHECKLAST "+ -"
    TESTPARSE "==<=" CHECKLAST "== <="
    TESTPARSE "<*" CHECKLAST "< *"
    TESTPARSE "!*" FAILLAST()

    --------------------------------------------------------------------------------
end

--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --
--  Compiler    --
--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --

local compile

do
    local _compile, compSubExp, compSeqExp, compCmdExp, compCmdExpPlain

    local conditional_keywords = { ["if"] = "if", ["elif"] = "elseif", ["else"] = "else" }

    local function compConExp(comp, exp, typ)
        local oldIS = comp.in_statement

        if oldIS then
            comp.exp, comp.err = exp, "Constant string is not a valid statement, it is an expression"
            return
        end

        if typ == "number" then
            if not exp.number then
                comp.exp, comp.err = exp, "Constant should be a valid number"
                return
            end

            comp:add(tostring(exp.number))
            exp.type = "number"
        elseif typ == "boolean" then
            if not exp.boolean then
                comp.exp, comp.err = exp, "Constant should be a valid boolean"
                return
            end

            comp:add(tostring(exp.boolean))
            exp.type = "boolean"
        elseif typ == "string" or not typ then
            comp:add(string.format("%q", exp.string))
            exp.type = "string"
        elseif type(typ) == "table" then
            --  More than one possibility.
            local hit = false

            for i = 1, #typ do
                if exp[typ[i]] then
                    hit = true
                    comp:add(tostring(exp[typ[i]]))
                    exp.type = typ[i]
                    break
                end
            end

            if not hit then
                local alternatives = { }

                for i = 1, #typ do
                    if i > 1 then
                        if i == #typ then
                            alternatives[#alternatives + 1] = ", or "
                        else
                            alternatives[#alternatives + 1] = ", "
                        end
                    end

                    alternatives[#alternatives + 1] = typ[i]
                end

                comp.exp, comp.err = exp, "Constant should be a valid " .. table.concat(alternatives)
                return
            end
        else
            error "Invalid constant type required!"
        end
    end

    local function getConst(name)
        return constant_names[name:upper()]
    end

    local function compVarExp(comp, exp, typ)
        local oldIS = comp.in_statement

        if oldIS then
            comp.exp, comp.err = exp, "Variable access is not a valid statement, it is an expression"
            return
        end

        local name = exp.name
        local const = getConst(name)

        if const then
            comp:add(const.lua_keyword)
            exp.type = const.type
        else
            if not name:match "^[a-zA-Z_][0-9a-zA-Z_]*$" then
                comp.exp, comp.err = exp, "Variable name may only contain letters, digits, and underscores; first character may not be a digit"
                return
            end

            local var = comp.scope[name]

            if not var then
                comp.exp, comp.err = exp, "No local defined with the name \"" .. name .. "\""
                return
            end

            comp:add(var.lua_identifier)
        end
    end

    local function compCmdExpOprMulti(comp, exp, arr, opr)
    end

    local function compCmdExpOprPn(comp, exp, arr, oprcnt)
        if oprcnt == 1 and #arr > 3 then
            local opr = arr[1]
            table.remove(arr, 1)
            return compCmdExpOprMulti(comp, exp, arr, opr)
        end

        local stack = { }   --  Stack will store operators.

        for i = 1, #arr do
            local oper = arr[i]
            local oType = types.get(oper)

            if oType == "OperatorExpression" then
                local opr = operator_translation[oper.opr]

                if not opr then
                    comp.exp, comp.err = oper, "Unsupported operator encountered in expression"
                    return
                end

                if opr.archetype == 3 then
                    --  Means this is a function.

                    comp:add(opr.lua_function)
                end

                comp:add "("

                if #stack > 0 then
                    stack[#stack].operands = stack[#stack].operands + 1
                end

                stack[#stack + 1] = { operator = opr, operands = 0 }
            else
                local top = stack[#stack]
                if not top then
                    comp.exp, comp.err = oper, "Unbalanced (excess) operands in Polish Notation expression"
                    return
                end

                top.operands = top.operands + 1

                if oType == "CommandExpression" then
                    compCmdExp(comp, oper)
                elseif oType == "VariableExpression" then
                    compVarExp(comp, oper)
                elseif oType == "ConstantExpression" then
                    compConExp(comp, oper, top.operator.operands_type)
                else
                    comp.exp, comp.err = oper, "Operands in an expression must be command substitutions, variable accesses, or constants"
                    return
                end

                if comp.err then return end

                if top.operands == 1 then
                    if top.operator.archetype == 3 then
                        comp:add ", "
                    else
                        comp:add(top.operator.lua_infix)
                    end
                elseif top.operands == 2 then
                    repeat
                        comp:add ")"

                        local sz = #stack
                        stack[sz] = nil
                        top = stack[sz - 1]
                    until not top or top.operands < 2
                else
                    error "wut?"
                end
            end
        end

        if #stack > 0 then
            comp.exp, comp.err = exp, "Unbalanced (lacking) operands in Polish Notation expression"
        end
    end

    local function compRpnOperand(comp, operand, operator)
        if #operand == 1 then
            local oType = types.get(operand[1])

            if oType == "CommandExpression" then
                compCmdExp(comp, operand[1])
            elseif oType == "VariableExpression" then
                compVarExp(comp, operand[1])
            elseif oType == "ConstantExpression" then
                compConExp(comp, operand[1], operator.operands_type)
            else
                comp.exp, comp.err = oper, "Operands in an expression must be command substitutions, variable accesses, or constants"
                return
            end

            if comp.err then return end
        else
            if operand[1].archetype == 3 then
                --  Means this is a function.

                comp:add(operand[1].lua_function)
            end

            comp:add "("

            for i = 2, #operand do
                if i > 2 then
                    if operand[1].archetype == 3 then
                        comp:add ", "
                    else
                        comp:add(operand[1].lua_infix)
                    end
                end

                compRpnOperand(comp, operand[i], operand[1])
            end

            comp:add ")"
        end
    end

    local function compCmdExpOprRpn(comp, exp, arr, oprcnt)
        if oprcnt == 1 and #arr > 3 then
            local opr = arr[#arr]
            table.remove(arr, #arr)
            return compCmdExpOprMulti(comp, exp, arr, opr)
        end

        local stack = { }   --  Stack will store operands.

        for i = 1, #arr do
            local oper = arr[i]
            local oType = types.get(oper)

            if oType == "OperatorExpression" then
                local opr = operator_translation[oper.opr]

                if not opr then
                    comp.exp, comp.err = oper, "Unsupported operator encountered in expression"
                    return
                end

                if #stack < 2 then
                    comp.exp, comp.err = exp, "Unbalanced (lacking) operands in Reverse Polish Notation expression"
                end

                stack[#stack - 1] = { opr, stack[#stack - 1], stack[#stack] }
                stack[#stack] = nil
            else
                stack[#stack + 1] = { oper }
            end
        end

        if #stack > 1 then
            comp.exp, comp.err = exp, "Unbalanced (excess) operands in Reverse Polish Notation expression"
        end

        return compRpnOperand(comp, stack[1])
    end

    local function compCmdExpOprAsgn(comp, exp, arr)
        for i = 1, #arr - 2 do
            local name = arr[i]
            local nType = types.get(name)

            if nType == "ConstantExpression" then
                if not name.string:match "^[a-zA-Z_][0-9a-zA-Z_]*$" then
                    comp.exp, comp.err = name, "Variable name may only contain letters, digits, and underscores; first character may not be a digit; name #" .. i .. " is invalid"
                    return
                elseif getConst(name.string) then
                    comp.exp, comp.err = name, "Variable name collides with constant name"
                    return
                end

                local var = comp.scope[name.string]

                if not var then
                    comp.exp, comp.err = name, "No variable defined with the name " .. name
                    return
                end

                if i > 1 then
                    comp:add ", "
                end

                comp:add(var.lua_identifier)
            else
                comp.exp, comp.err = exp, "Variable assignment needs names before the assignment operator; operand #" .. i .. " is not a name"
                if types.match(name, "Expression") then comp.exp = name end
                return
            end
        end

        local val = arr[#arr]
        local vType = types.get(val)

        comp:add " = "
        comp.tail, comp.in_statement = false, false

        if vType == "CommandExpression" then
            compCmdExp(comp, val)
        elseif vType == "ConstantExpression" then
            compConExp(comp, val)
        elseif vType == "VariableExpression" then
            compVarExp(comp, val)
        else
            comp.exp, comp.err = exp, "Local writing value must be a constant or a command substitution"
            if types.match(val, "Expression") then comp.exp = val end
            return
        end
    end

    local function compCmdExpOpr(comp, exp)
        local oldT, oldIS, oldI = comp.tail, comp.in_statement, comp.indent
        local ca, arr, oprcnt, fO, lO = exp.args, { exp.command_name }, 0

        fO = types.get(arr[1]) == "OperatorExpression"
        if fO then oprcnt = 1 end

        for i = 1, #ca do
            arr[i + 1] = ca[i]
            lO = types.get(ca[i]) == "OperatorExpression"

            if lO then oprcnt = oprcnt + 1 end
        end

        local isAsgn = not fO and not lO and oprcnt == 1 and #arr >= 3 and arr[#arr - 1].opr == "="

        if isAsgn then
            if not oldIS then
                comp.exp, comp.err = exp, "Assignment is a statement, not an expression"
                return
            end
        else
            if oldIS and oldI then comp:add(oldI) end
            if oldT then comp:add "return " end
        end

        comp.tail, comp.in_statement = false, false

        if fO then
            if lO then
                comp.exp, comp.err = exp, "Operator-enabled expression has an unrecognized structure"
            else
                compCmdExpOprPn(comp, exp, arr, oprcnt)
            end
        elseif lO then
            compCmdExpOprRpn(comp, exp, arr, oprcnt)
        elseif isAsgn then
            compCmdExpOprAsgn(comp, exp, arr)
        else
            comp.exp, comp.err = exp, "Infix operators are not supported yet"
        end

        if comp.err then return end

        comp.tail, comp.in_statement, comp.indent = oldT, oldIS, oldI
    end

    function compCmdExp(comp, exp)
        local cn, ca = exp.command_name, exp.args
        local cnt = types.get(cn)

        if cnt == "ConstantExpression" then
            local oldT, oldIS, oldI = comp.tail, comp.in_statement, comp.indent

            if cn:eq "if" then
                local done, keyword, i = false, "if", 1

                if not oldIS then
                    if oldT then
                        comp:add "return (function()\n"
                    else
                        comp:add "(function()\n"
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

                        if comp.indent then comp:add(comp.indent) end
                        comp:add "else\n"

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

                        if comp.indent then comp:add(comp.indent) end
                        comp:add(conditional_keywords[keyword])
                        comp:add " "

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

                        comp:add " then\n"
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

                        keyword = keyword.string
                    end
                until done

                if comp.indent then comp:add(comp.indent) end
                comp:add "end"

                if not oldIS then
                    comp:add "\n"
                    if oldI then comp:add(oldI) end
                    comp:add "end)()"
                end
            elseif cn:eq "return" then
                if not oldIS then
                    comp.exp, comp.err = exp, "Return statement is not a valid expression, it is a statement"
                    return
                end

                if oldIS and oldI then comp:add(oldI) end

                if oldT then
                    comp:add "return "
                else
                    comp:add "do return "
                end

                for i = 1, #ca do
                    local arg = ca[i]
                    local aType = types.get(arg)

                    if i > 1 then
                        comp:add ", "
                    end

                    comp.tail, comp.in_statement = false, false

                    if aType == "ConstantExpression" then
                        compConExp(comp, arg)
                    elseif aType == "VariableExpression" then
                        compVarExp(comp, arg)
                    elseif aType == "CommandExpression" then
                        compCmdExp(comp, arg)
                    elseif aType ~= "nil" then
                        comp.exp, comp.err = exp, "Return statement needs constants, variable accesses, or command substitutions as its arguments"
                        if types.match(arg, "Expression") then comp.exp = arg end
                        return
                    end

                    if comp.err then return end
                end

                if not oldT then
                    comp:add " end"
                end
            elseif cn:eq "local" then
                local hasAssignment = false

                for i = 1, #ca do
                    if types.get(ca[i]) == "OperatorExpression" then
                        if i == #ca - 1 and ca[i].opr == "=" then
                            hasAssignment = true
                        else
                            comp.exp, comp.err = ca[i], "Local declaration contains stray operator"
                            return
                        end
                    end
                end

                if not oldIS then
                    comp.exp, comp.err = exp, "Local declaration is not a valid expression, it is a statement"
                    return
                end

                if #ca < 1 then
                    comp.exp, comp.err = exp, "Local declaration needs at least one variable name"
                    return
                end

                if oldI then comp:add(oldI) end

                comp:add "local "

                for i = 1, hasAssignment and (#ca - 2) or #ca do
                    local name = ca[i]
                    local nType = types.get(name)

                    if nType == "ConstantExpression" then
                        if not name.string:match "^[a-zA-Z_][0-9a-zA-Z_]*$" then
                            comp.exp, comp.err = name, "Local variable name may only contain letters, digits, and underscores; first character may not be a digit; name #" .. i .. " is invalid"
                            return
                        elseif getConst(name.string) then
                            comp.exp, comp.err = name, "Local variable name collides with constant name"
                            return
                        end

                        if i > 1 then
                            comp:add ", "
                        end

                        local var = clVar(name.string, "local", true, exp)
                        comp.scope[name.string] = var

                        comp:add(var.lua_identifier)
                    else
                        comp.exp, comp.err = exp, "Local assignment needs names before the assignment operator; operand #" .. i .. " is not a name"
                        if types.match(name, "Expression") then comp.exp = name end
                        return
                    end
                end

                if hasAssignment then
                    local val = ca[#ca]
                    local vType = types.get(val)

                    comp:add " = "
                    comp.tail, comp.in_statement = false, false

                    if vType == "CommandExpression" then
                        compCmdExp(comp, val)
                    elseif vType == "ConstantExpression" then
                        compConExp(comp, val)
                    elseif vType == "VariableExpression" then
                        compVarExp(comp, val)
                    else
                        comp.exp, comp.err = exp, "Local variable(s) value(s), if present, must be a constant or a command substitution"
                        if types.match(val, "Expression") then comp.exp = val end
                        return
                    end
                end
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

                if oldIS and oldI then comp:add(oldI) end
                if oldT then comp:add "return " end

                --for i = 1, #ca do
                --    local name = ca[i]
                local name = ca[1]

                if types.get(name) ~= "ConstantExpression" then
                    --comp.exp, comp.err = exp, "Local reading needs a name for each argument; argument #" .. i .. " is not a name"
                    comp.exp, comp.err = exp, "Local reading needs a name"
                    if types.match(name, "Expression") then comp.exp = name end
                    return
                elseif not name.string:match "^[a-zA-Z_][0-9a-zA-Z_]*$" then
                    --comp.exp, comp.err = exp, "Local variable name may only contain letters, digits, and underscores; first character may not be a digit; name #" .. i .. " is invalid"
                    comp.exp, comp.err = exp, "Local variable name may only contain letters, digits, and underscores; first character may not be a digit"
                    return
                end

                local var = comp.scope[name.string]

                if not var then
                    comp.exp, comp.err = exp, "No local defined with the name " .. name
                    return
                end

                --if i > 1 then
                --    comp[#comp + 1] = ", "
                --end

                comp:add(var.lua_identifier)
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

                if oldI then comp:add(oldI) end

                for i = 1, #ca - 1 do
                    local name = ca[i]

                    if types.get(name) ~= "ConstantExpression" then
                        comp.exp, comp.err = exp, "Local writing needs a name for each argument; argument #" .. i .. " is not a name"
                        if types.match(name, "Expression") then comp.exp = name end
                        return
                    elseif not name.string:match "^[a-zA-Z_][0-9a-zA-Z_]*$" then
                        comp.exp, comp.err = exp, "Local variable name may only contain letters, digits, and underscores; first character may not be a digit; name #" .. i .. " is invalid"
                        return
                    end

                    local var = comp.scope[name.string]

                    if not var then
                        comp.exp, comp.err = exp, "No local defined with the name " .. name
                        return
                    end

                    if i > 1 then
                        comp:add ", "
                    end

                    comp:add(var.lua_identifier)
                end

                local val = ca[#ca]
                local vType = types.get(val)

                comp:add " = "
                comp.tail, comp.in_statement = false, false

                if vType == "CommandExpression" then
                    compCmdExp(comp, val)
                elseif vType == "ConstantExpression" then
                    compConExp(comp, val)
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

                if oldIS and oldI then comp:add(oldI) end
                if oldT then comp:add "return " end

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

                local const = constant_names[name.string:upper()]

                if const then
                    comp:add(const.lua_keyword)
                    exp.type = const.type
                else
                    --  TODO: Retreive more constants from the compiler, perhaps?
                    --comp.exp, comp.err = exp, "Constant value name #" .. i .. " is invalid or unknown"
                    comp.exp, comp.err = exp, "Constant value name is invalid or unknown: " .. name
                    return
                end
                --end
            else    --  Generic function call.
                compCmdExpPlain(comp, exp)
            end

            comp.tail = oldT
            comp.in_statement = oldIS
            comp.indent = oldI
        elseif cnt == "VariableExpression" then
            compCmdExpPlain(comp, exp)
        elseif cnt == "OperatorExpression" then
            compCmdExpOpr(comp, exp)
        else
            error "TODO"
        end
    end

    function compCmdExpPlain(comp, exp)
        local cn, ca = exp.command_name, exp.args

        for i = 1, #ca do
            --  Quickly find if this command invocation contains an operator. If this is the case, it is an expression.

            if types.get(ca[i]) == "OperatorExpression" then
                return compCmdExpOpr(comp, exp)
            end
        end

        local cnt = types.get(cn)
        local oldT, oldIS, oldI = comp.tail, comp.in_statement, comp.indent

        if oldIS and oldI then comp:add(oldI) end

        if oldT then
            comp.tail = false
            comp:add "return "
        end

        comp.in_statement = false

        if cnt == "ConstantExpression" then
            comp:add "__funcs["
            compConExp(comp, cn)
            comp:add "]("
        elseif cnt == "VariableExpression" then
            compVarExp(comp, exp)
            comp:add "("
        else
            comp.exp, comp.err = cn, "Command name should be a constant expression, or a variable access"
        end

        if comp.err then return end

        for i = 1, #ca do
            local arg = ca[i]
            local aType = types.get(arg)

            if i > 1 then
                comp:add ", "
            end

            if aType == "ConstantExpression" then
                compConExp(comp, arg)
            elseif aType == "VariableExpression" then
                compVarExp(comp, arg)
            elseif aType == "CommandExpression" then
                compCmdExp(comp, arg)
            else
                comp.exp, comp.err = arg, "Command argument should be a constant expression, a variable access, or a command substitution"
            end

            if comp.err then return end
        end

        comp:add ")"
        comp.tail, comp.in_statement, comp.indent = oldT, oldIS, oldI
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

            comp:add "\n"
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

            comp:add "\n"
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

    function compile(exp)
        local eType, comp = types.get(exp), clCmp()

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

                if exp then
                    ERR("SITE ", exp.start, "-", exp.finish, ":\n", exp)
                end

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
local foo = [do something];
if ['some check' [get foo]]
{
    local bar=default\ value;
    set bar foo [baz $bar [const false]];
    # no return here
}
elif ["another check" $'foo']
{
    return [const #[false#]nil] baaaaad
};
work with [get foo]]=]
    TESTCOMP "~ a + 4 0o10"
    TESTCOMP [=[
local a b;
a b = [foo [~ a b]];
local a b = [bar [| $a $b]]]=]
    TESTCOMP "local a b c; + 0 + [* $b $b] [* 4 [* $a $c]]"
    TESTCOMP "local a b c; 0 [$b $b *] [4 [$a $c *] *] + +"
end

return {
    parse = parse,
    compile = compile,
}

