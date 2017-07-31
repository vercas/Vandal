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

if vandal.tickit then error "wut?" end
local tickit = { }

local tk = require "vandal/ffi/tickit"
local window = require "vandal/tickit/window_class"
local inev = require "vandal/input_event_class"
local types = require "vandal/utils/types"
local ffi = require "ffi"
require "vandal/ffi/misc"
require "vandal/logging"
local c, C = tk.C, ffi.C

tickit.window = window

local registry, evq = { }, { }

function tickit.initialize(ui)
    if ui.initialized then
        error "Vandal error: tickit interface is already initialized."
    end

    ui.initialized = true

    C.setlocale(C.LC_CTYPE, "")
    ERR "Locale set."

    tickit.tt = c.tickit_term_open_stdio()
    ERR "Tickit stdio terminal opened."

    if tickit.tt == nil or tickit.tt == 0 then
        error("Vandal error: Failed to initialize tickit: " .. ffi.errno())
    end

    c.tickit_term_await_started_msec(tickit.tt, 100)
    ERR "Tickit terminal started."

    c.tickit_term_setctl_int(tickit.tt, c.TICKIT_TERMCTL_ALTSCREEN, 1)
    c.tickit_term_setctl_int(tickit.tt, c.TICKIT_TERMCTL_KEYPAD_APP, 1)

    c.tickit_term_clear(tickit.tt)
    ERR "Terminal cleared."

    tickit.win_callback = ffi.cast("TickitWindowEventFn*", tickit.on_event)
    tickit.term_callback = ffi.cast("TickitTermEventFn*", tickit.on_event)
    ERR "Events set up."

    tickit._ev = c.tickit_term_bind_event(tickit.tt, bit.bor(c.TICKIT_EV_RESIZE, c.TICKIT_EV_CHANGE, c.TICKIT_EV_KEY, c.TICKIT_EV_MOUSE), 0, tickit.term_callback, nil)

    ui.main_window = window(c.tickit_window_new_root(tickit.tt), false)
    ERR "Main window created."

    c.tickit_window_take_focus(ui.main_window._handle)
    ERR "Root window given focus."
end

function tickit.finalize(ui)
    if ui.main_window and ui.main_window.valid then
        ui.main_window:destroy()
    end

    if tickit.tt then
        c.tickit_term_unref(tickit.tt)
    end

    if tickit.win_callback then
        tickit.win_callback:free()
    end

    if tickit.term_callback then
        tickit.term_callback:free()
    end
end

function tickit.poll(ui, timeout)
    local tType = types.assert({ "nil", "number", "boolean" }, timeout, "timeout")

    if tType == "number" then
        if timeout < 0 then
            error "Vandal error: `timeout` value given to `poll` must be positive."
        end
    else
        timeout = (timeout ~= false) and -1 or 0
    end

    if #evq > 0 then
        --  There is an enqueued event? Then return it!

        local ev = evq[1]
        table.remove(evq, 1)
        return ev
    end

    c.tickit_window_flush(ui.main_window._handle)
    c.tickit_term_input_wait_msec(tickit.tt, timeout)

    if #evq > 0 then
        --  There is an enqueued event? Then return it!

        local ev = evq[1]
        table.remove(evq, 1)
        return ev
    else
        return false
    end
end

function tickit.on_event(han, ev, info, user)
    local win

    if ffi.istype("TickitWindow*", han) then
        win = registry[tonumber(ffi.cast("size_t", han))]

        if not win then
            error("Vandal/libtickit internal error: No window associated with handle (pointer): " .. tostring(han))
        end
    end

    ERR("ONEVENT ", tostring(han), " (", tostring(win), ");\t", tostring(ev), ";\t", tostring(info))

    if ev == c.TICKIT_EV_KEY then
        info = ffi.cast("TickitKeyEventInfo*", info)

        ERR(info.type == c.TICKIT_KEYEV_KEY and "KEY: " or "TEXT: ", info.mod, "; ", ffi.string(info.str))

        if info.type == c.TICKIT_KEYEV_TEXT then
            evq[#evq + 1] = inev(IET_KB, vandal.ui.KEY_CODEPOINT, ffi.string(info.str), vandal.ui.MOD_NONE)
        else
            evq[#evq + 1] = inev(IET_KB, tickit.key_translate[ffi.string(info.str)], nil, tickit.mod_translate[info.mod])
        end
    elseif ev == c.TICKIT_EV_RESIZE then
        info = ffi.cast("TickitResizeEventInfo*", info)
        evq[#evq + 1] = inev(IET_RESIZE, info.cols, info.lines)
    elseif ev == c.TICKIT_EV_GEOMCHANGE then
        info = ffi.cast("TickitGeomchangeEventInfo*", info)

        win:do_on_geometry_change(info.rect.left, info.rect.top, info.rect.cols, info.rect.lines)
    elseif ev == c.TICKIT_EV_EXPOSE then
        info = ffi.cast("TickitExposeEventInfo*", info)

        ERR("EXPOSE: ", info.rb, "; ", info.rect.left, ",", info.rect.top, ",", info.rect.cols, ",", info.rect.lines)

        win:do_on_draw(info.rect.left, info.rect.top, info.rect.cols, info.rect.lines, info.rb)
    end

    return 1
end

function tickit.register_window(win)
    local key = tonumber(ffi.cast("size_t", win._handle))
    registry[key] = win

    win._ev = c.tickit_window_bind_event(win._handle, bit.bor(c.TICKIT_EV_GEOMCHANGE, c.TICKIT_EV_CHANGE, c.TICKIT_EV_FOCUS, c.TICKIT_EV_EXPOSE, c.TICKIT_EV_KEY), 0, tickit.win_callback, nil)
end

function tickit.unregister_window(win)
    --
end

tickit.mod_translate = {
    vandal.ui.MOD_SHIFT,
    vandal.ui.MOD_ALT,
    vandal.ui.MOD_ALT_SHIFT,
    vandal.ui.MOD_CONTROL,
    vandal.ui.MOD_CONTROL_SHIFT,
    vandal.ui.MOD_CONTROL_ALT,
    vandal.ui.MOD_CONTROL_ALT_SHIFT,

    [0] = vandal.ui.MOD_NONE,
}

tickit.key_translate = { }

local keys = {
}

for _, key in ipairs { "Insert", "Delete", "Home", "End", "PageUp", "PageDown", "Enter", "Backspace", "Tab", "Escape", "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12", "Left", "Right", "Up", "Down" } do
    keys[key] = vandal.ui["KEY_" .. key:upper()]
end

for _, pref in ipairs { "", "M-", "C-", "S-", "M-C-", "M-S-", "C-S-", "M-C-S-" } do
    for k, v in pairs(keys) do
        tickit.key_translate[pref .. k] = v
    end
end

vandal.tickit = setmetatable({ }, { __index = tickit, __newindex = function() error "Vandal error: Cannot modify `vandal.tickit` table." end })

return vandal.tickit

