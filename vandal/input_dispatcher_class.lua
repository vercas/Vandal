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
    Name = "InputDispatcher",

    mode = { RETRIEVE = "_mode", },
}

function cl:do_on_mode_change(new, old)
    local fnc = self.on_mode_change

    if fnc then
        return fnc(self, new, old)
    end
end

function cl:__init()
    self._modes = { }
end

function cl:change_mode(n)
    local nType, m = types.assert({ "number", "string", "InputMode", }, n, "mode or mode name/index")

    if nType == "InputMode" then
        for i = 1, #self._modes do
            if self._modes[i] == n then
                m = n
                break
            end
        end
    else
        m = self._modes[n]
    end

    if not m then
        error("Vandal error: Failed to change mode to \"" .. tostring(n) .. "\" in input dispatcher.")
    end

    local old = self._mode

    if old then
        old._active = false
        old:do_on_leave()
    end

    self._mode = m

    m._active = true
    m:do_on_enter()

    self:do_on_mode_change(m, old)

    return m
end

function cl:get_mode(n)
    types.assert({ "number", "string", }, n, "mode name/index")

    return self._modes[n]
end

function cl:add_mode(m)
    types.assert("InputMode", m, "input mode")

    if self._modes[m.name] then
        error "Vandal error: A mode with the given name already registered with this dispatcher."
    end

    table.insert(self._modes, m)
    self._modes[m.name] = m

    return m
end

function cl:remove_mode(n)
    local nType = types.assert({ "number", "string", }, n, "mode name/index")

    local m = self._modes[n]

    if not m then
        error("Vandal error: Attempted to remove unknown input mode from dispatcher by " .. (nType == "number" and "index: " or "name: ") .. n)
    elseif self._mode == m then
        error("Vandal error: Attempted to remove input mode from dispatcher which is presently active: " .. n)
    end

    if nType == "number" then
        table.remove(self._modes[n])
        self._modes[m.name] = nil

        return m
    else
        self._modes[n] = nil

        for i = 1, #self._modes do
            if self._modes[i] == m then
                table.remove(self._modes, i)

                return m
            end
        end

        error "Invalid state!"
    end
end

function cl:handle_event(ev)
    types.assert("InputEvent", ev, "event")

    if self._mode then
        return self._mode:handle_event(ev)
    else
        error("Vandal error: Failed to dispatch input event because there is no active input mode: " .. tostring(ev))
    end
end

return classes.create(cl)

