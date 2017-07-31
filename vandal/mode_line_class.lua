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
    Name = "ModeLine",
    ParentName = "Window",

    mode_separator = UNIC("", "|"),
}

function cl:__init(win, x, y, w, h, disp)
    types.assert("Window", win, "ModeLine parent window")

    if type(x) ~= "number" or not types.is_integer(x) then error "Vandal error: `ModeLine` constructor X position must be an integer." end
    if type(y) ~= "number" or not types.is_integer(y) then error "Vandal error: `ModeLine` constructor Y position must be an integer." end
    if type(w) ~= "number" or not types.is_integer(w) then error "Vandal error: `ModeLine` constructor width must be an integer." end
    if type(h) ~= "number" or not types.is_integer(h) then error "Vandal error: `ModeLine` constructor height must be an integer." end

    types.assert("InputDispatcher", disp, "input dispatcher for ModeLine")

    local han = win:_derive(x, y, w, h)

    if not han then
        error "Vandal error: Failed to derive window in order to construct a `ModeLine`."
    end

    __super(self, han, true, x, y, w, h)

    self.disp = disp

    function disp.on_mode_change(disp, new, old)
        self:invalidate()
    end
end

function cl:process_event(ev)
    if ev.type == IET_MS then
        --  TODO: Mouse support?
        return false
    else
        return false
    end
end

function cl:on_draw(x, y, w, h)
    self:_clear(x, y, w, h)

    local mname = self.disp.mode.name

    self:_print_xy(0, 0, mname)
    self:_print_xy(#mname, 0, self.mode_separator)
end

return classes.create(cl)

