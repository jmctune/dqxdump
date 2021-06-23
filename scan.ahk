#SingleInstance, On
#Include <classMemory>
#Include <convertHex>
#Include <JSON>

SetBatchLines, -1
FileEncoding UTF-8
dqx := new _ClassMemory("ahk_exe DQXGame.exe", "", hProcessCopy)

;; get AOBs for start/end
startAOB := dqx.hexStringToPattern("49 4E 44 58 10 00 00") ;; INDX block start
textAOB := dqx.hexStringToPattern("54 45 58 54 10 00 00") ;; TEXT block start
endAOB := dqx.hexStringToPattern("46 4F 4F 54 10 00 00")  ;; FOOT block end
start_addr := 0

;; clean up files/folders before run
FileRemoveDir, dumps, 1
FileRemoveDir, completed, 1
FileDelete, hex_dict.csv
FileDelete, add_to_master.csv
FileCreateDir, dumps
FileCreateDir, dumps/en
FileCreateDir, dumps/ja
FileCreateDir, dumps/hex
FileCreateDir, dumps/tmp
FileCreateDir, completed
FileCreateDir, completed/known
FileCreateDir, completed/known/en
FileCreateDir, completed/known/ja
FileCreateDir, completed/unknown
FileCreateDir, completed/unknown/en
FileCreateDir, completed/unknown/ja

;; open a progress ui
Gui, 2:Default
Gui, Font, s12
Gui, +AlwaysOnTop +E0x08000000
Gui, Add, Edit, vNotes w500 r10 +ReadOnly -WantCtrlA -WantReturn,
Gui, Show, Autosize

;; start timer
startTime := A_TickCount

Loop
{
  file := A_Index

  ;; iterate through each file loaded into mem
  start_addr := dqx.processPatternScan(start_addr,, startAOB*)  ;; find each unique block
  hex_start := dqx.readRaw(start_addr, hexbuf, 64)
  hex_start := bufferToHex(hexbuf, 64)

  ;; if we can't find any more matches, we're done
  if start_addr = 0
    Break

  ;; we found a match, so keep going.
  start_addr := dqx.processPatternScan(start_addr,, textAOB*)  ;; jump to the start of the block
  end_addr   := dqx.processPatternScan(start_addr + 1,, endAOB*)  ;; jump to the end of the block

  ;; get difference of end_addr and start_addr to give us total bytes read
  diff := (end_addr - start_addr)

  ;; read entire space and put into buffer, then convert to hex
  dqx.readRaw(start_addr, buf, diff)
  buf_hex := bufferToHex(buf, diff)

  ;; remove beginning TEXT[] garbage
  trimmed_hex := SubStr(buf_hex, 37)

  ;; remove more garbage. leading/trailing 00's
  trimmed_hex := LTrim(trimmed_hex)  ;; remove spaces before
  trimmed_hex := RTrim(trimmed_hex)  ;; remove spaces after
  trimmed_hex := LTrim(trimmed_hex, "00")
  trimmed_hex := LTrim(trimmed_hex, "00 ")
  trimmed_hex := LTrim(trimmed_hex, " 00")
  trimmed_hex := RTrim(trimmed_hex, "00")
  trimmed_hex := RTrim(trimmed_hex, "00 ")
  trimmed_hex := RTrim(trimmed_hex, " 00")

  ;; replace line breaks with pipes and line terms with line breaks.
  trimmed_hex := StrReplace(trimmed_hex, "0A", "7C")
  trimmed_hex := StrReplace(trimmed_hex, "00", "0A")
  trimmed_hex := StrReplace(trimmed_hex, "09", "5C 74")

  ;; check last hex value. if only one character, add a 0 because we inadvertently chopped it off.
  last := SubStr(trimmed_hex, -1)
  if InStr(last, " ")
    trimmed_hex := trimmed_hex . "0"

  ;; dump hex for debugging
  FileAppend, %trimmed_hex%, dumps/hex/%file%.txt

  ;; convert the hex to strings
  strings := convertHexToStr(trimmed_hex)

  ;; finally, write to file
  FileAppend, %strings%, dumps/%file%.tmp

  ;; write dict to file. parse master csv to figure out what the file is
  Loop, Read, %A_ScriptDir%\master\hex_dict.csv
  {
    Loop, Parse, A_LoopReadLine, CSV
    {
      if (A_LoopField = hex_start)
      {
        split := StrSplit(A_LoopReadLine, ",")
        fileName := split[1]
        FileAppend, %fileName%`,%hex_start%`n,hex_dict.csv
        break
      }
    }
  }

  ;; if we couldn't find the file in our master list, it's new and we need to review it
  if (fileName = "")
    FileAppend, %file%`,%hex_start%`n,add_to_master.csv

  ;; kick off transform script
  Run, %A_ScriptDir%\transform.ahk %file% %fileName%

  ;; clear buffer and iterate to next block
  buf :=
  strings := 
  fileName :=
  start_addr := end_addr + 1
  GuiControl,, Notes, On file: %file%
}

;; check remaining files being processed
while (numberOfRunningProcesses != 0)
{
  numberOfRunningProcesses = 0
  for process in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process")
  {
    if process.Name = "AutoHotkey.exe"
      numberOfRunningProcesses++
  }
  GuiControl,, Notes, Left to process: %numberOfRunningProcesses%
  sleep 500
}

elapsedTime := A_TickCount - startTime
GuiControl,, Notes, Done.`n`nElapsed time: %elapsedTime%ms

Sleep 2000
ExitApp
