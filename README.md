# **MouseGestures.ahk - Context Sensitive Mouse Gestures in AutoHotkey v2**

---

## **TLDR:**

I use this class, `_MG`, to create mouse gestures for quick window management and program-specific shortcuts.  
Hold a mouse button (Right, Left, Middle, or extra buttons) and draw a direction to trigger an action.  

This is similar to my 8bitdo script, which supports **context-specific mappings with global fallbacks**, so you don't need to rewrite common gestures for every program. If my OnWebsite.ahk class and Descolada's UIA uia library are included, you can also write **website-specific** mouse gestures.

**Key Features:**
- 8-directional gestures: Up, Down, Left, Right, and diagonals (UL, UR, DL, DR)  
- Chained gestures: Draw multiple directions in sequence (e.g., `U_D` for up-then-down)  
- Button combinations: Press Left+Right buttons together for special actions  
- Context-aware: Different gestures for different programs, windows, or websites  
- Smart fallbacks: Define once globally, override for specific contexts  
- Browser integration: Works with website-specific gestures (requires `OnWebsite.ahk`)  

---

## **Quick Example**
The 'button' is defined outside the [], and the direction is defined in the first parameter. The second parameter is for context specificity (see part 4 for more details)
```ahk
_MG.R["UL", "global"] := (*) => MsgBox("Right button, gesture upper-left")
_MG.R["DR", "global"] := (*) => MsgBox("Right button, gesture down-right")
_MG.LR["L", "global"] := (*) => MsgBox("Left Button and Right button, gesture left")
```

**How it works:**
The script keeps track of where the mouse was when the key is pressed down, during movement, and when it was released. Then, it looks at that vectors to determine which action to send.

---

## **Button Names**

| Button ID | Description |
|------------|-------------|
| L | Left mouse button |
| R | Right mouse button |
| M | Middle mouse button (scroll wheel click) |
| X1 | Extra button 1 (usually “Back” button) |
| X2 | Extra button 2 (usually “Forward” button) |
| LR | Both Left + Right buttons pressed together |

---

## **Gesture Directions**
These are used in the first parameter inside [] to show direction the 
- `U` – Up  
- `D` – Down  
- `L` – Left  
- `R` – Right  
- `UL` – Upper-Left (diagonal)  
- `UR` – Upper-Right (diagonal)  
- `DL` – Down-Left (diagonal)  
- `DR` – Down-Right (diagonal)  

**Chained gestures:**
Use underscore `_` between letter to chain multiple directions:

```ahk
_MG.R["U_D", "global"] := (*) => MsgBox("Up then Down")
_MG.R["L_R", "global"] := (*) => MsgBox("Left then Right")
_MG.X2["U_D_U", "global"] := (*) => MsgBox("Complex chain")
```

---


## **Getting Started**
Download the source code, unzip, and right click 'MouseGestures Example' to open in an editor. This will let you view the gestures/change them. The dependences listed below are in the folder relative to the 'MouseGestures Examples.ahk' file, so you should be able to double click it test out the gestures. 
**Required Files:**
```ahk
#Requires AutoHotkey v2.0
#Include MouseGesturesClass.ahk ; contains the logic for the mouse gestures
```

**Optional (for making the sample file work):**
```ahk
#Include OnWebsite.ahk ; grabs current url and caches it
#Include UIA\Lib\UIA.ahk ; works with OnWebsite
#Include UIA\Lib\UIA_Browser.ahk ; works with onwebsite
#Include MonitorManager.ahk ; adds functionality to snapping windows left, right, moving to a specific monitor, etc.
```
---


## **My Sample Default Mappings**
I like these and use imitations of them in my normal keyboard shortcuts, my 8bitdo class for the 'd' pad, and in my my qmk.ahk script for consistency. UL will close the window, UR will maximized if not maximized, and full screen if already maximized. DL will reverse UR, either going out of full screen if in full screen, or restoring the window. DL will minimize the program. 

I also like having mappings to snap widows to the right and left half of the current monitor, and other mappings move windows to the next monitor if using multiple displays. Pressing both 'L' and 'R' together then moving to the left and right will snap to that direction, and moving left then right with both pressed will 'Throw' to the right monitor.

These are just my defaults though, feel free to edit those in the monitor manager class or define your own hotkeys to call per program! Additionally, feel free to rename the class if you would like. 
---
**Window Management (with Monitor Manager):**
```ahk
_MG.R["UL", "global"] := (*) => mm.GestureUL()
_MG.R["UR", "global"] := (*) => mm.GestureUR()
_MG.R["DL", "global"] := (*) => mm.GestureDL()
_MG.R["DR", "global"] := (*) => mm.GestureDR()

; Snap or throw windows with both the L and R mouse buttons pressed together
_MG.LR["L", "global"] := (*) => mm.SnapLeft("A")
_MG.LR["R", "global"] := (*) => mm.SnapRight("A")
_MG.LR["L_R", "global"] := (*) => mm.ThrowRight() ; throw to next right of current
_MG.LR["R_L", "global"] := (*) => mm.ThrowLeft() ; throw to monitor left of current
```

## Additional Shortcuts for ideas of what you could do:
**Browser Shortcuts:**
Ideas of what you could do in browsers
```ahk
_MG.R["U", "browser"] := (*) => Send("^w")       ; Close tab
_MG.R["D", "browser"] := (*) => Send("^+t")      ; Reopen closed tab
_MG.R["L", "browser"] := (*) => Send("^+{Tab}")  ; Previous tab
_MG.R["R", "browser"] := (*) => Send("^{Tab}")   ; Next tab

```
---

**Website-Specific Examples**

**YouTube:**
```ahk
_MG.R["R", "youtube.com"] := (*) => Send("{Right}")
_MG.R["L", "youtube.com"] := (*) => Send("{Left}")
_MG.R["U_D", "youtube.com"] := (*) => Send("c") ; turn on captions
_MG.R["D", "youtube.com"] := (*) => Send("{Space}") ; play/pause
_MG.L["UR", "youtube.com"] := (*) => Send("f") ; full screen, overrides the global UR gesture
_MG.R["L_R", "youtube.com"] := (*) => youtube.skipadd()
```

**Gmail:**
```ahk
_MG.R["R", "mail.google.com"] := (*) => Send("+3") ; delete email
_MG.R["L", "mail.google.com"] := (*) => Send("e") ; archive
```

Other Examples by wintitle, class, and exe
**Anki (by window title):**
A few examples
```ahk
_MG.L["L", "School - Anki"] := (*) => Send("1") ; mark as 'again'
_MG.L["D", "School - Anki"] := (*) => Send("2") ; mark as 'hard'
_MG.L["R", "School - Anki"] := (*) => Send("{Enter}") ; mark as 'good' or flip card
_MG.L["U", "School - Anki"] := (*) => Send("4") ; ; mark as 'easy'
_MG.L["UL", "School - Anki"] := (*) => Send("^+d") ; set due date
_MG.R["U", "School - Anki"] := (*) => Send("y") ; sync
```

**File Explorer (by class):**
```ahk
_MG.R["U", "ahk_class CabinetWClass"] := (*) => Send("!{Up}")
_MG.R["D", "ahk_class CabinetWClass"] := (*) => Send("{Enter}")
_MG.R["L", "ahk_class CabinetWClass"] := (*) => Send("!{Left}")
_MG.R["R", "ahk_class CabinetWClass"] := (*) => Send("!{Right}")
```

**Outlook Desktop (by exe):**
```ahk
_MG.R["R", "ahk_exe olk.exe"] := (*) => Send("^d")
_MG.R["L", "ahk_exe olk.exe"] := (*) => Send("^e")
_MG.R["U", "ahk_exe olk.exe"] := (*) => Send("^r")
_MG.R["D", "ahk_exe olk.exe"] := (*) => Send("^+r")
```

**Context menu (Win32 menus):**
```ahk
_MG.R["D", "ahk_class #32768"] := (*) => Send("{Down}")
```

**Multiple contexts (with title specification):**
```ahk
_MG.R["R", "ahk_class CabinetWClass", "Downloads"] := (*) => MsgBox("In Downloads folder")
```
---


## **Context Priority Order**

When you perform a gesture, the `_MG` class checks contexts in this order, then fires the first one that it mactches:

1. Win32 Context Menus (`ahk_class #32768`)  
2. Browser context ("browser" or "browsers")  
3. Website-specific (URL matching — requires `OnWebsite.ahk`)  
4. Window title matches  
5. Window class matches  
6. Window executable matches  
7. Browser fallback (for any detected browser window)  
8. Global mappings (last resort)

This allows you to set defaults globally and override them for specific programs or websites.

---


## **Best Practices/Integration with Other Scripts**
When overlapping URLs exist, list **more specific first**, earlier in your script:

```ahk
; ✅ Correct
_MG.R["R", "studio.youtube.com"] := (*) => MsgBox("YouTube Studio")
_MG.R["R", "youtube.com"] := (*) => MsgBox("Regular YouTube")

; ❌ Wrong
_MG.R["R", "youtube.com"] := (*) => MsgBox("Regular YouTube")
_MG.R["R", "studio.youtube.com"] := (*) => MsgBox("Never fires!")
```

This script integrates well with:
- **8BitDo.ahk** — controller gestures  
- **Macropad.ahk** — additional context menus  
- **QMK.ahk** —  QMK-like functionatlity with rollover support, homerow modifiers, and custom key combos.
  
All three scripts use OnWebsite.ahk to cache the current URL for URL-sensitive hotkeys/hotstrings. I reccommend consolidating all three to run in one main script to avoid reduce the number of calls to grab urls. 



## **Advanced Configuration Options**

You can customize gesture detection settings in the mousegestures class file:

```ahk
static userSettings := {
    Buttons: Map(
        "~LButton", true,
        "RButton", true,
        "~MButton", true,
        "XButton1", true,
        "XButton2", true
    ),
    Interval: 20,           ; Mouse polling interval (ms)
    LowThreshold: 10,       ; Minimum movement (pixels)
    Timeout: 1000,          ; Max gesture duration (ms)
    CancelTimeout: 800,     ; Auto-cancel timeout (ms)
    CombinationTimeout: 800 ; LR combination window (ms)
}
```

If you press a button but don't move the mouse, the script has fallback behaviors:

**Middle Button:**
- Short press: Normal middle click  
- Long hold: Customizable  

**Right Button:**
- Short press: Normal right click  
- Long hold: Customizable  

**Extra Buttons (X1, X2):**
- No gesture: Sends the original button press  

If needed, Customize these behaviors inside `GestureButton_Up() method`. Ex. If LastKey was R button and If WinActive("ahk_exe chrome.exe"), then >>

---


## **Troubleshooting**

**Gesture not firing:**
- Check if a more specific context overrides your global one  
- Ensure the movement passes the `LowThreshold`  
- Verify button is enabled in `userSettings.Buttons`  

**Wrong gesture detected:**
- Move the mouse more deliberately  
- Adjust `Interval` or `LowThreshold`  

**Button not working:**
- Ensure the button is enabled  
- Verify your mouse driver isn’t intercepting it  
- Try using `~` prefix for passthrough  

---



