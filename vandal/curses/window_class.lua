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
local c = require "vandal/ffi/curses"
local types = require "vandal/utils/types"
require "vandal/logging"

local cl = {
    Name = "Window",

    handle = { RETRIEVE = "_handle" },
    derived = { RETRIEVE = "_derived" },
    valid = { },
}

function cl:do_on_move(x, y)
    if self.on_move then
        return self:on_move(x, y)
    end
end

function cl:do_on_resize(w, h)
    if self.on_resize then
        return self:on_resize(w, h)
    end
end

function cl:do_on_draw(x, y, w, h)
    if self.on_draw then
        return self:on_draw(x, y, w, h)
    end
end

function cl:redraw(x, y, w, h)
    self:assert_valid()

    if not self.on_draw then
        return
    end

    if x ~= nil and (type(x) ~= "number" or not types.is_integer(x)) then error "Vandal error: `Window:redraw` X position must be nil or an integer." end
    if y ~= nil and (type(y) ~= "number" or not types.is_integer(y)) then error "Vandal error: `Window:redraw` Y position must be nil or an integer." end
    if w ~= nil and (type(w) ~= "number" or not types.is_integer(w)) then error "Vandal error: `Window:redraw` width must be nil or an integer." end
    if h ~= nil and (type(h) ~= "number" or not types.is_integer(h)) then error "Vandal error: `Window:redraw` height must be nil or an integer." end

    x, y, w, h = x or c.getbegx(self._handle), y or c.getbegy(self._handle), w or c.getmaxx(self._handle), h or c.getmaxy(self._handle)

    if x < 0 or y < 0 or w < 0 or h < 0 then error "Vandal error: `Window:redraw` was supplied invalid values or failed to retrieve them." end

    return self:on_draw(x, y, w, h)
end

function cl.valid:get()
    return not not self._handle
end

function cl:__init(handle, derived)
    types.assert("cdata", handle, "window handle")
    types.assert("boolean", derived, "window.derived")

    self._handle = handle
    self._derived = derived
end

function cl:destroy()
    if self:c_delwin() then
        self._handle = nil
    else
        error "Vandal fatal error: Failed to delete a window!"
    end
end

function cl:assert_valid()
    if not self._handle then
        error "Vandal assertion failure: Window seems to be invalid."
    end
end
local assvld = cl.assert_valid

function cl:assert_derived()
    if not self._derived then
        error "Vandal assertion failure: The requested operation *can only* be performed on derived windows."
    end
end

function cl:assert_not_derived()
    if self._derived then
        error "Vandal assertion failure: The requested operation *cannot* be performed on derived windows."
    end
end

cl.left = {
    get = function(self)
        self:assert_valid()

        return c.getbegx(self._handle)
    end,
    set = function(self, val)
        if type(val) ~= "number" or not types.is_integer(val) then
            error "Vandal error: Window left position must be an integer."
        end

        self:assert_valid()
        self:assert_derived()

        local other = c.getbegy(self._handle)

        if other == -1 then
            error "Vandal error: Failed to retrieve window top position."
        end

        if c.mvwin(self._handle, other, val) == -1 then
            error "Vandal error: Failed to move window."
        end
    end,
}

cl.top = {
    get = function(self)
        self:assert_valid()

        return c.getbegy(self._handle)
    end,
    set = function(self, val)
        if type(val) ~= "number" or not types.is_integer(val) then
            error "Vandal error: Window top position must be an integer."
        end

        self:assert_valid()
        self:assert_derived()

        local other = c.getbegx(self._handle)

        if other == -1 then
            error "Vandal error: Failed to retrieve window left position."
        end

        if c.mvwin(self._handle, val, other) == -1 then
            error "Vandal error: Failed to move window."
        end
    end,
}

cl.x = {
    get = function(self)
        self:assert_valid()
        self:assert_derived()

        return c.getparx(self._handle)
    end,
}

cl.y = {
    get = function(self)
        self:assert_valid()
        self:assert_derived()

        return c.getpary(self._handle)
    end,
}

cl.width = {
    get = function(self)
        self:assert_valid()

        return c.getmaxx(self._handle)
    end,
    set = function(self, val)
        if type(val) ~= "number" or not types.is_integer(val) then
            error "Vandal error: Window width must be an integer."
        end

        self:assert_valid()
        self:assert_derived()

        local other = c.getmaxy(self._handle)

        if other == -1 then
            error "Vandal error: Failed to retrieve window height."
        end

        if c.wresize(self._handle, other, val) == -1 then
            error "Vandal error: Failed to resize window."
        end
    end,
}

cl.height = {
    get = function(self)
        self:assert_valid()

        return c.getmaxy(self._handle)
    end,
    set = function(self, val)
        if type(val) ~= "number" or not types.is_integer(val) then
            error "Vandal error: Window height must be an integer."
        end

        self:assert_valid()
        self:assert_derived()

        local other = c.getmaxx(self._handle)

        if other == -1 then
            error "Vandal error: Failed to retrieve window width."
        end

        if c.wresize(self._handle, val, other) == -1 then
            error "Vandal error: Failed to resize window."
        end
    end,
}

function cl:print(first, str)
    self:assert_valid()

    local fT = types.assert({"string", "table"}, first, "`Window:print` first argument")

    if fT == "string" then
        return c.waddstr(self._handle, first) ~= -1
    else
        --  It's a table.

        types.assert("string", str, "`Window:print` second argument")

        if (first.x == nil) == (first.y == nil) then
            --  This basically checks that they are both either defined or undefined at the same time.

            if first.x and (type(first.x) ~= "number" or type(first.y) ~= "number" or not types.is_integer(first.x) or not types.is_integer(first.y)) then
                --  If they exist, they must be positive integers.

                error "Vandal error: `Window:print` coordinates must be both integers."
            end
        else
            error "Vandal error: `Window:print` coordinates are incomplete."
        end

        if first.limit then
            if type(first.limit) ~= "number" or not types.is_integer(first.limit) then
                error "Vandal error: `Window:print` first argument's `limit` member must be an integer."
            end

            if first.x then
                return c.mvwaddnstr(self._handle, first.y, first.x, str, first.limit) ~= -1
            else
                return c.waddnstr(self._handle, str, first.limit) ~= -1
            end
        else
            if first.x then
                return c.mvwaddstr(self._handle, first.y, first.x, str) ~= -1
            else
                return c.waddstr(self._handle, str) ~= -1
            end
        end
    end
end

function cl:printf(first, ...)
    self:assert_valid()

    local fT = types.assert({"string", "table"}, first, "`Window:printf` first argument")

    if fT == "string" then
        return c.waddstr(self._handle, first:format(...)) ~= -1
    else
        --  It's a table.

        local str = string.format(...)
        --  This will fail if it has to.

        if (first.x == nil) == (first.y == nil) then
            --  This basically checks that they are both either defined or undefined at the same time.

            if first.x and (type(first.x) ~= "number" or type(first.y) ~= "number" or not types.is_integer(first.x) or not types.is_integer(first.y)) then
                --  If they exist, they must be positive integers.

                error "Vandal error: `Window:printf` coordinates must be both integers."
            end
        else
            error "Vandal error: `Window:printf` coordinates are incomplete."
        end

        if first.limit then
            if type(first.limit) ~= "number" or not types.is_integer(first.limit) then
                error "Vandal error: `Window:printf` first argument's `limit` member must be an integer."
            end

            if first.x then
                return c.mvwaddnstr(self._handle, first.y, first.x, str, first.limit) ~= -1
            else
                return c.waddnstr(self._handle, str, first.limit) ~= -1
            end
        else
            if first.x then
                return c.mvwaddstr(self._handle, first.y, first.x, str) ~= -1
            else
                return c.waddstr(self._handle, str) ~= -1
            end
        end
    end
end

function cl:invalidate(y, h)
    self:assert_valid()

    if y ~= nil then
        if type(y) ~= "number" or not types.is_integer(y) then
            error "Vandal error: `Window:invalidate` Y position must be an integer if present."
        end

        if h ~= nil then
            if type(h) ~= "number" or not types.is_integer(h) then
                error "Vandal error: `Window:invalidate` height must be an integer if present."
            end

            return c.touchline(self._handle, y, h) ~= -1
        else
            return c.touchline(self._handle, y, 1) ~= -1
        end
    else
        if h then
            error "Vandal error: `Window:invalidate` must be given a Y position for a height to make sense."
        end

        return c.touchwin(self._handle) ~= -1
    end
end

function cl:refresh()
    self:assert_valid()

    self:c_refresh()
end

function cl:set_cursor(x, y)
    if type(x) ~= "number" or not types.is_integer(x) then
        ERR("Window:set_cursor arg 1: ", type(x), " - ", tostring(x))
        error "Vandal error: First argument to `Window:set_cursor` must be an integer."
    end

    if type(y) ~= "number" or not types.is_integer(y) then
        error "Vandal error: Second argument to `Window:set_cursor` must be an integer."
    end

    self:assert_valid()

    return c.wmove(self._handle, y, x) ~= -1
end

function cl:derive(x, y, w, h)
    if type(x) ~= "number" or not types.is_integer(x) then error "Vandal error: First argument to `Window:derive` must be an integer." end
    if type(y) ~= "number" or not types.is_integer(y) then error "Vandal error: Second argument to `Window:derive` must be an integer." end
    if type(w) ~= "number" or not types.is_integer(w) then error "Vandal error: Third argument to `Window:derive` must be an integer." end
    if type(h) ~= "number" or not types.is_integer(h) then error "Vandal error: Fourth argument to `Window:derive` must be an integer." end

    self:assert_valid()

    local newHan = c.derwin(self._handle, h, w, y, x)

    if newHan == nil or newHan == 0 then
        return nil
    end

    local newWin = classes.Window(newHan, true)

    if not newWin:c_syncok(true) then
        --  Shouldn't really happen.

        newWin:destroy()
    end

    return newWin
end

function cl:move(x, y)
    if type(x) ~= "number" or not types.is_integer(x) then error "Vandal error: First argument to `Window:move` must be an integer." end
    if type(y) ~= "number" or not types.is_integer(y) then error "Vandal error: Second argument to `Window:move` must be an integer." end

    self:assert_valid()
    self:assert_derived()

    return c.mvderwin(self._handle, y, x) ~= -1
end

function cl:resize(w, h)
    if type(w) ~= "number" or not types.is_integer(w) then error "Vandal error: First argument to `Window:resize` must be an integer." end
    if type(h) ~= "number" or not types.is_integer(h) then error "Vandal error: Second argument to `Window:resize` must be an integer." end

    self:assert_valid()

    return c.wresize(self._handle, h, w) ~= -1
end

-- -- -- -- -- -- -- --
--  curses wrappers  --
-- -- -- -- -- -- -- --

local function wrapper1(name)
    local fnc = c[name]

    cl["c_" .. name] = function(self, val)
        --assvld(self)

        return fnc(self._handle, not not val) ~= -1
    end
end

local function wrapper2(name)
    local fnc = c[name]

    if name:sub(1, 1) == 'w' then
        name = name:sub(2)
    end

    cl["c_" .. name] = function(self)
        --assvld(self)

        return fnc(self._handle) ~= -1
    end
end

for fnc in c.DECLS:gmatch "%sint%s+(%w+)%(%s*WINDOW%s*%*%s*,%s*bool%s*%)%s*;" do
    wrapper1(fnc)
end

--for fnc in c.DECLS:gmatch "%sint%s+(%w+)%(%s*WINDOW%s*%*%s*%)%s*;" do
--    print(fnc)
--end

for _, fnc in pairs { "werase", "wclear", "wclrtobot", "wclrtoeol", "wdelch", "wdeleteln", "winsertln", "wrefresh", "wnoutrefresh", "redrawwin", "touchwin", "untouchwin", "scroll", "delwin" } do
    wrapper2(fnc)
end

return classes.create(cl)

