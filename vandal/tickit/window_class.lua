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
local tk = require "vandal/ffi/tickit"
local types = require "vandal/utils/types"
require "vandal/logging"
local ffi = require "ffi"
local c = tk.C

local cl = {
    Name = "Window",

    handle = { RETRIEVE = "_handle" },
    derived = { RETRIEVE = "_derived" },
    valid = { get = function(self) return not not self._handle end, },
}

function cl:do_on_geometry_change(x, y, w, h)
    self._x, self._y, self._w, self._h = x, y, w, h

    local fnc = self.on_geometry_change 

    if fnc then
        return fnc(self, x, y, w, h)
    end
end

function cl:do_on_draw(x, y, w, h, buf)
    local fnc = self.on_draw

    --ERR("DO ON DRAW ", self, " ", fnc)

    if fnc then
        self._buf = buf

        local ret = fnc(self, x, y, w, h)

        self._buf = false

        return ret
    end
end

function cl:__init(handle, derived, x, y, w, h)
    types.assert("cdata", handle, "window handle")
    types.assert("boolean", derived, "window.derived")

    if derived then
        if type(x) ~= "number" or not types.is_integer(x) then error "Vandal error: `Window` constructor X position must be nil or an integer." end
        if type(y) ~= "number" or not types.is_integer(y) then error "Vandal error: `Window` constructor Y position must be nil or an integer." end
        if type(w) ~= "number" or not types.is_integer(w) then error "Vandal error: `Window` constructor width must be nil or an integer." end
        if type(h) ~= "number" or not types.is_integer(h) then error "Vandal error: `Window` constructor height must be nil or an integer." end
    elseif not (x == nil and y == nil and w == nil and h == nil) then
        error "Vandal error: `Window` constructor's 3rd through 6th arguments must all be integers for derived windows, otherwise nil."
    end

    self._handle, self._derived, self._x, self._y, self._w, self._h = handle, derived, x, y, w, h

    self._buf = false

    vandal.tickit.register_window(self)
end

function cl:__tostring()
    return string.format("[WIN %s | %s | %d,%d,%d,%d]", self._derived and "derived" or "root", tostring(self._handle), self.left, self.top, self.width, self.height)
end

function cl:destroy()
    if self._handle then
        c.tickit_window_close(self._handle)
        c.tickit_window_unref(self._handle)

        vandal.tickit.unregister_window(self)
        self._handle = nil
    else
        error "Vandal error: Tried to delete invalid window!"
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

function cl:assert_drawing()
    if not self._buf then
        error "Vandal assertion failure: The requested operation *can only* be performed while a window is (re)drawing."
    end
end

cl.left = {
    get = function(self)
        self:assert_valid()

        return c.tickit_window_get_abs_geometry(self._handle).left
    end,
    set = function(self, val)
        if type(val) ~= "number" or not types.is_integer(val) then
            error "Vandal error: Window left position must be an integer."
        end

        self:assert_valid()

        local geomA, geom = c.tickit_window_get_abs_geometry(self._handle), c.tickit_window_get_geometry(self._handle)
        geom.left = val - geomA.left + geom.left
        c.tickit_window_set_geometry(self._handle, geom)
    end,
}

cl.top = {
    get = function(self)
        self:assert_valid()

        return c.tickit_window_get_abs_geometry(self._handle).top
    end,
    set = function(self, val)
        if type(val) ~= "number" or not types.is_integer(val) then
            error "Vandal error: Window left position must be an integer."
        end

        self:assert_valid()

        local geomA, geom = c.tickit_window_get_abs_geometry(self._handle), c.tickit_window_get_geometry(self._handle)
        geom.top = val - geomA.top + geom.top
        c.tickit_window_set_geometry(self._handle, geom)
    end,
}

cl.x = {
    get = function(self)
        self:assert_valid()

        return self._x or c.tickit_window_get_geometry(self._handle).left
    end,
    set = function(self, val)
        if type(val) ~= "number" or not types.is_integer(val) then
            error "Vandal error: Window left position must be an integer."
        end

        self:assert_valid()

        local geom = c.tickit_window_get_geometry(self._handle)
        geom.left = val
        c.tickit_window_set_geometry(self._handle, geom)
    end,
}

cl.y = {
    get = function(self)
        self:assert_valid()

        return self._y or c.tickit_window_get_geometry(self._handle).top
    end,
    set = function(self, val)
        if type(val) ~= "number" or not types.is_integer(val) then
            error "Vandal error: Window top position must be an integer."
        end

        self:assert_valid()

        local geom = c.tickit_window_get_geometry(self._handle)
        geom.top = val
        c.tickit_window_set_geometry(self._handle, geom)
    end,
}

cl.width = {
    get = function(self)
        self:assert_valid()

        return self._w or c.tickit_window_get_geometry(self._handle).cols
    end,
    set = function(self, val)
        if type(val) ~= "number" or not types.is_integer(val) then
            error "Vandal error: Window width must be an integer."
        end

        self:assert_valid()

        local geom = c.tickit_window_get_geometry(self._handle)
        geom.cols = val
        c.tickit_window_set_geometry(self._handle, geom)
    end,
}

cl.height = {
    get = function(self)
        self:assert_valid()

        return self._h or c.tickit_window_get_geometry(self._handle).lines
    end,
    set = function(self, val)
        if type(val) ~= "number" or not types.is_integer(val) then
            error "Vandal error: Window height must be an integer."
        end

        self:assert_valid()

        local geom = c.tickit_window_get_geometry(self._handle)
        geom.lines = val
        c.tickit_window_set_geometry(self._handle, geom)
    end,
}

function cl:print(first, str)
    self:assert_drawing()

    local fT = types.assert({"string", "table"}, first, "`Window:print` first argument")

    if fT == "string" then
        return c.tickit_renderbuffer_text(self._buf, first)
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
                return c.tickit_renderbuffer_textn_at(self._buf, first.y, first.x, str, first.limit)
            else
                return c.tickit_renderbuffer_textn(self._buf, str, first.limit)
            end
        else
            if first.x then
                return c.tickit_renderbuffer_text_at(self._buf, first.y, first.x, str)
            else
                return c.tickit_renderbuffer_text(self._buf, str)
            end
        end
    end
end

function cl:_print_lim(lim, str)
    return c.tickit_renderbuffer_textn(self._buf, str, lim)
end

function cl:print_lim(lim, str)
    self:assert_drawing()

    if type(lim) ~= "number" or not types.is_integer(lim) then
        error "Vandal error: `Window:print_lim` first argument  must be an integer."
    end

    types.assert("string", str, "`Window:print_lim` second argument")

    return c.tickit_renderbuffer_textn(self._buf, str, lim)
end

function cl:_print_xy(x, y, str)
    return c.tickit_renderbuffer_text_at(self._buf, y, x, str)
end

function cl:print_xy(x, y, str)
    self:assert_drawing()

    if type(x) ~= "number" or not types.is_integer(x) then
        error "Vandal error: `Window:print_xy` first argument must be an integers."
    end

    if type(y) ~= "number" or not types.is_integer(y) then
        error "Vandal error: `Window:print_xy` second argument must be an integers."
    end

    types.assert("string", str, "`Window:print_xy` third argument")

    return c.tickit_renderbuffer_text_at(self._buf, y, x, str)
end

function cl:_print_xy_lim(x, y, lim, str)
    return c.tickit_renderbuffer_textn_at(self._buf, y, x, str, lim)
end

function cl:print_xy_lim(x, y, lim, str)
    self:assert_drawing()

    if type(x) ~= "number" or not types.is_integer(x) then
        error "Vandal error: `Window:print_xy_lim` first argument must be an integers."
    end

    if type(y) ~= "number" or not types.is_integer(y) then
        error "Vandal error: `Window:print_xy_lim` second argument must be an integers."
    end

    if type(lim) ~= "number" or not types.is_integer(lim) then
        error "Vandal error: `Window:print_xy_lim` third argument  must be an integer."
    end

    types.assert("string", str, "`Window:print_xy_lim` fourth argument")

    return c.tickit_renderbuffer_textn_at(self._buf, y, x, str, lim)
end

function cl:printf(first, ...)
    self:assert_drawing()

    local fT = types.assert({"string", "table"}, first, "`Window:printf` first argument")

    if fT == "string" then
        return c.tickit_renderbuffer_text(self._buf, first:format(...))
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
                return c.tickit_renderbuffer_textn_at(self._buf, first.y, first.x, str, first.limit)
            else
                return c.tickit_renderbuffer_textn(self._buf, str, first.limit)
            end
        else
            if first.x then
                return c.tickit_renderbuffer_text_at(self._buf, first.y, first.x, str)
            else
                return c.tickit_renderbuffer_text(self._buf, str)
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

        local area = ffi.new "TickitRect[1]"
        area[0] = c.tickit_window_get_geometry(self._handle)
        area[0].top = y
        area[0].left = 0

        if h ~= nil then
            if type(h) ~= "number" or not types.is_integer(h) then
                error "Vandal error: `Window:invalidate` height must be an integer if present."
            end

            area[0].lines = h
        else
            area[0].lines = 1
        end

        return c.tickit_window_expose(self._handle, area)
    else
        if h then
            error "Vandal error: `Window:invalidate` must be given a Y position for a height to make sense."
        end

        return c.tickit_window_expose(self._handle, nil)
    end
end

function cl:_set_cursor(x, y)
    c.tickit_window_set_cursor_position(self._handle, y, x)
end

function cl:set_cursor(x, y)
    if type(x) ~= "number" or not types.is_integer(x) then
        error "Vandal error: First argument to `Window:set_cursor` must be an integer."
    end

    if type(y) ~= "number" or not types.is_integer(y) then
        error "Vandal error: Second argument to `Window:set_cursor` must be an integer."
    end

    self:assert_valid()

    c.tickit_window_set_cursor_position(self._handle, y, x)
end

function cl:_derive(x, y, w, h)
    local newHan = c.tickit_window_new(self._handle, ffi.new("TickitRect", y, x, h, w), 0)

    if newHan == nil or newHan == 0 then
        return nil
    else
        return newHan
    end
end

function cl:derive(x, y, w, h)
    if type(x) ~= "number" or not types.is_integer(x) then error "Vandal error: First argument to `Window:derive` must be an integer." end
    if type(y) ~= "number" or not types.is_integer(y) then error "Vandal error: Second argument to `Window:derive` must be an integer." end
    if type(w) ~= "number" or not types.is_integer(w) then error "Vandal error: Third argument to `Window:derive` must be an integer." end
    if type(h) ~= "number" or not types.is_integer(h) then error "Vandal error: Fourth argument to `Window:derive` must be an integer." end

    self:assert_valid()

    local newHan = c.tickit_window_new(self._handle, ffi.new("TickitRect", y, x, h, w), 0)

    if newHan == nil or newHan == 0 then
        return nil
    end

    return classes.Window(newHan, true, x, y, w, h)
end

function cl:move(x, y)
    if type(x) ~= "number" or not types.is_integer(x) then error "Vandal error: First argument to `Window:move` must be an integer." end
    if type(y) ~= "number" or not types.is_integer(y) then error "Vandal error: Second argument to `Window:move` must be an integer." end

    self:assert_valid()
    self:assert_derived()

    c.tickit_window_reposition(self._handle, y, x)
end

function cl:resize(w, h)
    if type(w) ~= "number" or not types.is_integer(w) then error "Vandal error: First argument to `Window:resize` must be an integer." end
    if type(h) ~= "number" or not types.is_integer(h) then error "Vandal error: Second argument to `Window:resize` must be an integer." end

    self:assert_valid()

    c.tickit_window_resize(self._handle, h, w)
end

function cl:reposition(x, y, w, h)
    if type(x) ~= "number" or not types.is_integer(x) then error "Vandal error: First argument to `Window:reposition` must be an integer." end
    if type(y) ~= "number" or not types.is_integer(y) then error "Vandal error: Second argument to `Window:reposition` must be an integer." end
    if type(w) ~= "number" or not types.is_integer(w) then error "Vandal error: Third argument to `Window:reposition` must be an integer." end
    if type(h) ~= "number" or not types.is_integer(h) then error "Vandal error: Fourth argument to `Window:reposition` must be an integer." end

    self:assert_valid()
    self:assert_derived()

    c.tickit_window_set_geometry(self._handle, ffi.new("TickitRect", y, x, h, w))
end

function cl:get_size()
    self:assert_valid()

    local area = ffi.new "TickitRect[1]"
    area[0] = c.tickit_window_get_geometry(self._handle)

    return area[0].cols, area[0].lines
end

function cl:get_position()
    self:assert_valid()

    local area = ffi.new "TickitRect[1]"
    area[0] = c.tickit_window_get_geometry(self._handle)

    return area[0].left, area[0].top
end

function cl:get_geometry()
    self:assert_valid()

    local area = ffi.new "TickitRect[1]"
    area[0] = c.tickit_window_get_geometry(self._handle)

    return area[0].left, area[0].top, area[0].cols, area[0].lines
end

function cl:focus()
    self:assert_valid()

    c.tickit_window_take_focus(self._handle)
end

function cl:_clear(x, y, w, h)
    local rect = ffi.new "TickitRect[1]"

    if x and y and w and h then
        rect[0].top, rect[0].left, rect[0].lines, rect[0].cols = y, x, h, w
    elseif x and y then
        rect[0] = c.tickit_window_get_geometry(self._handle)
        rect[0].top, rect[0].lines = x, y
    else
        rect[0] = c.tickit_window_get_geometry(self._handle)
    end

    c.tickit_renderbuffer_eraserect(self._buf, rect)
end

function cl:clear(x, y, w, h)
    self:assert_drawing()

    local rect = ffi.new "TickitRect[1]"

    if x and y and (w or h) then
        if type(x) ~= "number" or not types.is_integer(x) then error "Vandal error: First argument to `Window:clear` must be an integer." end
        if type(y) ~= "number" or not types.is_integer(y) then error "Vandal error: Second argument to `Window:clear` must be an integer." end
        if type(w) ~= "number" or not types.is_integer(w) then error "Vandal error: Third argument to `Window:clear` must be an integer." end
        if type(h) ~= "number" or not types.is_integer(h) then error "Vandal error: Fourth argument to `Window:clear` must be an integer." end

        rect[0].top, rect[0].left, rect[0].lines, rect[0].cols = y, x, h, w
    elseif x or y then
        --  In this case, it's only lines.

        if type(x) ~= "number" or not types.is_integer(x) then error "Vandal error: First argument to `Window:clear` must be an integer." end
        if type(y) ~= "number" or not types.is_integer(y) then error "Vandal error: Second argument to `Window:clear` must be an integer." end

        rect[0] = c.tickit_window_get_geometry(self._handle)
        rect[0].top, rect[0].lines = x, y
    else
        rect[0] = c.tickit_window_get_geometry(self._handle)
    end

    c.tickit_renderbuffer_eraserect(self._buf, rect)
end

return classes.create(cl)

