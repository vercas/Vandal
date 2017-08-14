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

if vandal.classes then error "wut" end
local classes = { }

local metamethods = {
    "add", "sub", "mul", "div", "mod", "pow", "unm", "concat", "len",
    "eq", "lt", "le", "gc", "tostring", "call"
}

for i = 1, #metamethods do
    metamethods[i] = "__" .. metamethods[i]
end

--  Will actually store the classes.
local classes_store = { }

--  Should be quick.
local propfuncs = {}
local propgets, propsets = { }, { }

--  Will hold the class bases metatables.
local class_metatables = { }

--  Inheritance table.
local inheritance = { }
--  Parents table.
local parents = { }

local function addInheritance(cName, cParent)
    if cParent then
        if inheritance[cParent] then
            table.insert(inheritance[cParent], cName)
        else
            inheritance[cParent] = { cName }
        end

        addInheritance(cName, classes_store[cParent].__parent and classes_store[cParent].__parent.__name)
    else
        if inheritance[true] then
            table.insert(inheritance[true], cName)
        else
            inheritance[true] = { cName }
        end
    end
end

local function addParent(cName, cParent)
    parents[cName] = cParent
end

local function makePropFunc(prop, name, base)
    local pget, pset, povr, pret, ptyp = prop.get, prop.set, prop.OVERRIDE, prop.RETRIEVE, prop.TYPE

    local evname = "__on_update__" .. name

    local fnc

    if povr then
        pset = function(self, val)
            rawset(self, povr, val)
        end

        pget = function(self)
            return rawget(self, povr)
        end

        prop.get, prop.set = pget, pset
    elseif pret then
        pget = function(self)
            return rawget(self, pret)
        end

        prop.get = pget
    end

    if pget then
        if pset then
            if ptyp then
                fnc = function(self, write, val, errlvl)
                    if not errlvl then errlvl = 2 else errlvl = errlvl + 1 end

                    if write then
                        if types.get(val) ~= ptyp then
                            error("Vandal error: Property \"" .. name .. "\" value must be of type " .. tostring(ptyp), errlvl)
                        end

                        pset(self, val, errlvl)

                        if self[evname] then
                            self[evname](self, val, errlvl)
                        end
                    else
                        return pget(self, errlvl)
                    end
                end
            else
                fnc = function(self, write, val, errlvl)
                    if not errlvl then errlvl = 2 else errlvl = errlvl + 1 end

                    if write then
                        pset(self, val, errlvl)

                        if self[evname] then
                            self[evname](self, val, errlvl)
                        end
                    else
                        return pget(self, errlvl)
                    end
                end
            end
        else
            fnc = function(self, write, _val, errlvl)
                if not errlvl then errlvl = 2 else errlvl = errlvl + 1 end

                if write then
                    error("Vandal error: Property \"" .. name .. "\" has no setter!", errlvl)
                else
                    return pget(self, errlvl)
                end
            end
        end
    else
        return false
    end

    propfuncs[prop] = fnc
end

local function spawnClass(cName, cParentName, cBase)
    local cParent, cParentBase

    for k, v in pairs(cBase) do
        if type(v) == "table" then
            makePropFunc(v, k, cBase)
        end
    end

    local __base_new_indexer, __base_indexer

    if cParentName then
        --  By now, they MUST exist.
        cParent = classes_store[cParentName]
        cParentBase = class_metatables[cParentName]

        __base_indexer = cParentBase.__index
        __base_new_indexer = cParentBase.__newindex
    end

    local __new_indexer = cBase.__newindex or __base_new_indexer or rawset
    local __indexer = cBase.__index or __base_indexer or rawget
    local meta, class

    meta = {
        __metatable = "What do you want to do with this class instance's metatable?",

        __index = function(self, key, errlvl)
            local res = cBase[key]
            --  Will look for a property.

            if res == nil then
                return __indexer(self, key, (errlvl or 0) + 1)
            elseif propfuncs[res] then
                return propfuncs[res](self, false, nil, (errlvl or 0) + 1)
            else
                return res
            end
        end,

        __newindex = function(self, key, val, errlvl)
            local res = cBase[key]

            if errlvl then errlvl = errlvl + 1 else errlvl = 1 end

            if res ~= nil and propfuncs[res] then
                return propfuncs[res](self, true, val, errlvl)
            else
                return __new_indexer(self, key, val, errlvl)
            end
        end,
    }

    for i = #metamethods, 1, -1 do
        local mm = metamethods[i]

        if cBase[mm] then
            meta[mm] = cBase[mm]
        elseif cParentBase and cParentBase[mm] then
            meta[mm] = cParentBase[mm]
        end
    end

    local __init = cBase.__init

    if cParent then
        local oldFEnv = getfenv(__init)

        __init = setfenv(__init, setmetatable({ __super = cParent.__init }, { __index = oldFEnv, __newindex = oldFEnv }))
    end

    class = setmetatable({
        __init = __init,    --  Poor attempt to prevent retarded usage by changing that function...
        __base = cBase,
        __name = cName,
        __parent = cParent,
    }, {
        __metatable = "Why do you need to work with this class's metatable?",

        __index = function (cls, name)
            local val = cBase[name]

            if val == nil and cParent then
                return cParent[name]
            else
                return val
            end
        end,

        __call = function (cls, ...)
            local new = setmetatable({ }, meta)

            __init(new, ...)

            return new
        end,
    })

    cBase.__class = class

    class_metatables[cName] = meta

    addInheritance(cName, cParentName)

    return class
end

--  Formal class creation function.
function classes.create(cName, cParentName, cBase)
    if type(cName) == "table" and cParentName == nil and cBase == nil then
        local nam, par = cName.Name, cName.ParentName
        cName.Name, cName.ParentName = nil, nil

        return classes.create(nam, par, cName)
    end

    if type(cName) ~= "string" then
        error("Vandal error: Class name must be a string, not a " .. type(cName) .. ".")
    elseif classes_store[cName] then
        error("Vandal error: Class named \"" .. cName .. "\" already defined.")
    elseif classes[cName] then
        error("Vandal error: Class named \"" .. cName .. "\" conflicts with a function declared in `vandal.classes`.")
    end

    if cParentName ~= nil and type(cParentName) ~= "string" then
        error("Vandal error: Parent class name must be nil or a string, not a " .. type(cParentName) .. ".")
    elseif cParentName and not classes_store[cParentName] then
        error("Vandal error: Specified parent class does not exist. (yet?)")
    end

    if type(cBase) == "function" then
        cBase = cBase()
        --  "Unpack" the function which is supposed to return a table.

        if type(cBase) ~= "table" then
            error("Vandal error: Class base unpacker must return a table, not a " .. type(cBase) .. ".")
        end
    elseif type(cBase) ~= "table" then
        error("Vandal error: Class base must be a table or a function that returns a table (referred to as \"unpacker\"), not a " .. type(cBase) .. ".")
    end

    local class

    class = spawnClass(cName, cParentName, cBase)

    classes_store[cName] = class
    classes_store[class] = cName

    return class
end

--  Returns the name of each class that inherits from the given class.
--  True = all classes.
function classes.get_children(cls)
    if type(cls) == "string" then
        if classes_store[cls] then
            return inheritance[cls] or {}
        else
            error("Vandal error: No class named \"" .. cls .. "\" declared. (yet?)")
        end
    elseif cls == true then
        return inheritance[true] or {}
    else
        error("Vandal error: Argument #1 to `vandal.classes.get_children` must be a valid class name or `true` for listing defined classes.")
    end
end

--  Returns the name of the parent of the given class.
function classes.get_parent(cls)
    if type(cls) == "string" then
        if classes_store[cls] then
            return parents[cls]
        else
            error("Vandal error: No class named \"" .. cls .. "\" declared. (yet?)")
        end
    else
        error("Vandal error: Argument #1 to `vandal.classes.get_parent` must be a valid class name.")
    end
end

--  Prevent malicious changes.
vandal.classes = setmetatable({ }, {
    __index = function(self, key)
        return classes[key] or classes_store[key]
    end,

    __newindex = function()
        error("Vandal error: Invalid operation; cannot change the vandal.classes table.")
    end,

    __metatable = "Nope."
})

return vandal.classes

