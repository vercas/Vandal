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

local types = require "vandal/utils/types"
local bit = require "bit"

if not vandal.utils.colors then vandal.utils.colors = { } end
local colors = vandal.utils.colors

local function HEX(str)
    return tonumber(str, 16)
end

local function RGB(r, g, b)
    return bit.bor(bit.lshift(r, 16), bit.lshift(g, 8), b)
end

--  --  --  --  --  --  --
--  XTerm Color Space   --
--  --  --  --  --  --  --

local xterm_colorspace = {
    [0] = HEX "000000",
    HEX "800000",
    HEX "008000",
    HEX "808000",
    HEX "000080",
    HEX "800080",
    HEX "008080",
    HEX "c0c0c0",

    --  Equivalent "bright" versions of original 8 colors.
    HEX "808080",
    HEX "ff0000",
    HEX "00ff00",
    HEX "ffff00",
    HEX "0000ff",
    HEX "ff00ff",
    HEX "00ffff",
    HEX "ffffff",

    --  Strictly ascending.
    HEX "000000",
    HEX "00005f",
    HEX "000087",
    HEX "0000af",
    HEX "0000d7",
    HEX "0000ff",
    HEX "005f00",
    HEX "005f5f",
    HEX "005f87",
    HEX "005faf",
    HEX "005fd7",
    HEX "005fff",
    HEX "008700",
    HEX "00875f",
    HEX "008787",
    HEX "0087af",
    HEX "0087d7",
    HEX "0087ff",
    HEX "00af00",
    HEX "00af5f",
    HEX "00af87",
    HEX "00afaf",
    HEX "00afd7",
    HEX "00afff",
    HEX "00d700",
    HEX "00d75f",
    HEX "00d787",
    HEX "00d7af",
    HEX "00d7d7",
    HEX "00d7ff",
    HEX "00ff00",
    HEX "00ff5f",
    HEX "00ff87",
    HEX "00ffaf",
    HEX "00ffd7",
    HEX "00ffff",
    HEX "5f0000",
    HEX "5f005f",
    HEX "5f0087",
    HEX "5f00af",
    HEX "5f00d7",
    HEX "5f00ff",
    HEX "5f5f00",
    HEX "5f5f5f",
    HEX "5f5f87",
    HEX "5f5faf",
    HEX "5f5fd7",
    HEX "5f5fff",
    HEX "5f8700",
    HEX "5f875f",
    HEX "5f8787",
    HEX "5f87af",
    HEX "5f87d7",
    HEX "5f87ff",
    HEX "5faf00",
    HEX "5faf5f",
    HEX "5faf87",
    HEX "5fafaf",
    HEX "5fafd7",
    HEX "5fafff",
    HEX "5fd700",
    HEX "5fd75f",
    HEX "5fd787",
    HEX "5fd7af",
    HEX "5fd7d7",
    HEX "5fd7ff",
    HEX "5fff00",
    HEX "5fff5f",
    HEX "5fff87",
    HEX "5fffaf",
    HEX "5fffd7",
    HEX "5fffff",
    HEX "870000",
    HEX "87005f",
    HEX "870087",
    HEX "8700af",
    HEX "8700d7",
    HEX "8700ff",
    HEX "875f00",
    HEX "875f5f",
    HEX "875f87",
    HEX "875faf",
    HEX "875fd7",
    HEX "875fff",
    HEX "878700",
    HEX "87875f",
    HEX "878787",
    HEX "8787af",
    HEX "8787d7",
    HEX "8787ff",
    HEX "87af00",
    HEX "87af5f",
    HEX "87af87",
    HEX "87afaf",
    HEX "87afd7",
    HEX "87afff",
    HEX "87d700",
    HEX "87d75f",
    HEX "87d787",
    HEX "87d7af",
    HEX "87d7d7",
    HEX "87d7ff",
    HEX "87ff00",
    HEX "87ff5f",
    HEX "87ff87",
    HEX "87ffaf",
    HEX "87ffd7",
    HEX "87ffff",
    HEX "af0000",
    HEX "af005f",
    HEX "af0087",
    HEX "af00af",
    HEX "af00d7",
    HEX "af00ff",
    HEX "af5f00",
    HEX "af5f5f",
    HEX "af5f87",
    HEX "af5faf",
    HEX "af5fd7",
    HEX "af5fff",
    HEX "af8700",
    HEX "af875f",
    HEX "af8787",
    HEX "af87af",
    HEX "af87d7",
    HEX "af87ff",
    HEX "afaf00",
    HEX "afaf5f",
    HEX "afaf87",
    HEX "afafaf",
    HEX "afafd7",
    HEX "afafff",
    HEX "afd700",
    HEX "afd75f",
    HEX "afd787",
    HEX "afd7af",
    HEX "afd7d7",
    HEX "afd7ff",
    HEX "afff00",
    HEX "afff5f",
    HEX "afff87",
    HEX "afffaf",
    HEX "afffd7",
    HEX "afffff",
    HEX "d70000",
    HEX "d7005f",
    HEX "d70087",
    HEX "d700af",
    HEX "d700d7",
    HEX "d700ff",
    HEX "d75f00",
    HEX "d75f5f",
    HEX "d75f87",
    HEX "d75faf",
    HEX "d75fd7",
    HEX "d75fff",
    HEX "d78700",
    HEX "d7875f",
    HEX "d78787",
    HEX "d787af",
    HEX "d787d7",
    HEX "d787ff",
    HEX "d7af00",
    HEX "d7af5f",
    HEX "d7af87",
    HEX "d7afaf",
    HEX "d7afd7",
    HEX "d7afff",
    HEX "d7d700",
    HEX "d7d75f",
    HEX "d7d787",
    HEX "d7d7af",
    HEX "d7d7d7",
    HEX "d7d7ff",
    HEX "d7ff00",
    HEX "d7ff5f",
    HEX "d7ff87",
    HEX "d7ffaf",
    HEX "d7ffd7",
    HEX "d7ffff",
    HEX "ff0000",
    HEX "ff005f",
    HEX "ff0087",
    HEX "ff00af",
    HEX "ff00d7",
    HEX "ff00ff",
    HEX "ff5f00",
    HEX "ff5f5f",
    HEX "ff5f87",
    HEX "ff5faf",
    HEX "ff5fd7",
    HEX "ff5fff",
    HEX "ff8700",
    HEX "ff875f",
    HEX "ff8787",
    HEX "ff87af",
    HEX "ff87d7",
    HEX "ff87ff",
    HEX "ffaf00",
    HEX "ffaf5f",
    HEX "ffaf87",
    HEX "ffafaf",
    HEX "ffafd7",
    HEX "ffafff",
    HEX "ffd700",
    HEX "ffd75f",
    HEX "ffd787",
    HEX "ffd7af",
    HEX "ffd7d7",
    HEX "ffd7ff",
    HEX "ffff00",
    HEX "ffff5f",
    HEX "ffff87",
    HEX "ffffaf",
    HEX "ffffd7",
    HEX "ffffff",

    --  Gray-scale range.
    HEX "080808",
    HEX "121212",
    HEX "1c1c1c",
    HEX "262626",
    HEX "303030",
    HEX "3a3a3a",
    HEX "444444",
    HEX "4e4e4e",
    HEX "585858",
    HEX "626262",
    HEX "6c6c6c",
    HEX "767676",
    HEX "808080",
    HEX "8a8a8a",
    HEX "949494",
    HEX "9e9e9e",
    HEX "a8a8a8",
    HEX "b2b2b2",
    HEX "bcbcbc",
    HEX "c6c6c6",
    HEX "d0d0d0",
    HEX "dadada",
    HEX "e4e4e4",
    HEX "eeeeee",

    Start = 16,
    End = 255,
}

--  --  --  --  --
--  X11 Colors  --
--  --  --  --  --

local rgbDotTxt = [[255 250 250		snow
248 248 255		ghost white
248 248 255		GhostWhite
245 245 245		white smoke
245 245 245		WhiteSmoke
220 220 220		gainsboro
255 250 240		floral white
255 250 240		FloralWhite
253 245 230		old lace
253 245 230		OldLace
250 240 230		linen
250 235 215		antique white
250 235 215		AntiqueWhite
255 239 213		papaya whip
255 239 213		PapayaWhip
255 235 205		blanched almond
255 235 205		BlanchedAlmond
255 228 196		bisque
255 218 185		peach puff
255 218 185		PeachPuff
255 222 173		navajo white
255 222 173		NavajoWhite
255 228 181		moccasin
255 248 220		cornsilk
255 255 240		ivory
255 250 205		lemon chiffon
255 250 205		LemonChiffon
255 245 238		seashell
240 255 240		honeydew
245 255 250		mint cream
245 255 250		MintCream
240 255 255		azure
240 248 255		alice blue
240 248 255		AliceBlue
230 230 250		lavender
255 240 245		lavender blush
255 240 245		LavenderBlush
255 228 225		misty rose
255 228 225		MistyRose
255 255 255		white
  0   0   0		black
 47  79  79		dark slate gray
 47  79  79		DarkSlateGray
 47  79  79		dark slate grey
 47  79  79		DarkSlateGrey
105 105 105		dim gray
105 105 105		DimGray
105 105 105		dim grey
105 105 105		DimGrey
112 128 144		slate gray
112 128 144		SlateGray
112 128 144		slate grey
112 128 144		SlateGrey
119 136 153		light slate gray
119 136 153		LightSlateGray
119 136 153		light slate grey
119 136 153		LightSlateGrey
190 190 190		gray
190 190 190		grey
190 190 190		x11 gray
190 190 190		X11Gray
190 190 190		x11 grey
190 190 190		X11Grey
128 128 128		web gray
128 128 128		WebGray
128 128 128		web grey
128 128 128		WebGrey
211 211 211		light grey
211 211 211		LightGrey
211 211 211		light gray
211 211 211		LightGray
 25  25 112		midnight blue
 25  25 112		MidnightBlue
  0   0 128		navy
  0   0 128		navy blue
  0   0 128		NavyBlue
100 149 237		cornflower blue
100 149 237		CornflowerBlue
 72  61 139		dark slate blue
 72  61 139		DarkSlateBlue
106  90 205		slate blue
106  90 205		SlateBlue
123 104 238		medium slate blue
123 104 238		MediumSlateBlue
132 112 255		light slate blue
132 112 255		LightSlateBlue
  0   0 205		medium blue
  0   0 205		MediumBlue
 65 105 225		royal blue
 65 105 225		RoyalBlue
  0   0 255		blue
 30 144 255		dodger blue
 30 144 255		DodgerBlue
  0 191 255		deep sky blue
  0 191 255		DeepSkyBlue
135 206 235		sky blue
135 206 235		SkyBlue
135 206 250		light sky blue
135 206 250		LightSkyBlue
 70 130 180		steel blue
 70 130 180		SteelBlue
176 196 222		light steel blue
176 196 222		LightSteelBlue
173 216 230		light blue
173 216 230		LightBlue
176 224 230		powder blue
176 224 230		PowderBlue
175 238 238		pale turquoise
175 238 238		PaleTurquoise
  0 206 209		dark turquoise
  0 206 209		DarkTurquoise
 72 209 204		medium turquoise
 72 209 204		MediumTurquoise
 64 224 208		turquoise
  0 255 255		cyan
  0 255 255		aqua
224 255 255		light cyan
224 255 255		LightCyan
 95 158 160		cadet blue
 95 158 160		CadetBlue
102 205 170		medium aquamarine
102 205 170		MediumAquamarine
127 255 212		aquamarine
  0 100   0		dark green
  0 100   0		DarkGreen
 85 107  47		dark olive green
 85 107  47		DarkOliveGreen
143 188 143		dark sea green
143 188 143		DarkSeaGreen
 46 139  87		sea green
 46 139  87		SeaGreen
 60 179 113		medium sea green
 60 179 113		MediumSeaGreen
 32 178 170		light sea green
 32 178 170		LightSeaGreen
152 251 152		pale green
152 251 152		PaleGreen
  0 255 127		spring green
  0 255 127		SpringGreen
124 252   0		lawn green
124 252   0		LawnGreen
  0 255   0		green
  0 255   0		lime
  0 255   0		x11 green
  0 255   0		X11Green
  0 128   0		web green
  0 128   0		WebGreen
127 255   0		chartreuse
  0 250 154		medium spring green
  0 250 154		MediumSpringGreen
173 255  47		green yellow
173 255  47		GreenYellow
 50 205  50		lime green
 50 205  50		LimeGreen
154 205  50		yellow green
154 205  50		YellowGreen
 34 139  34		forest green
 34 139  34		ForestGreen
107 142  35		olive drab
107 142  35		OliveDrab
189 183 107		dark khaki
189 183 107		DarkKhaki
240 230 140		khaki
238 232 170		pale goldenrod
238 232 170		PaleGoldenrod
250 250 210		light goldenrod yellow
250 250 210		LightGoldenrodYellow
255 255 224		light yellow
255 255 224		LightYellow
255 255   0		yellow
255 215   0 		gold
238 221 130		light goldenrod
238 221 130		LightGoldenrod
218 165  32		goldenrod
184 134  11		dark goldenrod
184 134  11		DarkGoldenrod
188 143 143		rosy brown
188 143 143		RosyBrown
205  92  92		indian red
205  92  92		IndianRed
139  69  19		saddle brown
139  69  19		SaddleBrown
160  82  45		sienna
205 133  63		peru
222 184 135		burlywood
245 245 220		beige
245 222 179		wheat
244 164  96		sandy brown
244 164  96		SandyBrown
210 180 140		tan
210 105  30		chocolate
178  34  34		firebrick
165  42  42		brown
233 150 122		dark salmon
233 150 122		DarkSalmon
250 128 114		salmon
255 160 122		light salmon
255 160 122		LightSalmon
255 165   0		orange
255 140   0		dark orange
255 140   0		DarkOrange
255 127  80		coral
240 128 128		light coral
240 128 128		LightCoral
255  99  71		tomato
255  69   0		orange red
255  69   0		OrangeRed
255   0   0		red
255 105 180		hot pink
255 105 180		HotPink
255  20 147		deep pink
255  20 147		DeepPink
255 192 203		pink
255 182 193		light pink
255 182 193		LightPink
219 112 147		pale violet red
219 112 147		PaleVioletRed
176  48  96		maroon
176  48  96		x11 maroon
176  48  96		X11Maroon
128   0   0		web maroon
128   0   0		WebMaroon
199  21 133		medium violet red
199  21 133		MediumVioletRed
208  32 144		violet red
208  32 144		VioletRed
255   0 255		magenta
255   0 255		fuchsia
238 130 238		violet
221 160 221		plum
218 112 214		orchid
186  85 211		medium orchid
186  85 211		MediumOrchid
153  50 204		dark orchid
153  50 204		DarkOrchid
148   0 211		dark violet
148   0 211		DarkViolet
138  43 226		blue violet
138  43 226		BlueViolet
160  32 240		purple
160  32 240		x11 purple
160  32 240		X11Purple
128   0 128		web purple
128   0 128		WebPurple
147 112 219		medium purple
147 112 219		MediumPurple
216 191 216		thistle
255 250 250		snow1
238 233 233		snow2
205 201 201		snow3
139 137 137		snow4
255 245 238		seashell1
238 229 222		seashell2
205 197 191		seashell3
139 134 130		seashell4
255 239 219		AntiqueWhite1
238 223 204		AntiqueWhite2
205 192 176		AntiqueWhite3
139 131 120		AntiqueWhite4
255 228 196		bisque1
238 213 183		bisque2
205 183 158		bisque3
139 125 107		bisque4
255 218 185		PeachPuff1
238 203 173		PeachPuff2
205 175 149		PeachPuff3
139 119 101		PeachPuff4
255 222 173		NavajoWhite1
238 207 161		NavajoWhite2
205 179 139		NavajoWhite3
139 121	 94		NavajoWhite4
255 250 205		LemonChiffon1
238 233 191		LemonChiffon2
205 201 165		LemonChiffon3
139 137 112		LemonChiffon4
255 248 220		cornsilk1
238 232 205		cornsilk2
205 200 177		cornsilk3
139 136 120		cornsilk4
255 255 240		ivory1
238 238 224		ivory2
205 205 193		ivory3
139 139 131		ivory4
240 255 240		honeydew1
224 238 224		honeydew2
193 205 193		honeydew3
131 139 131		honeydew4
255 240 245		LavenderBlush1
238 224 229		LavenderBlush2
205 193 197		LavenderBlush3
139 131 134		LavenderBlush4
255 228 225		MistyRose1
238 213 210		MistyRose2
205 183 181		MistyRose3
139 125 123		MistyRose4
240 255 255		azure1
224 238 238		azure2
193 205 205		azure3
131 139 139		azure4
131 111 255		SlateBlue1
122 103 238		SlateBlue2
105  89 205		SlateBlue3
 71  60 139		SlateBlue4
 72 118 255		RoyalBlue1
 67 110 238		RoyalBlue2
 58  95 205		RoyalBlue3
 39  64 139		RoyalBlue4
  0   0 255		blue1
  0   0 238		blue2
  0   0 205		blue3
  0   0 139		blue4
 30 144 255		DodgerBlue1
 28 134 238		DodgerBlue2
 24 116 205		DodgerBlue3
 16  78 139		DodgerBlue4
 99 184 255		SteelBlue1
 92 172 238		SteelBlue2
 79 148 205		SteelBlue3
 54 100 139		SteelBlue4
  0 191 255		DeepSkyBlue1
  0 178 238		DeepSkyBlue2
  0 154 205		DeepSkyBlue3
  0 104 139		DeepSkyBlue4
135 206 255		SkyBlue1
126 192 238		SkyBlue2
108 166 205		SkyBlue3
 74 112 139		SkyBlue4
176 226 255		LightSkyBlue1
164 211 238		LightSkyBlue2
141 182 205		LightSkyBlue3
 96 123 139		LightSkyBlue4
198 226 255		SlateGray1
185 211 238		SlateGray2
159 182 205		SlateGray3
108 123 139		SlateGray4
202 225 255		LightSteelBlue1
188 210 238		LightSteelBlue2
162 181 205		LightSteelBlue3
110 123 139		LightSteelBlue4
191 239 255		LightBlue1
178 223 238		LightBlue2
154 192 205		LightBlue3
104 131 139		LightBlue4
224 255 255		LightCyan1
209 238 238		LightCyan2
180 205 205		LightCyan3
122 139 139		LightCyan4
187 255 255		PaleTurquoise1
174 238 238		PaleTurquoise2
150 205 205		PaleTurquoise3
102 139 139		PaleTurquoise4
152 245 255		CadetBlue1
142 229 238		CadetBlue2
122 197 205		CadetBlue3
 83 134 139		CadetBlue4
  0 245 255		turquoise1
  0 229 238		turquoise2
  0 197 205		turquoise3
  0 134 139		turquoise4
  0 255 255		cyan1
  0 238 238		cyan2
  0 205 205		cyan3
  0 139 139		cyan4
151 255 255		DarkSlateGray1
141 238 238		DarkSlateGray2
121 205 205		DarkSlateGray3
 82 139 139		DarkSlateGray4
127 255 212		aquamarine1
118 238 198		aquamarine2
102 205 170		aquamarine3
 69 139 116		aquamarine4
193 255 193		DarkSeaGreen1
180 238 180		DarkSeaGreen2
155 205 155		DarkSeaGreen3
105 139 105		DarkSeaGreen4
 84 255 159		SeaGreen1
 78 238 148		SeaGreen2
 67 205 128		SeaGreen3
 46 139	 87		SeaGreen4
154 255 154		PaleGreen1
144 238 144		PaleGreen2
124 205 124		PaleGreen3
 84 139	 84		PaleGreen4
  0 255 127		SpringGreen1
  0 238 118		SpringGreen2
  0 205 102		SpringGreen3
  0 139	 69		SpringGreen4
  0 255	  0		green1
  0 238	  0		green2
  0 205	  0		green3
  0 139	  0		green4
127 255	  0		chartreuse1
118 238	  0		chartreuse2
102 205	  0		chartreuse3
 69 139	  0		chartreuse4
192 255	 62		OliveDrab1
179 238	 58		OliveDrab2
154 205	 50		OliveDrab3
105 139	 34		OliveDrab4
202 255 112		DarkOliveGreen1
188 238 104		DarkOliveGreen2
162 205	 90		DarkOliveGreen3
110 139	 61		DarkOliveGreen4
255 246 143		khaki1
238 230 133		khaki2
205 198 115		khaki3
139 134	 78		khaki4
255 236 139		LightGoldenrod1
238 220 130		LightGoldenrod2
205 190 112		LightGoldenrod3
139 129	 76		LightGoldenrod4
255 255 224		LightYellow1
238 238 209		LightYellow2
205 205 180		LightYellow3
139 139 122		LightYellow4
255 255	  0		yellow1
238 238	  0		yellow2
205 205	  0		yellow3
139 139	  0		yellow4
255 215	  0		gold1
238 201	  0		gold2
205 173	  0		gold3
139 117	  0		gold4
255 193	 37		goldenrod1
238 180	 34		goldenrod2
205 155	 29		goldenrod3
139 105	 20		goldenrod4
255 185	 15		DarkGoldenrod1
238 173	 14		DarkGoldenrod2
205 149	 12		DarkGoldenrod3
139 101	  8		DarkGoldenrod4
255 193 193		RosyBrown1
238 180 180		RosyBrown2
205 155 155		RosyBrown3
139 105 105		RosyBrown4
255 106 106		IndianRed1
238  99	 99		IndianRed2
205  85	 85		IndianRed3
139  58	 58		IndianRed4
255 130	 71		sienna1
238 121	 66		sienna2
205 104	 57		sienna3
139  71	 38		sienna4
255 211 155		burlywood1
238 197 145		burlywood2
205 170 125		burlywood3
139 115	 85		burlywood4
255 231 186		wheat1
238 216 174		wheat2
205 186 150		wheat3
139 126 102		wheat4
255 165	 79		tan1
238 154	 73		tan2
205 133	 63		tan3
139  90	 43		tan4
255 127	 36		chocolate1
238 118	 33		chocolate2
205 102	 29		chocolate3
139  69	 19		chocolate4
255  48	 48		firebrick1
238  44	 44		firebrick2
205  38	 38		firebrick3
139  26	 26		firebrick4
255  64	 64		brown1
238  59	 59		brown2
205  51	 51		brown3
139  35	 35		brown4
255 140 105		salmon1
238 130	 98		salmon2
205 112	 84		salmon3
139  76	 57		salmon4
255 160 122		LightSalmon1
238 149 114		LightSalmon2
205 129	 98		LightSalmon3
139  87	 66		LightSalmon4
255 165	  0		orange1
238 154	  0		orange2
205 133	  0		orange3
139  90	  0		orange4
255 127	  0		DarkOrange1
238 118	  0		DarkOrange2
205 102	  0		DarkOrange3
139  69	  0		DarkOrange4
255 114	 86		coral1
238 106	 80		coral2
205  91	 69		coral3
139  62	 47		coral4
255  99	 71		tomato1
238  92	 66		tomato2
205  79	 57		tomato3
139  54	 38		tomato4
255  69	  0		OrangeRed1
238  64	  0		OrangeRed2
205  55	  0		OrangeRed3
139  37	  0		OrangeRed4
255   0	  0		red1
238   0	  0		red2
205   0	  0		red3
139   0	  0		red4
255  20 147		DeepPink1
238  18 137		DeepPink2
205  16 118		DeepPink3
139  10	 80		DeepPink4
255 110 180		HotPink1
238 106 167		HotPink2
205  96 144		HotPink3
139  58  98		HotPink4
255 181 197		pink1
238 169 184		pink2
205 145 158		pink3
139  99 108		pink4
255 174 185		LightPink1
238 162 173		LightPink2
205 140 149		LightPink3
139  95 101		LightPink4
255 130 171		PaleVioletRed1
238 121 159		PaleVioletRed2
205 104 137		PaleVioletRed3
139  71	 93		PaleVioletRed4
255  52 179		maroon1
238  48 167		maroon2
205  41 144		maroon3
139  28	 98		maroon4
255  62 150		VioletRed1
238  58 140		VioletRed2
205  50 120		VioletRed3
139  34	 82		VioletRed4
255   0 255		magenta1
238   0 238		magenta2
205   0 205		magenta3
139   0 139		magenta4
255 131 250		orchid1
238 122 233		orchid2
205 105 201		orchid3
139  71 137		orchid4
255 187 255		plum1
238 174 238		plum2
205 150 205		plum3
139 102 139		plum4
224 102 255		MediumOrchid1
209  95 238		MediumOrchid2
180  82 205		MediumOrchid3
122  55 139		MediumOrchid4
191  62 255		DarkOrchid1
178  58 238		DarkOrchid2
154  50 205		DarkOrchid3
104  34 139		DarkOrchid4
155  48 255		purple1
145  44 238		purple2
125  38 205		purple3
 85  26 139		purple4
171 130 255		MediumPurple1
159 121 238		MediumPurple2
137 104 205		MediumPurple3
 93  71 139		MediumPurple4
255 225 255		thistle1
238 210 238		thistle2
205 181 205		thistle3
139 123 139		thistle4
  0   0   0		gray0
  0   0   0		grey0
  3   3   3		gray1
  3   3   3		grey1
  5   5   5		gray2
  5   5   5		grey2
  8   8   8		gray3
  8   8   8		grey3
 10  10  10 		gray4
 10  10  10 		grey4
 13  13  13 		gray5
 13  13  13 		grey5
 15  15  15 		gray6
 15  15  15 		grey6
 18  18  18 		gray7
 18  18  18 		grey7
 20  20  20 		gray8
 20  20  20 		grey8
 23  23  23 		gray9
 23  23  23 		grey9
 26  26  26 		gray10
 26  26  26 		grey10
 28  28  28 		gray11
 28  28  28 		grey11
 31  31  31 		gray12
 31  31  31 		grey12
 33  33  33 		gray13
 33  33  33 		grey13
 36  36  36 		gray14
 36  36  36 		grey14
 38  38  38 		gray15
 38  38  38 		grey15
 41  41  41 		gray16
 41  41  41 		grey16
 43  43  43 		gray17
 43  43  43 		grey17
 46  46  46 		gray18
 46  46  46 		grey18
 48  48  48 		gray19
 48  48  48 		grey19
 51  51  51 		gray20
 51  51  51 		grey20
 54  54  54 		gray21
 54  54  54 		grey21
 56  56  56 		gray22
 56  56  56 		grey22
 59  59  59 		gray23
 59  59  59 		grey23
 61  61  61 		gray24
 61  61  61 		grey24
 64  64  64 		gray25
 64  64  64 		grey25
 66  66  66 		gray26
 66  66  66 		grey26
 69  69  69 		gray27
 69  69  69 		grey27
 71  71  71 		gray28
 71  71  71 		grey28
 74  74  74 		gray29
 74  74  74 		grey29
 77  77  77 		gray30
 77  77  77 		grey30
 79  79  79 		gray31
 79  79  79 		grey31
 82  82  82 		gray32
 82  82  82 		grey32
 84  84  84 		gray33
 84  84  84 		grey33
 87  87  87 		gray34
 87  87  87 		grey34
 89  89  89 		gray35
 89  89  89 		grey35
 92  92  92 		gray36
 92  92  92 		grey36
 94  94  94 		gray37
 94  94  94 		grey37
 97  97  97 		gray38
 97  97  97 		grey38
 99  99  99 		gray39
 99  99  99 		grey39
102 102 102 		gray40
102 102 102 		grey40
105 105 105 		gray41
105 105 105 		grey41
107 107 107 		gray42
107 107 107 		grey42
110 110 110 		gray43
110 110 110 		grey43
112 112 112 		gray44
112 112 112 		grey44
115 115 115 		gray45
115 115 115 		grey45
117 117 117 		gray46
117 117 117 		grey46
120 120 120 		gray47
120 120 120 		grey47
122 122 122 		gray48
122 122 122 		grey48
125 125 125 		gray49
125 125 125 		grey49
127 127 127 		gray50
127 127 127 		grey50
130 130 130 		gray51
130 130 130 		grey51
133 133 133 		gray52
133 133 133 		grey52
135 135 135 		gray53
135 135 135 		grey53
138 138 138 		gray54
138 138 138 		grey54
140 140 140 		gray55
140 140 140 		grey55
143 143 143 		gray56
143 143 143 		grey56
145 145 145 		gray57
145 145 145 		grey57
148 148 148 		gray58
148 148 148 		grey58
150 150 150 		gray59
150 150 150 		grey59
153 153 153 		gray60
153 153 153 		grey60
156 156 156 		gray61
156 156 156 		grey61
158 158 158 		gray62
158 158 158 		grey62
161 161 161 		gray63
161 161 161 		grey63
163 163 163 		gray64
163 163 163 		grey64
166 166 166 		gray65
166 166 166 		grey65
168 168 168 		gray66
168 168 168 		grey66
171 171 171 		gray67
171 171 171 		grey67
173 173 173 		gray68
173 173 173 		grey68
176 176 176 		gray69
176 176 176 		grey69
179 179 179 		gray70
179 179 179 		grey70
181 181 181 		gray71
181 181 181 		grey71
184 184 184 		gray72
184 184 184 		grey72
186 186 186 		gray73
186 186 186 		grey73
189 189 189 		gray74
189 189 189 		grey74
191 191 191 		gray75
191 191 191 		grey75
194 194 194 		gray76
194 194 194 		grey76
196 196 196 		gray77
196 196 196 		grey77
199 199 199 		gray78
199 199 199 		grey78
201 201 201 		gray79
201 201 201 		grey79
204 204 204 		gray80
204 204 204 		grey80
207 207 207 		gray81
207 207 207 		grey81
209 209 209 		gray82
209 209 209 		grey82
212 212 212 		gray83
212 212 212 		grey83
214 214 214 		gray84
214 214 214 		grey84
217 217 217 		gray85
217 217 217 		grey85
219 219 219 		gray86
219 219 219 		grey86
222 222 222 		gray87
222 222 222 		grey87
224 224 224 		gray88
224 224 224 		grey88
227 227 227 		gray89
227 227 227 		grey89
229 229 229 		gray90
229 229 229 		grey90
232 232 232 		gray91
232 232 232 		grey91
235 235 235 		gray92
235 235 235 		grey92
237 237 237 		gray93
237 237 237 		grey93
240 240 240 		gray94
240 240 240 		grey94
242 242 242 		gray95
242 242 242 		grey95
245 245 245 		gray96
245 245 245 		grey96
247 247 247 		gray97
247 247 247 		grey97
250 250 250 		gray98
250 250 250 		grey98
252 252 252 		gray99
252 252 252 		grey99
255 255 255 		gray100
255 255 255 		grey100
169 169 169		dark grey
169 169 169		DarkGrey
169 169 169		dark gray
169 169 169		DarkGray
0     0 139		dark blue
0     0 139		DarkBlue
0   139 139		dark cyan
0   139 139		DarkCyan
139   0 139		dark magenta
139   0 139		DarkMagenta
139   0   0		dark red
139   0   0		DarkRed
144 238 144		light green
144 238 144		LightGreen
220  20  60		crimson
 75   0 130		indigo
128 128   0		olive
102  51 153		rebecca purple
102  51 153		RebeccaPurple
192 192 192		silver
  0 128 128		teal
]]

local x11cols = { }

for r, g, b, name in rgbDotTxt:gmatch("%s*(%d+)%s+(%d+)%s+(%d+)%s+([^\n]+)") do
    x11cols[name] = RGB(tonumber(r), tonumber(g), tonumber(b))
end

do
    local tmp = { }

    for k, v in pairs(x11cols) do
        if k:find "%s" then
            tmp[k:gsub("%s+", "")] = v
        end
    end

    for k, v in pairs(tmp) do
        if x11cols[k] and x11cols[k] ~= v then
            error("Vandal error: Identically-named colors in X11's rgb.txt have different values: \"" .. k .. "\"")
        else
            x11cols[k] = v
        end
    end

    tmp = { }

    for k, v in pairs(x11cols) do
        local l, u = k:lower(), k:upper()

        if k ~= l then tmp[l] = v end
        if k ~= u then tmp[u] = v end
    end

    for k, v in pairs(tmp) do
        if x11cols[k] and x11cols[k] ~= v then
            error("Vandal error: Identically-named colors in X11's rgb.txt have different values: \"" .. k .. "\"")
        else
            x11cols[k] = v
        end
    end

    tmp = nil   --  Cleanup.
end

--  --  --  --  --
--  Wrap up...  --
--  --  --  --  --

local colorspaces = {
    xterm = xterm_colorspace,
}

local cache = { }

function colors.initialize(csn)
    if not csn then csn = "xterm" end

    local cs = colorspaces[csn]

    if not cs then
        local csns = { }

        for k, v in pairs(colorspaces) do
            csns[#csns + 1] = "\n\t"
            csns[#csns + 1] = k
        end

        error("Vandal error: Colorspace \"" .. csn .. "\" is unknown. Known values are:" .. table.concat(csns))
    end

    function get_nearest_color(num)
        local mR, mG, mB = bit.rshift(num, 16), bit.band(0xFF, bit.rshift(num, 8)), bit.band(0xFF, num)

        local res, minDistSq
        --  Minimum distance, squared.

        for i = cs.Start, cs.End do
            local col = cs[i]
            local dR = bit.rshift(col, 16) - mR
            local dG = bit.band(0xFF, bit.rshift(col, 8)) - mG
            local dB = bit.band(0xFF, col) - mB
            local dstSq = dR * dR + dG * dG + dB * dB
            --  Distance, squared.

            if dstSq == 0 then
                res = i
                break
            end

            if not minDistSq or dstSq < minDistSq then
                res, minDistSq = i, dstSq
            end
        end
    end

    function colors.rgb2ind(num)
        if type(num) ~= "number" or not types.is_integer(num) or num < 0 or num > 0xFFFFFF then
            error "Vandal error: First argument to `vandal.utils.colors.rgb2ind` must be a 24-bit (positive) integer."
        end

        local res = cache[num]

        if res then
            return res
        else
            res = get_nearest_color(num)
        end

        cache[num] = res
        return res
    end

    function colors.ind2rgb(ind)
        if type(ind) ~= "number" or not types.is_integer(ind) then
            error "Vandal error: First argument to `vandal.utils.colors.ind2rgb` must be an integer."
        end

        if ind < cs.Start or ind > cs.End then
            error("Vandal error: First argument to `vandal.utils.colors.ind2rgb` is out of range (" .. cs.Start .. " to " .. cs.End .. "): " .. ind)
        end

        return cs[ind]
    end

    function colors.get(val)
        local valType = types.assert({ "number", "string" }, val, "color value")

        local res = cache[val]

        if res then
            return res
        elseif valType == "number" then
            if num < 0 or num > 0xFFFFFF then
                error "Vandal error: First argument to `vandal.utils.colors.get` must be a 24-bit (positive) integer, or a string."
            end

            res = get_nearest_color(val)
        else
            if #val == 0 then
                error "Vandal error: An empty string does not name a color."
            end

            if val:sub(1, 1) == "#" then
                --  Oooh, numba.

                if #val == 7 then
                    --  Fully-specified.

                    local num = HEX(val:sub(2))

                    if not num then
                        error("Vandal error: Invalid color value: \"" .. val .. "\".")
                    end

                    res = get_nearest_color(num)
                elseif #val == 4 then
                    --  Short form. Every nibble is duplicated.

                    local r, g, b = val:sub(2, 2), val:sub(3, 3), val:sub(4, 4)
                    local num = HEX(r .. r .. g .. g .. b .. b)

                    if not num then
                        error("Vandal error: Invalid color value: \"" .. val .. "\".")
                    end

                    res = get_nearest_color(num)
                else
                    error "Vandal error: Color value (string starting with #) must be either 7 or 4 characters long."
                end
            elseif string.find(val, ":", 1, true) then
                for spec in val:gmatch "[^;]+" do
                    local n, v = spec:match "^%s*([^:%s]+)%s*:%s*(%d+)%s*$"

                    if n == "FALLBACK" then
                        --  No matches until fallback? Then a complete value is provided.
                        res = colors.get(v)
                        break
                    end

                    v = tonumber(v)

                    if not v then
                        error("Vandal error: Value given to alternative \"" .. n .. "\" in color specification is not a valid number")
                    end

                    if n == csn or n == "REST" then
                        --  Either this is an identical match, or a common value as a fallback.
                        res = v
                        break
                    end
                end
            else
                --  Not a hex value, not a specification... Only other option is a name.

                local num = x11cols[val]

                if not num then
                    error("Vandal error: Unknown/undecipherable color value: \"" .. val .. "\".")
                end

                res = colors.rgb2ind(num)
            end
        end

        cache[val] = res
        return res
    end

    _G.COL = colors.get
end

function colors.round(num)
    return colors.ind2rgb(colors.rgb2ind(num))
end

return colors

