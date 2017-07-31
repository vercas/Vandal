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
local unicode = require "vandal/utils/unicode"
require "vandal/logging"

local cl = {
    Name = "TextInput",
    ParentName = "Window",

    scroll_up_glyph     = UNIC "↑|^",
    scroll_down_glyph   = UNIC "↓|v",
    scroll_either_glyph = UNIC "↕|X",
    scroll_left_glyph   = UNIC "|<",
    scroll_right_glyph  = UNIC "|>",
}

function cl:do_on_newline(mod)
    local fnc = self.on_newline

    if fnc then
        return fnc(self, mod) or false
    end
end

function cl:do_on_unhandled_key(ev)
    local fnc = self.on_unhandled_key

    if fnc then
        fnc(self, ev)
    end
end

function cl:do_on_caret_move(x, y)
    local fnc = self.on_caret_move

    if fnc then
        return fnc(self, x, y)
    end
end

function cl:do_on_contents_change()
    local fnc = self.on_contents_change

    if fnc then
        return fnc(self) ~= false
    end
end

function cl:__init(win, x, y, w, h)
    types.assert("Window", win, "TextInput window")

    if type(x) ~= "number" or not types.is_integer(x) then error "Vandal error: `TextInput` constructor X position must be an integer." end
    if type(y) ~= "number" or not types.is_integer(y) then error "Vandal error: `TextInput` constructor Y position must be an integer." end
    if type(w) ~= "number" or not types.is_integer(w) then error "Vandal error: `TextInput` constructor width must be an integer." end
    if type(h) ~= "number" or not types.is_integer(h) then error "Vandal error: `TextInput` constructor height must be an integer." end

    local han = win:_derive(x, y, w, h)

    if not han then
        error "Vandal error: Failed to derive window in order to construct a `TextInput`."
    end

    __super(self, han, true, x, y, w, h)

    self.lines = { { str = "", scroll = 0 } }
    self.cur_line = 1
    self.cur_column = 0
    self.cur_scroll = 1
    self.watermark = false
end

cl._state = {
    get = function(self)
        return { lines = table.deepcopy(self.lines), cur_line = self.cur_line, cur_column = self.cur_column, cur_scroll = self.cur_scroll, watermark = self.watermark }
    end,

    set = function(self, val)
        self.lines, self.cur_line, self.cur_column, self.cur_scroll, self.watermark = val.lines, val.cur_line, val.cur_column, val.cur_scroll, val.watermark
    end,
}

function cl:process_key(ev)
    local key, char, mod = ev.key, ev.char, ev.modifiers
    local line = self.lines[self.cur_line]

    if key == vandal.ui.KEY_CODEPOINT then
        --  Usual printable character.

        if self.cur_column == #line.str then
            line.str = line.str .. char
            self.cur_column = self.cur_column + 1

            if line.scroll < self.cur_column - self._w + 1 then
                line.scroll = self.cur_column - self._w + 1
            end
        elseif self.cur_column > 0 then
            line.str = line.str:sub(1, self.cur_column) .. char .. line.str:sub(self.cur_column + 1)

            self:move_caret_right(false, true)  --  Won't invalidate the line unless scrolled, but it just changed.
        else
            line.str = char .. line.str
            self.cur_column = self.cur_column + 1

            --  No chance that this needs scrolling.
        end

        self:invalidate(self.cur_line - self.cur_scroll)

        self:do_on_contents_change()
    elseif key == vandal.ui.KEY_ENTER then
        --  Enter key.

        if self:do_on_newline(mod) then
            --  Do nothing. When the hook returns true, it means it did its own thing-a-magic.
        else
            local oldLine, newLine = self.lines[self.cur_line], { scroll = 0 }
            self.cur_line = self.cur_line + 1

            table.insert(self.lines, self.cur_line, newLine)

            if mod == vandal.ui.MOD_NONE then
                newLine.str = oldLine.str:sub(self.cur_column + 1)
                oldLine.str = oldLine.str:sub(1, self.cur_column)

                oldLine.scroll = math.max(0, #oldLine.str - self._w + 1)
            else
                newLine.str = ""
            end

            self.cur_column = 0

            if self.cur_line - self.cur_scroll >= self._h then
                self.cur_scroll = self.cur_scroll + 1

                self:invalidate()
            else
                self:invalidate(self.cur_line - self.cur_scroll - 1, self._h)
            end

            self:do_on_contents_change()
        end
    elseif key == vandal.ui.KEY_BACKSPACE then
        --  Erase previous character.

        if self.watermark and self.cur_line == 1 and self.cur_column <= #self.watermark then
            --  Invalid.
        elseif self.cur_column > 0 then
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

            self:invalidate(self.cur_line - self.cur_scroll)

            self:do_on_contents_change()
        elseif self.cur_line > 1 then
            local oldLine, newLine = self.lines[self.cur_line], self.lines[self.cur_line - 1]

            self.cur_column = #newLine.str
            newLine.str = newLine.str .. oldLine.str
            newLine.scroll = math.max(0, math.min(math.floor(self.cur_column - (self._w - 3) / 2), #newLine.str - self._w + 1))

            table.remove(self.lines, self.cur_line)
            self.cur_line = self.cur_line - 1

            if self.cur_scroll > self.cur_line then
                self.cur_scroll = self.cur_scroll - 1

                self:invalidate()
            else
                self:invalidate(self.cur_line - self.cur_scroll, self._h)
            end

            self:do_on_contents_change()
        end
    elseif key == vandal.ui.KEY_DELETE then
        --  Erase next character.

        local line = self.lines[self.cur_line]

        if self.cur_column < #line.str then
            line.str = line.str:sub(1, self.cur_column) .. line.str:sub(self.cur_column + 2)

            self:invalidate(self.cur_line - self.cur_scroll)

            self:do_on_contents_change()
        elseif self.cur_line < #self.lines then
            line.str = line.str .. self.lines[self.cur_line + 1].str

            table.remove(self.lines, self.cur_line + 1)

            self:invalidate(self.cur_line - self.cur_scroll, self._h)

            self:do_on_contents_change()
        end
    elseif key == vandal.ui.KEY_LEFT then
        self:move_caret_left()
    elseif key == vandal.ui.KEY_RIGHT then
        self:move_caret_right()
    elseif key == vandal.ui.KEY_UP and mod == vandal.ui.MOD_NONE then
        self:move_caret_up()
    elseif key == vandal.ui.KEY_UP and mod == vandal.ui.MOD_CONTROL then
        self:scroll_up()
    elseif key == vandal.ui.KEY_DOWN and mod == vandal.ui.MOD_NONE then
        self:move_caret_down()
    elseif key == vandal.ui.KEY_DOWN and mod == vandal.ui.MOD_CONTROL then
        self:scroll_down()
    elseif key == vandal.ui.KEY_HOME then
        --  Move caret to start of line, then scroll to beginning.
        local startX = (self.watermark and self.cur_line == 1) and #self.watermark or 0

        if self.cur_column > startX then
            local line = self.lines[self.cur_line]

            if self.cur_column > line.scroll + 1 and line.scroll > 0 then
                self.cur_column = line.scroll + 1
            else
                self.cur_column = startX

                if line.scroll > 0 then
                    line.scroll = 0
                    self:invalidate(self.cur_line - self.cur_scroll)
                end
            end

            self:do_on_caret_move(self.cur_column, self.cur_line)
        end
    elseif key == vandal.ui.KEY_END then
        --  Move caret to end of line, then scroll to end.

        local line = self.lines[self.cur_line]

        if self.cur_column < #line.str then
            local lspw = line.scroll + self._w
            --  Line Scroll Plus Width...

            if self.cur_column < lspw - 3 and #line.str > lspw - 1 then
                self.cur_column = lspw - 3
            else
                self.cur_column = #line.str

                local newS = math.max(0, #line.str - self._w + 1)

                if line.scroll ~= newS then
                    line.scroll = newS
                    self:invalidate(self.cur_line - self.cur_scroll)
                end
            end

            self:do_on_caret_move(self.cur_column, self.cur_line)
        end
    else
        self:do_on_unhandled_key(ev)

        return true
    end

    self:_set_cursor(self.cur_column - self.lines[self.cur_line].scroll, self.cur_line - self.cur_scroll)

    return true
end

function cl:process_event(ev)
    if ev.type == IET_KB then
        return self:process_key(ev)
    else
        --  TODO: Mouse support?
        return false
    end
end

function cl:on_draw(x, y, w, h)
    self:_clear(x, y, w, h)

    for i = y, math.min(y + h - 1, #self.lines - self.cur_scroll) do
        local line = self.lines[self.cur_scroll + i]
        local gL, gR = line.scroll > 0, #line.str - line.scroll > self._w - 1
        local tStart, tEnd = math.max(x, gL and 1 or 0), math.min(x + w, self._w - (gR and 2 or 1))
        local tLen = tEnd - tStart

        if gL and x == 0 then
            self:_print_xy(0, i, self.scroll_left_glyph)
        end

        if gR and x + w > self._w - 2 then
            self:_print_xy(self._w - 2, i, self.scroll_right_glyph)
        end

        self:_print_xy_lim(tStart, i, tLen, line.str:sub(line.scroll + 1 + tStart, line.scroll + tEnd))
    end

    if x + w >= self._w then
        --  If the last column was invalidated as well...

        if self._h > 1 then
            if y == 0 and self.cur_scroll > 1 then
                self:_print_xy(self._w - 1, 0, self.scroll_up_glyph)
            end

            if y + h >= self._h and #self.lines - self.cur_scroll - self._h >= 0 then
                self:_print_xy(self._w - 1, self._h - 1, self.scroll_down_glyph)
            end
        elseif #self.lines > 1 then
            --  Only one line, means no other line could've been invalidated.

            local glyph

            if self.cur_scroll == 1 then
                glyph = self.scroll_down_glyph
            elseif self.cur_scroll == #self.lines then
                glyph = self.scroll_up_glyph
            else
                glyph = self.scroll_either_glyph
            end

            self:_print_xy(self._w - 1, 0, glyph)
        end
    end
end

function cl:on_geometry_change(x, y, w, h)
    if #self.lines - self.cur_scroll < h - 1 then
        self.cur_scroll = #self.lines - h + 1
    end

    local line = self.lines[self.cur_line]

    if self.cur_column > line.scroll + w - 3 then
        line.scroll = self.cur_column - w + 3
    end
end

function cl:get_caret_position()
    return self.cur_column - self.lines[self.cur_line].scroll, self.cur_line - self.cur_scroll
end

function cl:get_caret()
    return self.cur_column, self.cur_line
end

function cl:set_caret(x, y, skipScroll, skipRedraw)
    self.cur_line = math.clamp(1, y, #self.lines)
    self.cur_column = math.clamp((self.watermark and y == 1) and #self.watermark or 0, x, #self.lines[self.cur_line].str)

    if not skipScroll then
        self:scroll_to_caret(true, true, skipRedraw)
    end

    self:_set_cursor(self.cur_column - self.lines[self.cur_line].scroll, self.cur_line - self.cur_scroll)

    self:do_on_caret_move(self.cur_column, self.cur_line)
end

function cl:move_caret_left(skipScroll, skipRedraw)
    if self.cur_column <= ((self.watermark and self.cur_line == 1) and #self.watermark or 0) then
        return false
    end

    local line = self.lines[self.cur_line]

    self.cur_column = self.cur_column - 1

    if self.cur_column <= line.scroll and line.scroll > 0 and not skipScroll then
        --  Should scroll left.
        line.scroll = self.cur_column - 1

        if not skipRedraw then
            self:invalidate(self.cur_line - self.cur_scroll)
        end
    end

    self:do_on_caret_move(self.cur_column, self.cur_line)

    return true
end

function cl:move_caret_right(skipScroll, skipRedraw)
    local line = self.lines[self.cur_line]

    if self.cur_column == #line.str then
        return false
    end

    self.cur_column = self.cur_column + 1

    if line.scroll < self.cur_column - self._w + 3 and self.cur_column < #line.str - 1 and not skipScroll then
        --  Note that the position was incremented at this point, that's why there's a `2` at the end. If it wasn't, it would be a `3`.

        line.scroll = self.cur_column - self._w + 3

        if not skipRedraw then
            self:invalidate(self.cur_line - self.cur_scroll)
        end
    end

    self:do_on_caret_move(self.cur_column, self.cur_line)

    return true
end

function cl:move_caret_up(skipScroll, skipRedraw)
    if self.cur_line > 1 then
        local oldLine = self.lines[self.cur_line]
        self.cur_line = self.cur_line - 1
        local newLine = self.lines[self.cur_line]

        local inval = false

        if self.cur_column == 0 then
            if newLine.scroll > 0 then
                newLine.scroll = 0
                inval = true
            end
        elseif self.cur_column == #oldLine.str then
            self.cur_column = #newLine.str

            local newS = math.max(0, self.cur_column - self._w + 2)

            if newLine.scroll ~= newS then
                newLine.scroll = newS
                inval = true
            end
        else
            self.cur_column = newLine.scroll + math.min(self.cur_column - oldLine.scroll, #newLine.str - newLine.scroll)
        end

        if self.watermark and self.cur_line == 1 and self.cur_column < #self.watermark then
            self.cur_column = #self.watermark
        end

        if (skipScroll or not self:scroll_to_caret(true, false, skipRedraw)) and inval and not skipRedraw then
            --  Either scrolling is skipped, or was unnecessary. Also, redrawing is required and allowed.
            --  In this case, only the now-selected line needs to be invalidated.

            self:invalidate(self.cur_line - self.cur_scroll)
        end

        self:do_on_caret_move(self.cur_column, self.cur_line)
    end
end

function cl:move_caret_down(skipScroll, skipRedraw)
    if self.cur_line < #self.lines then
        local oldLine = self.lines[self.cur_line]
        self.cur_line = self.cur_line + 1
        local newLine = self.lines[self.cur_line]

        local inval = false

        if self.cur_column == 0 then
            if newLine.scroll > 0 then
                newLine.scroll = 0
                inval = true
            end
        elseif self.cur_column == #oldLine.str then
            self.cur_column = #newLine.str

            local newS = math.max(0, self.cur_column - self._w + 2)

            if newLine.scroll ~= newS then
                newLine.scroll = newS
                inval = true
            end
        else
            self.cur_column = newLine.scroll + math.min(self.cur_column - oldLine.scroll, #newLine.str - newLine.scroll)
        end

        if (skipScroll or not self:scroll_to_caret(true, false, skipRedraw)) and inval and not skipRedraw then
            self:invalidate(self.cur_line - self.cur_scroll)
        end

        self:do_on_caret_move(self.cur_column, self.cur_line)
    end
end

function cl:scroll_to_caret(includeVertical, includeHorizontal, skipRedraw)
    local hasScrolled = 0

    if includeVertical then
        if self.cur_scroll > self.cur_line then
            --  Needs to scroll up.

            self.cur_scroll = self.cur_line
            hasScrolled = 2
        elseif self.cur_scroll <= self.cur_line - self._h then
            --  Needs to scroll down.

            self.cur_scroll = self.cur_line - self._h + 1
            hasScrolled = 2
        end
    end

    if includeHorizontal then
        local line, newS = self.lines[self.cur_line]

        if line.scroll > 0 and line.scroll >= self.cur_column then
            line.scroll = self.cur_column - 1
            hasScrolled = hasScrolled + 1
        elseif line.scroll < self.cur_column - self._w + 3 and self.cur_column < #line.str - 1 then
            line.scroll = self.cur_column - self._w + 3
            hasScrolled = hasScrolled + 1
        end
    end

    if not skipRedraw then
        if hasScrolled >= 2 then
            self:invalidate()   --  All of it, because it's scrolling vertically.
        elseif hasScrolled == 1 then
            self:invalidate(self.cur_line - self.cur_scroll)
        end
    end

    return hasScrolled > 0
end

function cl:scroll_up(skipRedraw)
    if self.cur_scroll > 1 then
        self.cur_scroll = self.cur_scroll - 1

        if self.cur_scroll <= self.cur_line - self._h then
            self:move_caret_up(true, true)
        end

        if not skipRedraw then
            self:invalidate()
        end

        return true
    else
        return false
    end
end

function cl:scroll_down(skipRedraw)
    if self.cur_scroll <= #self.lines - self._h then
        self.cur_scroll = self.cur_scroll + 1

        if self.cur_scroll > self.cur_line then
            self:move_caret_down(true, true)
        end

        if not skipRedraw then
            self:invalidate()
        end

        return true
    else
        return false
    end
end

local contentsMetatable = {
    __metatable = "TextInput Contents",

    __tostring = function(self)
        return self.text
    end,
}

function cl:get_contents(includeNav)
    local text = { }

    for i = 1, #self.lines do
        text[i] = self.lines[i].str
    end

    if self.watermark then
        text[1] = text[1]:sub(#self.watermark + 1)
    end

    text = table.concat(text, "\n")

    if includeNav then
        local cont = setmetatable({ text = text, watermark = self.watermark }, contentsMetatable)

        cont.caret_x, cont.caret_y = self:get_caret()
        cont.scroll_vertical = self.cur_scroll

        if self.watermark and cont.caret_y == 1 then
            cont.caret_x = cont.caret_x - #self.watermark
        end

        return cont
    else
        return text
    end
end

function cl:set_contents(cont)
    local cType = types.assert({"table", "string"}, cont, "contents")
    local text = cont

    if cType == "table" then
        text = cont.text
    end

    self.lines = { }

    for line in text:iteratesplit("\r?\n\r?", false) do
        table.insert(self.lines, { str = line, scroll = 0 })
    end

    if cType == "table" then
        if cont.watermark then
            self.watermark = cont.watermark
            self.lines[1].str = self.watermark .. self.lines[1].str
        else
            self.watermark = false
        end

        if cont.scroll_vertical then
            self.cur_scroll = cont.scroll_vertical
        else
            self.cur_scroll = 1
        end

        if cont.caret_x and cont.caret_y then
            local x = cont.caret_x

            if cont.watermark and cont.caret_y == 1 then
                x = x + #cont.watermark
            end

            self:set_caret(x, cont.caret_y, false, true) --  Needs to redraw everything anyway, so it skips redraw. But it adjusts scrolling.
        else
            self:set_caret(0, 1, true, true)    --  No scroll, no redraw.
        end
    else
        if self.watermark then
            self.lines[1].str = self.watermark .. self.lines[1].str
        end

        self.cur_scroll = 1
        self:set_caret(0, 1, true, true)    --  Accounts for watermark if present.
    end

    self:invalidate()
end

function cl:clear_contents(watermark)
    if types.assert({"nil", "string"}, watermark, "watermark") == "string" and #watermark == 0 then
        watermark = nil
    end

    self.watermark = watermark or false
    self.lines = { { str = watermark or "", scroll = 0 } }
    self.cur_scroll = 1
    self:set_caret(0, 1, true, true)
    self:invalidate()
end

return classes.create(cl)

