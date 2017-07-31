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

local cl = {
    Name = "InputMode",

    name = { RETRIEVE = "_name", },
    active = { RETRIEVE = "_active", }
}

function cl.add_custom_event(evn)
    types.assert("string", evn, "event name")

    evn = "on_" .. evn

    if cl["do_" .. evn] then
        error("Vandal error: Input mode class already has a custom event named \"" .. evn .. "\".")
    end

    cl["do_" .. evn] = function(self, ...)
        if self[evn] then
            return self[evn](self, ...)
        end
    end
end

function cl:do_on_enter()
    if self.on_enter then
        return self:on_enter()
    end
end

function cl:do_on_leave()
    if self.on_leave then
        return self:on_leave()
    end
end

function cl:do_on_refresh()
    if self.on_refresh then
        return self:on_refresh()
    end
end

function cl:__init(name)
    self._name = name
    self._active = false
end

function cl:handle_event(ev)
    types.assert("InputEvent", ev, "event")
    assert(self._active, "This mode should be active!")

    if self.on_event then
        return self:on_event(ev)
    end
end

return classes.create(cl)

