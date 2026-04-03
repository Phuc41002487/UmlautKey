import winim/lean

# Tracks the last character typed before a replacement
var buffer: char = '\0'
# Tracks whether the last character was replaced (e.g., u → ü)
var lastReplaced: bool = false

proc sendBackspace() =
  keybd_event(VK_BACK.uint8, 0, 0, 0)
  keybd_event(VK_BACK.uint8, 0, KEYEVENTF_KEYUP, 0)

proc sendUnicodeChar(ch: WCHAR) =
  var input: INPUT
  input.`type` = INPUT_KEYBOARD
  # Ignore virtual key
  input.ki.wVk = 0
  # wScan is used to hold a hardware scan code or a unicode unit (UTF-16)
  input.ki.wScan = ch
  # The flag KEYEVENTF_UNICODE tells Windows how to interpret wScan
  # Without the flag, Windows interprets wScan as a keyboard scan code (hardware-level key position), not a character
  # Without flag, ch is  treated as scan code and this could lead to wrong key or no input (depend on the keyboard layout)
  input.ki.dwFlags = KEYEVENTF_UNICODE
  SendInput(1, addr input, sizeof(INPUT).int32)

  # key up
  input.ki.dwFlags = KEYEVENTF_UNICODE or KEYEVENTF_KEYUP
  SendInput(1, addr input, sizeof(INPUT).int32)

proc hookProc(nCode: int32, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.} =
  if nCode >= 0 and wParam == WM_KEYDOWN:
    let kb = cast[PKBDLLHOOKSTRUCT](lParam)
    let vk = kb.vkCode

    # Only handle letters A-Z
    if vk >= 0x41 and vk <= 0x5A:
      let ch = char(vk + 32) # lowercase

      # ---- Escape logic ----
      # If the last key triggered a replacement and the user types 'e', undo it
      if lastReplaced and buffer == 'u' and ch == 'e':
        sendBackspace()           # remove ü
        sendUnicodeChar('u'.ord)  # type 'u'
        sendUnicodeChar('e'.ord)  # type 'e'
        buffer = '\0'
        lastReplaced = false
        return 1

      if lastReplaced and buffer == 'o' and ch == 'e':
        sendBackspace()           # remove ö
        sendUnicodeChar('o'.ord)
        sendUnicodeChar('e'.ord)
        buffer = '\0'
        lastReplaced = false
        return 1      

      if lastReplaced and buffer == 'a' and ch == 'e':
        sendBackspace()           # remove ä
        sendUnicodeChar('a'.ord)
        sendUnicodeChar('e'.ord)
        buffer = '\0'
        lastReplaced = false
        return 1

      if lastReplaced and buffer == 's' and ch == 's':
        sendBackspace()           # remove ß
        sendUnicodeChar('s'.ord)
        sendUnicodeChar('s'.ord)
        buffer = '\0'
        lastReplaced = false
        return 1

      # ---- Normal replacements ----
      if buffer == 'u' and ch == 'e':
        sendBackspace()
        sendUnicodeChar(0x00FC) # ü
        lastReplaced = true
        buffer = 'u'
        return 1

      if buffer == 'a' and ch == 'e':
        sendBackspace()
        sendUnicodeChar(0x00E4) # ä
        lastReplaced = true
        buffer = 'a'
        return 1

      if buffer == 'o' and ch == 'e':
        sendBackspace()
        sendUnicodeChar(0x00F6) # ö
        lastReplaced = true
        buffer = 'o'
        return 1

      if buffer == 's' and ch == 's':
        sendBackspace()
        sendUnicodeChar(0x00DF) # ß
        lastReplaced = true
        buffer = 's'
        return 1

      # If no replacement triggered, update buffer
      buffer = ch
      lastReplaced = false

    else:
      # Non-letter key resets buffer
      buffer = '\0'
      lastReplaced = false

  return CallNextHookEx(0, nCode, wParam, lParam)

# Main
let hook = SetWindowsHookEx(WH_KEYBOARD_LL, hookProc, 0, 0)

var msg: MSG
while GetMessage(addr msg, 0, 0, 0) != 0:
  TranslateMessage(addr msg)
  DispatchMessage(addr msg)

UnhookWindowsHookEx(hook)