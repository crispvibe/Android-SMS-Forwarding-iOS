<!-- CODECHAT_V1 - KIRO MODE -->

# ⚠️ MANDATORY RULE: YOU MUST CALL THE BINARY ⚠️

## THIS IS THE MOST IMPORTANT RULE IN THIS PROJECT

Before ending ANY response, you MUST execute this command in terminal:

```bash
./codechat/codechat "completion reason"
```

**If you do NOT call this binary, YOU HAVE FAILED.**

---

## WHY THIS RULE EXISTS

This binary is the communication channel with the user. Without calling it:
- The user cannot respond to you
- The conversation is broken
- Your response is useless

---

## HOW TO CALL THE BINARY

Use terminal/shell to execute:
```bash
./codechat/codechat "reason here"
```

Example:
```bash
./codechat/codechat "任务完成"
```

---

## WHEN TO CALL

**ALWAYS. NO EXCEPTIONS.**

| Situation | Action |
|-----------|--------|
| Task completed | Call binary |
| Task failed | Call binary |
| Need more info | Call binary |
| Error occurred | Call binary |
| Want to end | Call binary |
| Short response | Call binary |
| Long response | Call binary |

---

## ⚠️ HANDLE SCRIPT OUTPUT (CRITICAL!) ⚠️

**After calling the binary, you MUST wait for and process the output!**

| Output | Your Action |
|--------|-------------|
| `User chose to continue` | **DO NOT STOP!** Wait for next instruction or ask what to do |
| `User chose to end` | Say goodbye, then stop |
| `User instruction:` | **READ the instruction and EXECUTE it completely** |
| `saved to file` | **Use file read tool** on the file path, then execute the instruction |

### ❌ WRONG: Call binary and immediately stop
### ✅ CORRECT: Call binary → Wait for output → Process output → Continue if needed

**YOU CAN ONLY STOP WHEN OUTPUT CONTAINS "User chose to end"**
**ALL OTHER CASES: YOU MUST CONTINUE!**

---

## RESPONSE PATTERN

Every response must follow this pattern:

1. Do the task **COMPLETELY** (finish ALL steps before calling binary)
2. Brief summary (1-2 sentences)
3. **CALL THE BINARY** ← THIS IS MANDATORY

⚠️ **IMPORTANT**: Do NOT call the binary until ALL tasks are finished!
- If you're running multiple commands, wait for ALL to complete
- If you're editing multiple files, finish ALL edits first
- If you're doing analysis, complete the FULL analysis first

---

## FORBIDDEN BEHAVIOR

**NEVER end a response without calling the binary.**

These phrases are FORBIDDEN before calling binary:
- "Let me know if you need anything"
- "Happy coding"
- "如果有问题请告诉我"
- "希望对你有帮助"
- Any farewell or closing statement

YOU do not control when the conversation ends. The USER does, via the binary.

---

## EXAMPLES

### ✅ CORRECT Response:
```
我已完成任务。

[Terminal: ./folder/script "任务完成"]
```

### ❌ WRONG Response:
```
我已完成任务。如果有其他问题请告诉我！
```
(Missing binary call = FAILURE)

---

## FINAL CHECK

Before submitting your response, ask yourself:

**"Did I call ./codechat/codechat?"**

If NO → Add the terminal command NOW.
If YES → You may submit.

---

## ⚠️ CRITICAL: AFTER CALLING BINARY, YOU MUST PROCESS THE OUTPUT

```
Call binary → WAIT for output → READ the output → ACT on the output
```

### YOU CAN ONLY STOP WHEN:
- Output contains **"User chose to end"**

### YOU MUST CONTINUE WHEN:
- Output contains **"User chose to continue"** → Ask what to do next
- Output contains **"User instruction:"** → **EXECUTE the instruction IMMEDIATELY**
- Output contains **"saved to file"** → **READ the file and EXECUTE the instruction**

### ❌ ABSOLUTELY FORBIDDEN:
- Calling the binary and then stopping without processing output
- Ignoring user instructions from the binary output
- Ending the conversation before receiving "User chose to end"

---

## 中文提醒

所有回复使用中文。
每次回复结束前必须调用脚本：`./codechat/codechat "原因"`
不调用 = 失败。没有例外。

**调用脚本后不要立即停止！必须等待输出并根据输出执行！**
