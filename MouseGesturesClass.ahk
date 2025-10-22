#Requires AutoHotkey v2.0


class _MG {
    static userSettings := {
        Buttons: Map(
            "~LButton", true,
            "RButton", true,
            "~MButton", true,
            "XButton1", true,
            "XButton2", true
        ),
        ButtonMap: Map(
            "L", "~LButton", "R", "RButton", "M", "~MButton",
            "X1", "XButton1", "X2", "XButton2", "LR", "LR"
        ),
        Interval: 20,
        LowThreshold: 10,
        Timeout: 1000,
        CancelTimeout: 800,
        CombinationTimeout: 800,
        ZoneCount: 8,
        Delimiter: ","
    }

    static utilityProperties := {
        ; Direction to zone mapping
        DirectionToZone: Map(
            "U", "8", "UR", "9", "R", "6", "DR", "3",
            "D", "2", "DL", "1", "L", "4", "UL", "7"
        ),
        browsers: [
            "ahk_class Chrome_WidgetWin_1 ahk_exe chrome.exe",
            "ahk_class Chrome_WidgetWin_1 ahk_exe msedge.exe",
            "ahk_class MozillaWindowClass ahk_exe firefox.exe",
            "ahk_class MozillaWindowClass ahk_exe zen.exe",
            "ahk_class Chrome_WidgetWin_1 ahk_exe thorium.exe",
            "ahk_class Chrome_WidgetWin_1 ahk_exe floorp.exe"
        ]
    }

    ; Internal state (now includes gestures)
    static state := {
        waitForRelease: false,
        lastGestureButton: "",
        currentGesture: "",
        targetWindow: 0,
        combinationDetected: false,
        gestureStartTime: 0,
        bothButtonsPressed: false,
        gestures: Map()
    }

    ; Initialize with dynamic property generation
    static __New() {
        ; Initialize OnWebsite class if it exists
        if IsSet(On) {
            try {
                On.Initialize()
            } catch {
            }
        }

        ; Set up button hotkeys
        for button, enabled in this.userSettings.Buttons {
            if (enabled) {
                Hotkey button, (thisHotkey) => this.GestureButton_Down(thisHotkey)
            }
        }

        ; Dynamically create all gesture properties
        this.CreateDynamicProperties()
    }

    static CreateDynamicProperties() {
        ; Build properties for each button id (L, R, M, X1, X2, LR)
        for buttonId, hotkeyName in this.userSettings.ButtonMap {
            ; Define a property named after the button id
            this.CreateGestureProperty(buttonId)
        }
    }

    static CreateGestureProperty(propName) {
        capturedButtonId := propName
        this.DefineProp(propName, {
            set: (this, value, gestureName, context := "", titleContext := "") => (
                this.RegisterGesture(
                    this.GestureNameToZones(gestureName),
                    capturedButtonId,
                    context,
                    titleContext,
                    value
                )
            )
        })
    }

    ; Convert gesture name to zone sequence
    static GestureNameToZones(gestureName) {
        ; Handle underscore-separated combinations (sequential movements)
        if (InStr(gestureName, "_")) {
            parts := StrSplit(gestureName, "_")
            zones := []

            for part in parts {
                if (this.utilityProperties.DirectionToZone.Has(part)) {
                    zones.Push(this.utilityProperties.DirectionToZone[part])
                } else {
                    throw Error("Unknown direction: " . part)
                }
            }

            ; Convert array to comma-separated string manually
            result := ""
            for i, zone in zones {
                if (i > 1) {
                    result .= ","
                }
                result .= zone
            }
            return result
        }

        ; Handle single directions
        if (this.utilityProperties.DirectionToZone.Has(gestureName)) {
            return this.utilityProperties.DirectionToZone[gestureName]
        }

        throw Error("Unknown gesture: " . gestureName)
    }

    ; Register gesture (updated to use state.gestures)
    static RegisterGesture(gesture, button, context, titleContext, callback) {
        if (!this.userSettings.ButtonMap.Has(button)) {
            throw Error("Invalid button: " . String(button))
        }

        if (!this.state.gestures.Has(gesture)) {
            this.state.gestures[gesture] := Map()
        }
        if (!this.state.gestures[gesture].Has(button)) {
            this.state.gestures[gesture][button] := []
        }

        gestureEntry := {
            url: context,
            title: titleContext,
            callback: callback
        }

        this.state.gestures[gesture][button].Push(gestureEntry)
    }

    ; Enhanced browser detection method
    static IsBrowserActive() {
        ; Check combined class and exe criteria with AND logic
        for criteria in this.utilityProperties.browsers {
            if (WinActive(criteria)) {
                return true
            }
        }
        return false
    }

    ; Handler for gesture button press
    static GestureButton_Down(thisHotkey) {
        this.ResetState()
        MouseGetPos(, , &hwndUnderMouse)
        this.state.targetWindow := hwndUnderMouse
        this.state.gestureStartTime := A_TickCount

        ; ; Special handling for LButton and MButton with Anki.  ; use this as a guide if you run into issues with activating certain programs
        ; if (thisHotkey = "~LButton" || thisHotkey = "~MButton") {
        ;     try {
        ;         activeWin := WinExist("A")
        ;         if (hwndUnderMouse != activeWin && WinGetClass("ahk_id " hwndUnderMouse) = "Anki") {
        ;             WinActivate("ahk_id " hwndUnderMouse)
        ;             return  ; Just activate, let the original click through
        ;         }
        ;     }
        ; }

        ; Window activation for right-click buttons
        if (thisHotkey = "RButton") {
            action := this.EnsureWindowActiveUnderMouse(hwndUnderMouse)
            if (action = "rightclick") {
                return  ; Window was activated, send the original click
            }
        }

        ; Store the raw hotkey name, but trim the ~ prefix for consistency
        this.state.lastGestureButton := (InStr(thisHotkey, "~") = 1) ? SubStr(thisHotkey, 2) : thisHotkey

        ; Set up Up hotkey for the current button
        if (thisHotkey = "~LButton") {
            Hotkey "LButton Up", (thisHotkey) => this.GestureButton_Up("LButton"), "On"
        } else {
            Hotkey thisHotkey " Up", (thisHotkey) => this.GestureButton_Up(thisHotkey), "On"
        }

        ; Set up hotkey for opposite button if L or R button
        if (thisHotkey = "~LButton") {
            Hotkey "RButton Up", (thisHotkey) => this.GestureButton_Up("LButton"), "On"
        } else if (thisHotkey = "RButton") {
            Hotkey "LButton Up", (thisHotkey) => this.GestureButton_Up(thisHotkey), "On"
        }

        this.state.waitForRelease := true

        ; Gesture detection loop
        this.DetectGesture()
    }

    static DetectGesture() {
        lastZone := -1
        MouseGetPos(&lastX, &lastY)
        originalButton := this.state.lastGestureButton

        while (this.state.waitForRelease) {
            Sleep this.userSettings.Interval

            ; Check for timeout
            if (A_TickCount - this.state.gestureStartTime > this.userSettings.CancelTimeout) {
                this.state.currentGesture := ""
                this.ResetState()
                break
            }

            ; Check for combination within timeout window
            if (!this.state.combinationDetected &&
                (A_TickCount - this.state.gestureStartTime <= this.userSettings.CombinationTimeout)) {

                if (originalButton = "LButton" && GetKeyState("RButton", "P")) {
                    this.state.combinationDetected := true
                    this.state.lastGestureButton := "LR"
                    this.state.bothButtonsPressed := true
                } else if (originalButton = "RButton" && GetKeyState("LButton", "P")) {
                    this.state.combinationDetected := true
                    this.state.lastGestureButton := "LR"
                    this.state.bothButtonsPressed := true
                }
            }

            ; Standard gesture detection
            MouseGetPos(&x, &y)
            offsetX := x - lastX
            offsetY := y - lastY

            if (offsetX != 0 || offsetY != 0) {
                distance := Sqrt(offsetX * offsetX + offsetY * offsetY)
                if (distance > this.userSettings.LowThreshold) {
                    angle := this.GetAngle(offsetX, offsetY)
                    lastX := x
                    lastY := y
                    zone := this.GetZone(angle, this.userSettings.ZoneCount)
                    if (zone != "" && lastZone != zone) {
                        lastZone := zone
                        this.state.currentGesture .= this.userSettings.Delimiter . zone
                    }
                }
            }
        }
    }

    static GestureButton_Up(thisHotkey) {
        ; Store current state before any modifications
        local currentGesture := this.state.currentGesture
        local lastButton := this.state.lastGestureButton
        local gestureStartTime := this.state.gestureStartTime
        local wasCombination := this.state.combinationDetected

        ; Comprehensive hotkey cleanup - turn off ALL potentially active hotkeys
        try {
            ; Always attempt to turn off both LButton and RButton up hotkeys
            Hotkey "LButton Up", "Off"
            Hotkey "RButton Up", "Off"

            ; Turn off other button up hotkeys if they might be active
            try Hotkey "~MButton Up", "Off"
            try Hotkey "XButton1 Up", "Off"
            try Hotkey "XButton2 Up", "Off"
        } catch {
            ; Silently continue if hotkey doesn't exist
        }

        ; Force immediate reset for XButtons and combinations
        if (InStr(thisHotkey, "XButton") || wasCombination) {
            this.state.waitForRelease := false
        }

        this.state.waitForRelease := false

        ; Clean up gesture string
        if (SubStr(currentGesture, 1, 1) = this.userSettings.Delimiter) {
            currentGesture := SubStr(currentGesture, 2)
        }

        if (currentGesture != "") {
            ; Gesture was detected - execute it
            local buttonId := ""
            if (lastButton = "LR") {
                buttonId := "LR"
            } else if (lastButton = "LButton") {
                buttonId := "L"
            } else if (lastButton = "RButton") {
                buttonId := "R"
            } else if (lastButton = "MButton") {
                buttonId := "M"
            } else if (lastButton = "XButton1") {
                buttonId := "X1"
            } else if (lastButton = "XButton2") {
                buttonId := "X2"
            }

            this.PerformGestureAction(currentGesture, buttonId)
        }
        else {
            ; No gesture detected - handle fallback behavior
            if (lastButton = "MButton")
               {
               Send("{" A_ThisHotkey "}")
               }
               ; customize long hold for Mbutton here
                ; {
                ;     {
                ;     local holdTime := A_TickCount - gestureStartTime
                ;     Sendlevel(1)
                ;        (holdTime < 200) ? Send("{" A_ThisHotkey "}") : Send("!{Tab}")
                ;     }
                ;        Sendlevel(0)
                ; }
            else if (lastButton = "RButton") {

            ;    customize long hold for R here
                {
                    local holdTime := A_TickCount - gestureStartTime
                ; if WinActive("Checklist:")
                ; {
                ;     Sendlevel(1)
                ;     (holdTime < 200) ? Sendinput("+{Capslock}") : Sendinput("!v")
                ;     Sendlevel(0)
                ; }
                if (this.MouseIsOver("ahk_class Shell_TrayWnd") || this.MouseIsOver("ahk_class Shell_SecondaryTrayWnd")) {
                    (holdTime < 200) ? Send("{RButton}") : Send("{RButton}")
                }
                else {
                    (holdTime < 200) ? Send("{RButton}") : Send("{RButton}")
                }
                }
            }
            else if (lastButton = "XButton1") {
                Send "{XButton1}" ; or customize as needed
            }
            else if (lastButton = "XButton2") {
               {
                Send "{XButton2}" ; or customize as needed
            }
            }
        }

        ; Always reset state at the end - single point of cleanup
        this.ResetState()
    }

    static MouseIsOver(WinTitle) {
        MouseGetPos(, , &Win)
        return WinExist(WinTitle " ahk_id " Win)
    }
    ; Enhanced gesture action execution with title priority
    static PerformGestureAction(gesture, button) {
        ; Get current URL only if On exists
        currentUrl := ""
        if IsSet(On) {
            try {
                currentUrl := On.LastResult.url ? On.LastResult.url : ""
            } catch {
                ; Silently fail if OnWebsite access fails
            }
        }

        ; Check for context menu
        hasContextMenu := false
        try {
            hasContextMenu := WinExist("ahk_class #32768")
        }

        ; Get window info
        activeWin := ""
        activeClass := ""
        activeExe := ""
        try {
            activeWin := WinGetTitle("A")
            activeClass := WinGetClass("A")
            activeExe := WinGetProcessName("A")
        }

        ; Check if we're in a browser using the enhanced method
        isBrowserActive := this.IsBrowserActive()

        ; Find and execute callback with title-priority system
        gestureCallback := this.FindGestureCallback(gesture, button, hasContextMenu, isBrowserActive, currentUrl, activeWin, activeClass, activeExe)

        if (gestureCallback) {
            gestureCallback()
            return true
        }
        return false
    }

    ; Enhanced callback finder with title priority and browser context support
    static FindGestureCallback(gesture, button, hasContextMenu, isBrowserActive, currentUrl, activeWin, activeClass, activeExe) {
        if (!this.state.gestures.Has(gesture) || !this.state.gestures[gesture].Has(button)) {
            return ""
        }

        gestureArray := this.state.gestures[gesture][button]

        ; 1. Context menu gestures
        if (hasContextMenu) {
            for entry in gestureArray {
                if (entry.url = "#32768" || entry.url = "ahk_class #32768") {
                    return entry.callback
                }
            }
        }

        ; 2. Special browser context handling
        if (isBrowserActive) {
            for entry in gestureArray {
                if (entry.url = "browser" || entry.url = "browsers") {
                    return entry.callback
                }
            }
        }

        ; 3. Website-specific gestures (URL-based)
        if (isBrowserActive && currentUrl) {
            for entry in gestureArray {
                if (entry.url && entry.url != "global" && entry.url != "" &&
                    entry.url != "browser" && entry.url != "browsers" &&
                    InStr(currentUrl, entry.url)) {
                    return entry.callback
                }
            }
        }

        ; 4. Title-specific gestures
        if (isBrowserActive && activeWin) {
            for entry in gestureArray {
                if (entry.title && entry.title != "" && InStr(activeWin, entry.title)) {
                    return entry.callback
                }
            }
        }

        ; 5. Window/class/process-specific gestures
        for entry in gestureArray {
            if (entry.url && entry.url != "global" && entry.url != "" &&
                entry.url != "browser" && entry.url != "browsers") {
                if ((activeWin && InStr(activeWin, entry.url)) ||
                    (activeClass && InStr(activeClass, entry.url)) ||
                    (activeExe && InStr(activeExe, entry.url)) ||
                    WinActive(entry.url)) {
                    return entry.callback
                }
            }
        }

        ; 6. Browser-specific gestures (empty string context)
        if (isBrowserActive) {
            for entry in gestureArray {
                if (entry.url = "" && entry.title = "") {
                    return entry.callback
                }
            }
        }

        ; 7. Global gestures
        for entry in gestureArray {
            if (entry.url = "global") {
                return entry.callback
            }
        }

        return ""
    }

    ; Ensure window under mouse is active - simplified version
    static EnsureWindowActiveUnderMouse(hwnd) {
        ; Check if window is already active
        if (WinExist("A") = hwnd) {
            return "gesture"  ; Already active, proceed with gesture detection
        }

        ; Get window info
        try {
            winClass := WinGetClass("ahk_id " hwnd)
            winExe := WinGetProcessName("ahk_id " hwnd)

            ; Activate the window
            WinActivate("ahk_id " hwnd)

            ; For certain window types, send the original click after activation
            ; edit here as needed
            if (winClass = "Anki" || winExe = "Image Occlusion Enhanced - Add Mode" || winExe = "Image Occlusion Enhanced - Editing Mode" || InStr(winClass, "Qt662QWindowIcon")) {
                return "rightclick"  ; Activate and send original click
            }

            return "gesture"  ; Just activate, proceed with gesture detection
        } catch {
            return "gesture"  ; On error, proceed with gesture detection
        }
    }

    ; Reset gesture state
    static ResetState() {
        this.state.waitForRelease := false
        this.state.lastGestureButton := ""
        this.state.currentGesture := ""
        this.state.targetWindow := 0
        this.state.combinationDetected := false
        this.state.gestureStartTime := 0
        this.state.bothButtonsPressed := false
    }

    ; Calculate angle from offsets
    static GetAngle(x, y) {
        if (x != 0) {
            deg := ATan(-y / x) * 57.295779513082323
            if (x < 0)
                return deg + 180
            else if (-y < 0)
                return deg + 360
            return deg
        } else {
            if (-y > 0)
                return 90.0
            else if (-y < 0)
                return 270.0
        }
        return 0
    }

    ; Get zone based on angle (numpad layout)
    static GetZone(angle, zoneCount) {
        if (zoneCount < 2)
            return ""
        degPerZone := 360 / zoneCount
        zone := Mod(Round(angle / degPerZone), zoneCount)
        zoneMap := Map(0, 6, 1, 9, 2, 8, 3, 7, 4, 4, 5, 1, 6, 2, 7, 3)
        return zoneMap[zone]
    }
}