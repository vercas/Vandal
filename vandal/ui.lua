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

if vandal.ui then error "wut?" end
local ui = {}

local inev = require "vandal/input_event_class"
local types = require "vandal/utils/types"
local colors = require "vandal/utils/colors"
local ffi = require "ffi"
require "vandal/ffi/misc"

ui.initialized = false

function ui.initialize()
    colors.initialize(vandal.colorspace)

    return ui.kit.initialize(ui)
end

function ui.finalize()
    return ui.kit.finalize(ui)
end

function ui.poll(timeout)
    local ev = ui.kit.poll(ui, timeout)

    ui.last_event = ev

    return ev
end

ui.KEYS = [[
CODEPOINT NONE UNKNOWN
ESC/ESCAPE TAB ENTER BACKSPACE DEL/DELETE
HOME END PGUP/PAGEUP PGDN/PGDOWN/PAGEDOWN INS/INSERT PRTSC/PRINTSCREEN SCRLK/SCROLL_LOCK
UP DOWN LEFT RIGHT
NUM0 NUM1 NUM2 NUM3 NUM4 NUM5 NUM6 NUM7 NUM8 NUM9 NUM_ENTER NUM_PLUS NUM_MINUS NUM_MUL/NUM_MULT/NUM_MULTIPLY NUM_DIV/NUM_DIVIDE NUM_DOT/NUM_PERIOD NUM_COMMA NUM_EQU/NUM_EQUALS
]]

ui.MODS = [[NONE C/CTRL/CONTROL M/META/ALT S/SHIFT C_M/CTRL_META/CONTROL_ALT C_S/CTRL_SHIFT/CONTROL_SHIFT A_S/META_SHIFT/ALT_SHIFT C_M_S/CTRL_META_SHIFT/CONTROL_ALT_SHIFT]]

ui.key_names, ui.mod_names = { }, { }

local nextKeyVal = 0
for k in ui.KEYS:gmatch("%S+") do
    for l in k:gmatch("[^/]+") do
        ui["KEY_" .. l] = nextKeyVal
        ui.key_names[nextKeyVal] = l
    end

    nextKeyVal = nextKeyVal + 1
end

nextKeyVal = 0
for k in ui.MODS:gmatch("%S+") do
    for l in k:gmatch("[^/]+") do
        ui["MOD_" .. l] = nextKeyVal
        ui.mod_names[nextKeyVal] = l
    end

    nextKeyVal = nextKeyVal + 1
end

vandal.ui = setmetatable({ }, { __index = ui, __newindex = function() error "Vandal error: Cannot modify `vandal.ui` table." end })

if vandal.ui_kit == "curses" then
    ui.kit = require "vandal/curses/init"
elseif vandal.ui_kit == "tickit" then
    ui.kit = require "vandal/tickit/init"
else
    error("Vandal error: Unknown UI kit \"" .. tostring(vandal.ui_kit) .."\".")
end

ui.window = ui.kit.window

return vandal.ui

