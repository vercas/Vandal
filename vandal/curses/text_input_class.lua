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
local curses = require "vandal/curses"
local c = require "vandal/ffi/curses"
local types = require "vandal/utils/types"
require "vandal/logging"

local cl = {
    Name = "TextInput",

    scroll_up_glyph     = "↑", --"∧",
    scroll_down_glyph   = "↓", --"∨",
    scroll_either_glyph = "↕", --"X",
    scroll_left_glyph   = "", --"←",
    scroll_right_glyph  = "",
}

local function mirror_property(name)
    cl[name] = {
        get = function(self)
            return self._win[name]
        end,
        set = function(self, val)
            self._win[name] = val
        end,
    }
end

mirror_property "left"
mirror_property "right"
mirror_property "width"
mirror_property "height"
mirror_property "x"
mirror_property "y"
mirror_property "valid"
mirror_property "handle"
mirror_property "derived"

function cl:assert_valid()
    return self._win and self._win:assert_valid()
end

function cl:__init(win, x, y, w, h)
    types.assert("Window", win, "TextInput window")

    if (x == nil) ~= (y == nil) or (y == nil) ~= (w == nil) or (w == nil) ~= (h == nil) then
        error "Vandal error: `TextInput` constructor's 2nd through 5th arguments must all be integers or nil."
    end

    if x then
        if type(x) ~= "number" or not types.is_integer(x) then error "Vandal error: `TextInput` constructor X position must be nil or an integer." end
        if type(y) ~= "number" or not types.is_integer(y) then error "Vandal error: `TextInput` constructor Y position must be nil or an integer." end
        if type(w) ~= "number" or not types.is_integer(w) then error "Vandal error: `TextInput` constructor width must be nil or an integer." end
        if type(h) ~= "number" or not types.is_integer(h) then error "Vandal error: `TextInput` constructor height must be nil or an integer." end

        self._win = win:derive(x, y, w, h)

        if not self._win then
            error "Vandal error: Failed to derive window in order to construct a `TextInput`."
        end
    else
        win:assert_valid()

        self._win = win

        x, y, w, h = c.getbegx(win._handle), c.getbegy(win._handle), c.getmaxx(win._handle), c.getmaxy(win._handle)

        if x < 0 or y < 0 or w < 0 or h < 0 then
            error "Vandal error: Failed to retrieve window boundaries for `TextInput` construction."
        end
    end

    self._x, self._y, self._w, self._h, self._handle = x, y, w, h, self._win._handle

    self.lines = { { str = "", scroll = 0 } }
    self.cur_line = 1
    self.cur_column = 0
    self.cur_scroll = 1

    function win:on_draw(x, y, w, h)
        return self:on_draw(x, y, w, h)
    end
end

function cl:process_key(key, char)
    local line = self.lines[self.cur_line]

    if key == curses.KEY_CODEPOINT then
        --  Usual printable character.

        if self.cur_column == #line.str then
            line.str = line.str .. char

            if self.cur_column >= self._w - 2 then
                --  Needs to scroll.
                line.scroll = line.scroll + 1
            end
        elseif self.cur_column > 0 then
            line.str = line.str:sub(1, self.cur_column) .. char .. line.str:sub(self.cur_column + 1)
        else
            line.str = char .. line.str
        end

        self:on_draw()

        self.cur_column = self.cur_column + 1
        --self._win:refresh()
    elseif key == curses.KEY_ENTER then
        --  Enter key.

        local oldLine, newLine = self.lines[self.cur_line], { scroll = 0 }
        self.cur_line = self.cur_line + 1

        table.insert(self.lines, self.cur_line, newLine)

        newLine.str = oldLine.str:sub(self.cur_column + 1)
        oldLine.str = oldLine.str:sub(1, self.cur_column)

        self.cur_column = 0
        oldLine.scroll = math.max(0, #oldLine.str - self._w + 2)

        if self.cur_line - self.cur_scroll >= self._h then
            self.cur_scroll = self.cur_scroll + 1
        end

        self:on_draw()
    elseif key == curses.KEY_BACKSPACE then
        --  Erase previous character.

        if self.cur_column > 0 then
            local line = self.lines[self.cur_line]

            line.str = line.str:sub(1, self.cur_column - 1) .. line.str:sub(self.cur_column + 1)
            self.cur_column = self.cur_column - 1

            if line.scroll > 0 then
                if self.cur_column == line.scroll then
                    line.scroll = math.max(0, line.scroll - 2)
                elseif self.cur_column == line.scroll + 1 then
                    line.scroll = line.scroll - 1
                end
            end

            self:on_draw()
        elseif self.cur_line > 1 then
            local oldLine, newLine = self.lines[self.cur_line], self.lines[self.cur_line - 1]

            self.cur_column = #newLine.str
            newLine.scroll = math.max(0, math.floor(#newLine.str - (self._w - 3) / 2))
            newLine.str = newLine.str .. oldLine.str

            table.remove(self.lines, self.cur_line)
            self.cur_line = self.cur_line - 1

            if self.cur_scroll > self.cur_line then
                self.cur_scroll = self.cur_scroll - 1
            end

            self:on_draw()
        end
    elseif key == curses.KEY_DELETE then
        --  Erase next character.

        local line = self.lines[self.cur_line]

        if self.cur_column < #line.str then
            line.str = line.str:sub(1, self.cur_column) .. line.str:sub(self.cur_column + 2)

            self:on_draw()
        elseif self.cur_line < #self.lines then
            line.str = line.str .. self.lines[self.cur_line + 1].str

            table.remove(self.lines, self.cur_line + 1)

            self:on_draw()
        end
    elseif key == curses.KEY_LEFT then
        --  Move cursor left.

        if self.cur_column == line.scroll + 1 and line.scroll > 0 then
            --  Gotta scroll left.
            line.scroll = line.scroll - 1
            self.cur_column = self.cur_column - 1

            self:on_draw()
        elseif self.cur_column > line.scroll then
            self.cur_column = self.cur_column - 1
        end
    elseif key == curses.KEY_RIGHT then
        --  Move cursor right.

        if self.cur_column < #line.str then
            self.cur_column = self.cur_column + 1

            if self.cur_column - line.scroll > self._w - 3 and self.cur_column ~= #line.str then
                line.scroll = line.scroll + 1

                self:on_draw()
            end
        end
    elseif key == curses.KEY_UP then
        --  Move cursor up.

        if self.cur_line > 1 then
            local oldLine = self.lines[self.cur_line]
            self.cur_line = self.cur_line - 1
            local newLine = self.lines[self.cur_line]

            if self.cur_column == 0 then
                newLine.scroll = 0
            elseif self.cur_column == #oldLine.str then
                self.cur_column = #newLine.str
                newLine.scroll = math.max(0, self.cur_column - self._w + 2)
            else
                self.cur_column = newLine.scroll + math.min(self.cur_column - oldLine.scroll, #newLine.str - newLine.scroll)
            end

            if self.cur_scroll > self.cur_line then
                self.cur_scroll = self.cur_line
            end

            self:on_draw()
        end
    elseif key == curses.KEY_DOWN then
        --  Move cursor down.

        if self.cur_line < #self.lines then
            local oldLine = self.lines[self.cur_line]
            self.cur_line = self.cur_line + 1
            local newLine = self.lines[self.cur_line]

            if self.cur_column == 0 then
                newLine.scroll = 0
            elseif self.cur_column == #oldLine.str then
                self.cur_column = #newLine.str
                newLine.scroll = math.max(0, self.cur_column - self._w + 2)
            else
                self.cur_column = newLine.scroll + math.min(self.cur_column - oldLine.scroll, #newLine.str - newLine.scroll)
            end

            if self.cur_scroll <= self.cur_line - self._h then
                self.cur_scroll = self.cur_scroll + 1
            end

            self:on_draw()
        end
    elseif key == curses.KEY_HOME then
        --  Move cursor to start of line, then scroll to beginning.

        if self.cur_column > 0 then
            local line = self.lines[self.cur_line]

            if self.cur_column > line.scroll + 1 then
                self.cur_column = line.scroll + 1
            else
                self.cur_column = 0
                line.scroll = 0

                self:on_draw()
            end
        end
    elseif key == curses.KEY_END then
        --  Move cursor to end of line, then scroll to end.

        local line = self.lines[self.cur_line]

        if self.cur_column < #line.str then
            if self.cur_column < line.scroll + self._w - 3 then
                self.cur_column = line.scroll + self._w - 3
            else
                self.cur_column = #line.str
                line.scroll = #line.str - self._w + 2

                self:on_draw()
            end
        end
    end

    return true
end

function cl:process_event(ev)
    if ev.type == IET_KB then
        return self:process_key(ev.key, ev.char)
    else
        --  TODO: Mouse support?
        return false
    end
end

function cl:on_draw(x, y, w, h)
    if x then
        self._x, self._y, self._w, self._h = x, y, w, h
    else
        --  Just making things quicker.

        x, y, w, h = self._x, self._y, self._w, self._h
    end

    if c.werase(self._handle) == -1 then
        error "Vandal error: Failed to erase text input window."
    end

    for i = 0, h - 1 do
        local line = self.lines[self.cur_scroll + i]
        local gL = line.scroll > 0
        local gR = #line.str - line.scroll > w - 1

        if gL and c.mvwaddstr(self._handle, i, 0, self.scroll_left_glyph) == -1 then
            error "Vandal error: Failed to draw left scrolling glyph on text input redraw."
        end

        if gR and c.mvwaddstr(self._handle, i, w - 2, self.scroll_right_glyph) == -1 then
            ERR("Right scroll glyph: ", i, ", ", w - 2)
            error "Vandal error: Failed to draw right scrolling glyph on text input redraw."
        end

        if c.mvwaddnstr(self._handle, i, gL and 1 or 0, line.str:sub(line.scroll + (gL and 2 or 1)), w - (gL and 2 or 1) - (gR and 1 or 0)) == -1 then
            error "Vandal error: Failed to draw line on text input redraw."
        end
    end

    if h > 1 then
        if self.cur_scroll > 1 and c.mvwinsstr(self._handle, 0, w - 1, self.scroll_up_glyph) == -1 then
            error "Vandal error: Failed to draw up arrow on text input redraw."
        end

        if #self.lines - self.cur_scroll - h >= 0 and c.mvwinsstr(self._handle, h - 1, w - 1, self.scroll_down_glyph) == -1 then
            error "Vandal error: Failed to draw down arrow on text input redraw."
        end
    elseif #self.lines > 1 then
        local glyph

        if self.cur_scroll == 1 then
            glyph = self.scroll_down_glyph
        elseif self.cur_scroll == #self.lines then
            glyph = self.scroll_up_glyph
        else
            glyph = self.scroll_either_glyph
        end

        if c.mvwinsstr(self._handle, 0, w - 1, glyph) == -1 then
            ERR("Single arrow glyph: ", w - 1, ", ", glyph)
            error "Vandal error: Failed to draw scrolling glyph on single-line text input redraw."
        end
    end
end

function cl:redraw(...)
    return self._win:redraw()
end

function cl:get_cursor_position()
    return self.cur_column - self.lines[self.cur_line].scroll, self.cur_line - self.cur_scroll
end

function cl:get_cursor_position_abs()
    return self._x + self.cur_column - self.lines[self.cur_line].scroll, self._y + self.cur_line - self.cur_scroll
end

return classes.create(cl)

