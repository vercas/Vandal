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

if not vandal then vandal = { } else error "wut?" end
local vandal = vandal

local ui, text_input, mode_line, commands  -- REQUIRED LATER
local inputdispatcher = require "vandal/input_dispatcher_class"
local inputmode = require "vandal/input_mode_class"
local vcall = require "vandal/utils/vcall"

vandal.indis = inputdispatcher()

vandal.inm_nrm = inputmode "normal"
vandal.inm_msg = inputmode "message"
vandal.inm_cmd = inputmode "command"

vandal.indis:add_mode(vandal.inm_nrm)
vandal.indis:add_mode(vandal.inm_msg)
vandal.indis:add_mode(vandal.inm_cmd)

function vandal.inm_nrm:on_event(ev)
    if ev.type == IET_KB then
        if ev.key == ui.KEY_ESC then
            vandal.stopping = true
        elseif ev.key == ui.KEY_CODEPOINT then
            if ev.char == "m" then
                vandal.indis:change_mode(vandal.inm_msg)
            elseif ev.char == ":" then
                vandal.indis:change_mode(vandal.inm_cmd)
            end
        end
    end
end

function vandal.inm_nrm:on_enter()
    ui.main_window:focus()
end

function vandal.inm_msg:on_event(ev)
    vandal.input_window:process_event(ev)
end

function vandal.inm_msg:on_enter()
    vandal.input_window:focus()

    if self.last_cont then
        vandal.input_window:set_contents(self.last_cont)
        self.last_cont = false
    else
        vandal.input_window:clear_contents()
    end
end

function vandal.inm_msg:on_leave()
    self.last_cont = vandal.input_window:get_contents(true)
end

function vandal.inm_cmd:on_event(ev)
    vandal.input_window:process_event(ev)
end

function vandal.inm_cmd:on_enter()
    vandal.input_window:focus()

    if self.last_cont then
        vandal.input_window:set_contents(self.last_cont)
        self.last_cont = false
    else
        vandal.input_window:clear_contents(":")
    end
end

function vandal.inm_cmd:on_leave()
    self.last_cont = vandal.input_window:get_contents(true)
end

function vandal.main()
    text_input = require "vandal/text_input_class"
    mode_line = require "vandal/mode_line_class"
    commands = require "vandal/commands"

    vandal.stopping = false

    vandal.input_window = text_input(ui.main_window, 0, ui.main_window.height - 1, ui.main_window.width, 1)
    vandal.mode_line = mode_line(ui.main_window, 0, ui.main_window.height - 2, ui.main_window.width, 1, vandal.indis)

    vandal.indis:change_mode(vandal.inm_nrm)

    function ui.main_window:on_geometry_change(x, y, w, h)
        local tih = math.clamp(1, #vandal.input_window.lines, math.ceil(h / 15))

        vandal.input_window:reposition(0, h - tih, w, tih)
        vandal.mode_line:reposition(0, h - tih - 1, w, 1)
    end

    function ui.main_window:on_draw(x, y, w, h)
        self:clear()
    end

    function vandal.input_window:on_unhandled_key(ev)
        if ev.key == ui.KEY_ESC then
            vandal.indis:change_mode(vandal.inm_nrm)

            return
        end
    end

    function vandal.input_window:on_newline(mod)
        ui.main_window:do_on_geometry_change(ui.main_window:get_geometry())
        ui.main_window:invalidate()
    end

    function vandal.input_window:on_contents_change()
        if #self.lines ~= self.height then
            ui.main_window:do_on_geometry_change(ui.main_window:get_geometry())
            ui.main_window:invalidate()
        end
    end

    repeat
        local ev = ui.poll(100)

        if ev then
            ERR("Event ", tostring(ev))

            if ev.type == IET_KB or ev.type == IET_MS then
                vandal.indis:handle_event(ev)
            end

            vandal.indis.mode:do_on_refresh()
        end
    until vandal.stopping
end

function vandal.run()
    --  TODO: Parse command-line args?
    vandal.ui_kit = "tickit"
    vandal.colorspace = "xterm"
    vandal.utf8 = true
    vandal.debug = true

    local res = vcall(require, "vandal/ui")

    if res.Error then
        io.stderr:write(res:Print())
        io.stderr:flush()

        return 1
    end

    ui = res.Return[1]

    res = vcall(ui.initialize)

    if not res.Error then
        res = vcall(vandal.main)
    end

    local res2 = vcall(ui.finalize)
    --  Called even if initialization failed.

    if res2.Error then
        if res.Error then
            io.stderr:write(res:Print())
            io.stderr:write("-------------------------------------------------------------------------------\n")
        end

        io.stderr:write(res2:Print())
        io.stderr:flush()

        return 2
    elseif res.Error then
        io.stderr:write(res:Print())
        io.stderr:flush()

        return 3
    end

    return 0
end

return vandal

