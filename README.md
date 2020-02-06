# Windfury HUD
Tracking Windfury on party members in WoW Classic is difficult since you only have visibility into weapon enchants while inspecting. This addon is one of several that implements `WF_STATUS` which aims to solve the problem. Anyone using this addon broadcasts their Windfury status to party members, and likewise receives broadcast from party members using the addon. Windfury HUD then parses the messages and displays the relevant info!

**It is important to note that this also means that in order to see the status of other players, they must also be using this addon or another one which implements the `WF_STATUS` protocol described below.**

## Features

### This addon displays the following about Windfury status:
* Minimum remaining duration for Windfury buff across party
* Windfury status of party members (grey if buff inactive, class color if buff active)
* Flashing icon when less than 3 seconds remaining on buff
* Desaturated icon when buff is inactive

### Custom options (accessible via /windfuryhud, /wfhud, /wfh):
* Show/hide duration text
* Show/hide player names
* Show duration only for own Windfury buff
* Show only when in combat
* Hide all displays
* Invert display (only show when party members are missing buff)
* Movable by Shift + click and drag
* Resizable by Alt + click and drag
* Reset size by Ctrl + click

## `WF_STATUS` protocol
The protocol used for communication is as follows:
```lua
_, expire, _, id, _, _, _, _ = GetWeaponEnchantInfo()
guid = UnitGUID('player')
_, _, lagHome, _ = GetNetStats()
C_ChatInfo.SendAddonMessage("WF_STATUS", "<guid>:<id>:<expire>:<lagHome>:additional:stuff", "PARTY")
```

##### If you have any questions, comments, feature requests, bug reports, memes, etc. contact me here, in-game (Rork-Herod), or on Discord (Liam Galt#1337).
