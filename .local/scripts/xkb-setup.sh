#!/bin/bash
target=/usr/share/X11/xkb/symbols
# ====================================================================================================
# /usr/share/X11/xkb/symbols/pc
# ====================================================================================================
#     key <RCTL> {[  Mode_switch ]};
sed -i 's/key <RCTL> {\[  Control_R  \]}/key <RCTL> {\[  Mode_switch \]}/' "$target/pc"
# ====================================================================================================
# /usr/share/X11/xkb/symbols/us
# ====================================================================================================
sed -i 's/key <AD09>	{\[	 o,	 O		\]}/key <AD09>	{\[	 o,	 O		\], \[ Home \]}/' "$target/us"
sed -i 's/key <AD10>	{\[	 p,	 P		\]}/key <AD10>	{\[	 p,	 P		\], \[ End  \]}/' "$target/us"
sed -i 's/key <AD11>	{\[ bracketleft,	 braceleft	\]}/key <AD11>	{\[ bracketleft,	 braceleft	\], \[ Prior \]}/' "$target/us"
sed -i 's/key <AD12>	{\[ bracketright, braceright	\]}/key <AD12>	{\[ bracketright, braceright	\], \[ Next  \]}/' "$target/us"
sed -i 's/key <AC06>	{\[	 h,	 H		\]}/key <AC06>	{\[	 h,	 H		\], \[ Left  \]}/' "$target/us"
sed -i 's/key <AC07>	{\[	 j,	 J		\]}/key <AC07>	{\[	 j,	 J		\], \[ Down  \]}/' "$target/us"
sed -i 's/key <AC08>	{\[	 k,	 K		\]}/key <AC08>	{\[	 k,	 K		\], \[ Up    \]}/' "$target/us"
sed -i 's/key <AC09>	{\[	 l,	 L		\]}/key <AC09>	{\[	 l,	 L		\], \[ Right \]}/' "$target/us"

#     key <AD09>	{[	 o,	 O		], [ Home ]};
#     key <AD10>	{[	 p,	 P		], [ End  ]};
#     key <AD11>	{[ bracketleft,	 braceleft	], [ Prior ]};
#     key <AD12>	{[ bracketright, braceright	], [ Next  ]};
#
#     key <AC06>	{[	 h,	 H		], [ Left ]};
#     key <AC07>	{[	 j,	 J		], [ Down ]};
#     key <AC08>	{[	 k,	 K		], [ Up   ]};
#     key <AC09>	{[	 l,	 L		], [ Right]};
# ====================================================================================================
#
