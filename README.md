# Purpose
The application is developed to support typing three umlauts (ä, ö, ü) and the sharp s (ß, called Eszett or scharfes S) on a non-German layour keyboard.  
The app is a Nim version inspired from the Rust version (develop by [Mr. Duong](https://github.com/duong-se)) which can be found [here](https://github.com/duong-se/umlautkey)

# How to use
To run the application simply run the UmlautKey.exe in CMD.<br>

The rule is as follow:<br>
ae -> ä<br>
ue -> ü<br>
oe -> ö<br>
ss -> ß

To escape the special character, just type the last character to cancel it (e or s) just like the following:<br>
aee -> ae<br>
uee -> ue<br>
oee -> oe<br>
sss -> ss

# Thing I learned
### 1. What does this ```var input: INPUT``` mean?
In the Windows API, INPUT is a union-like structure that can represent different kinds of input:

- Keyboard
- Mouse
- Hardware

In C it looks roughly like:

```
typedef struct tagINPUT {
DWORD type;
union {
    MOUSEINPUT mi;
    KEYBDINPUT ki;
    HARDWAREINPUT hi;
};
} INPUT;
```
More information about ```INPUT``` can be found [here](https://learn.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-input)

What ki means
- ki = KEYBDINPUT
- It holds all the data for a keyboard event  

What's inside ```KEYBDINPUT```
```
input.ki.wVk        # virtual key code (e.g. VK_RETURN)
input.ki.wScan      # hardware scan code OR Unicode char
input.ki.dwFlags    # flags (KEYEVENTF_UNICODE, KEYUP, etc.)
input.ki.time       # timestamp (usually 0)
input.ki.dwExtraInfo # extra data (usually 0)
```
More information about ```KEYBDINPUT``` can be found [here](https://learn.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-keybdinput)

Why do we need ```input.ki.dwFlags = KEYEVENTF_UNICODE```?  
```wScan``` does not inherently mean Unicode.
It’s just a field that can hold either:
- a hardware scan code, or
- a Unicode UTF-16 code unit

The flag ```KEYEVENTF_UNICODE``` tells Windows how to interpret ```wScan```.  
Without the flag
```
input.ki.wScan = ch
# no KEYEVENTF_UNICODE
```

Windows interprets ```wScan``` as a keyboard scan code (hardware-level key position), not a character. So:
- 65 → might mean the physical key for “A” (depending on layout)
- ❌ Not treated as Unicode 'A'

### 2. What is ```SendInput```?
In C, the function looks like:
```
UINT SendInput(
  UINT    cInputs,
  LPINPUT pInputs,
  int     cbSize
);
```
So ```SendInput(1, addr input, sizeof(INPUT).int32)``` means:
- 1: Number of input event we are sending
- addr input: pointer to the ```input``` struct
- sizeof(INPUT).int32: Size of one ```INPUT``` struct in bytes. Cast to ```int32``` because the API expects an ```int```.

More information about ```SendInput``` can be found [here](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-sendinput)

### 3. Why ```SendInput``` need to be called two times?
Because a key press is actually two separate events in Windows:
1. Key down (press)
2. Key up (release)

**Why both are needed**  
Operating systems track key state like this:
- Key down → “key is pressed”
- Key up → “key is released”

If you only send key down:
- The system thinks the key is still being held
- Can cause:
    - repeated input (like holding a key)
    - stuck modifier keys (Ctrl, Shift, etc.)

## FAQ
1. Does this project use AI code?<br>
Of course. What are you thinking?

2. What is the next update?<br>
Adding more comment so I can understand chatGPT code.<br>

3. Why it is in NIM?<br>
Because I am trying to learn NIM.

4. If you are trying to learn NIM, why did you use AI?<br>
Because I am lazy.
