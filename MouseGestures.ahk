#Requires AutoHotkey v2.0

#SingleInstance Force

#Include MouseGesturesClass.ahk
#Include Monitor Manager.ahk
#Include OnWebsite.ahk ; uncomment for website-specific support, though it does require OnWebsite.ahk (On class) and Descolada's UIA library
#Include UIA\Lib\UIA.ahk
#Include UIA\Lib\UIA_Browser.ahk

; My defaults for mouse gestures:
; "R" here is right button, "UL" means upper left corner, and "gobal" will default to run everywhere, unless another _MG.R["UL"] is defined in a specific context (and we are in that context)
_MG.R["UL", "global"] := (*) => mm.GestureUL() ; closes program
_MG.R["UR", "global"] := (*) => mm.GestureUR() ; Maximizes window, or if maximized, full screen
_MG.R["DL", "global"] := (*) => mm.GestureDL() ; Un-full screen, or if already out of full screen, restores
_MG.R["DR", "global"] := (*) => mm.GestureDR() ; minimizes window
_MG.R["U", "browser"] := (*) => Send("^w") ; closes tabs in browsers, list of browsers defined in MouseGesturesClass
;; Note 'LR' - this is for pressing 'l' and 'r' buttons together, then moving left/right to snap the current window left or right in the current monitor
_MG.LR["L", "global"] := (*) => mm.SnapLeft("A")
_MG.LR["R", "global"] := (*) => mm.SnapRight("A")
; For R button gestures, I typically keep those four corners the same across all programs. For r button 'down'. I like to have a personal 'context menu' built with win32 controls, so my 'down' globally is built to show that as well. There is a place in the script where you can code long holds for each button if you want a normal click and longer held click action as well
;End of Default section




; Extra Examples for ideas/syntax
/*
; you can also go chain multiple directions, like going up then down (separated by _). Here it is with the X2 button:
_MG.X2["U_D", "global"] := (*) => SendInput("^{End}")
_MG.X2["D_U", "global"] := (*) => SendInput("^{Home}")

; Website specific example - needs the OnWebsite.ahk class and Descolada's UIA.ahk class included
_MG.R["R", "mail.google.com"] := (*) => Send("+3") ; deletes email
_MG.R["L", "mail.google.com"] := (*) => Send("e") ; archives email

; examples by Wintitle - "School - Anki" - a similified version of mine for demonstration:
_MG.L["L", "School - Anki"] := (*) => Send("1")
_MG.L["R", "School - Anki"] := (*) => Send("{Enter}")
_MG.L["U", "School - Anki"] := (*) => Send("4")
_MG.L["D", "School - Anki"] := (*) => Send("2")
_MG.L["UL", "School - Anki"] := (*) => Send("^+d")
_MG.R["U", "School - Anki"] := (*) => Send("y")

; examples by exe
_MG.R["R", "ahk_exe olk.exe"] := (*) => outlookdesktop.delete()
_MG.R["L", "ahk_exe olk.exe"] := (*) => outlookdesktop.archive()
_MG.R["U_D", "ahk_exe olk.exe"] := (*) => outlookdesktop.insert()

; examples by class
_MG.R["R", "ahk_class CabinetWClass", "Set Download Name"] := (*) => fileexplorer.saveasonenotepagetitle()
_MG.R["R", "ahk_class #32770"] := (*) => bwe({ LocalizedType: "split button", Name: "Open" })


; ; Note: if you have multiple URLs with similar urls, it goes with the first match (similar to how normal #hotif statements in ahk already work). Put the more complex url above the previous one
_MG.R["R", "studio.youtube.com"] := (*) => youtube.studio.insert()
_MG.R["R", "youtube.com"] := (*) => youtube.skipadd()
*/