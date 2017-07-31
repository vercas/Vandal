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

IET_min = 1
IET_KB      = 1  --  Keyboard
IET_MS      = 2  --  Mouse
IET_RESIZE  = 3  --  Terminal resized
IET_max = 3

IEMB_min, IEMB_L, IEMB_R, IEMB_M, IEMB_max = 1, 1, 2, 3, 3
--  Left, right and middle mouse buttons.

local cl = {
    Name = "InputEvent",

    type = { RETRIEVE = "_type", },

    x = {
        get = function(self)
            if self._type == IET_MS then
                return self._a
            else
                error "Vandal error: Input event does not have this property."
            end
        end,
    },

    y = {
        get = function(self)
            if self._type == IET_MS then
                return self._b
            else
                error "Vandal error: Input event does not have this property."
            end
        end,
    },

    button = {
        get = function(self)
            if self._type == IET_MS then
                return self._c
            else
                error "Vandal error: Input event does not have this property."
            end
        end,
    },

    key = {
        get = function(self)
            if self._type == IET_KB then
                return self._a
            else
                error "Vandal error: Input event does not have this property."
            end
        end,
    },

    char = {
        get = function(self)
            if self._type == IET_KB then
                return self._b
            else
                error "Vandal error: Input event does not have this property."
            end
        end,
    },

    modifiers = {
        get = function(self)
            if self._type == IET_KB then
                return self._c
            else
                error "Vandal error: Input event does not have this property."
            end
        end,
    },
}

function cl:__init(typ, a, b, c, d)
    if type(typ) ~= "number" or not types.is_integer(typ) or typ < IET_min or typ > IET_max then
        error "Vandal error: Input event type must be one of the valid constant values."
    end

    self._type = typ

    if typ == IET_MS then
        if type(a) ~= "number" or a < 0 or not types.is_integer(a) then
            error "Vandal error: Input event of type mouse must get X coordinates (positive integer) as second argument."
        end

        if type(b) ~= "number" or b < 0 or not types.is_integer(b) then
            error "Vandal error: Input event of type mouse must get Y coordinates (positive integer) as third argument."
        end

        if type(c) ~= "number" or not types.is_integer(c) or c < IEMB_min or c > IEMB_max then
            error "Vandal error: Input event of type mouse must get button number (predefined constant integer) as fourth argument."
        end

        self._a, self._b, self._c = a, b, c
    elseif typ == IET_KB then
        if a == vandal.ui.KEY_CODEPOINT then
            if type(b) ~= "string" then
                error "Vandal error: Input event of type keyboard codepoint must receive a UTF-8 sequence as third argument."
            end
        else
            if b ~= nil then
                error "Vandal error: Input event of type keyboard non-codepoint must not receive a third argument. It must be nil."
            end
        end

        if not types.is_int_or_long(c) then
            error("Vandal error: Input event of type keyboard codepoint must receive a modifier as fourth argument. \"" .. tostring(c) .. "\" is invalid.")
        end

        self._a, self._b, self._c = a, b, c
    end
end

function cl:__tostring()
    if self._type == IET_KB then
        if self._a == vandal.ui.KEY_CODEPOINT then
            return string.format("[INEV KB CODEPOINT %s]", self._b)
        else
            return string.format("[INEV KB %s %s]", vandal.ui.key_names[self._a] or "???", vandal.ui.mod_names[self._c] or "???")
        end
    elseif self._type == IET_RESIZE then
        return "[INEV RESIZE]"
    else
        error "TODO"
    end
end

return classes.create(cl)

