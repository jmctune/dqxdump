#SingleInstance, Off
#NoTrayIcon
#Include <classMemory>
#Include <convertHex>
#Include <JSON>

SetBatchLines, -1
FileEncoding UTF-8

if (2 != "")
  SplitPath, 2,,,, name_no_ext

;; iterate through each line in the file
FileRead, content, dumps/%1%.tmp

;; get total number of lines in file
Loop, Read, dumps/%1%.tmp
  total_lines = %A_Index%  ;; we use this for the loop below to not add a comma to the last line of the json
Sleep 50  ;; script tends to break if this is missing
FileDelete, dumps/%1%.tmp

;; parse through each line in content and format into nested json.
;; this format is weblate friendly and also the format that clarity expects.
FileAppend, {`r`n, dumps/ja/%1%.json
FileAppend, {`r`n, dumps/en/%1%.json

Loop, Parse, content, `n, `r
{
  if (A_Index != total_lines)
  {
    if (A_LoopField = "")  ;; if "" string was generated, add the clarity_nt_char tag for converting to 00
    {
      nt_unique_count++
      unique_val := "clarity_nt_char_" . nt_unique_count
      jaFormattedText := "  " . """" . A_Index """" . ": {" . "`n" . "    " . """" . unique_val . """: """ . unique_val . """" . "`n" . "  },"
      enFormattedText := "  " . """" . A_Index """" . ": {" . "`n" . "    " . """" . unique_val . """: """ . unique_val . """" . "`n" . "  },"
    }
    else if (A_LoopField = "　")  ;; if the JIS space was generated, add the clarity_ms_space tag for converting to e38080
    {
      ms_space_unique_count++
      unique_val := "clarity_ms_space_" . ms_space_unique_count
      jaFormattedText := "  " . """" . A_Index """" . ": {" . "`n" . "    " . """" . unique_val . """: """ . unique_val . """" . "`n" . "  },"
      enFormattedText := "  " . """" . A_Index """" . ": {" . "`n" . "    " . """" . unique_val . """: """ . unique_val . """" . "`n" . "  },"
    }
    else
    {
      unique_val := A_LoopField
      jaFormattedText := "  " . """" . A_Index """" . ": {" . "`n" . "    " . """" . unique_val . """: """ . unique_val . """" . "`n" . "  },"
      enFormattedText := "  " . """" . A_Index """" . ": {" . "`n" . "    " . """" . unique_val . """: """ . """" . "`n" . "  },"
    }

    FileAppend, %jaFormattedText%`n, dumps/ja/%1%.json
    FileAppend, %enFormattedText%`n, dumps/en/%1%.json
  }
  else  ;; don't add comma to the last object
  {
    if (A_LoopField = "")
    {
      nt_unique_count++
      unique_val := "clarity_nt_char_" . nt_unique_count
      jaFormattedText := "  " . """" . A_Index """" . ": {" . "`n" . "    " . """" . unique_val . """: """ . unique_val . """" . "`n" . "  }"
      enFormattedText := "  " . """" . A_Index """" . ": {" . "`n" . "    " . """" . unique_val . """: """ . """" . "`n" . "  }"
    }
    else if (A_LoopField = "　")  ;; special monospaced space used in JIS text
    {
      ms_space_unique_count++
      unique_val := "clarity_ms_space_" . ms_space_unique_count
      jaFormattedText := "  " . """" . A_Index """" . ": {" . "`n" . "    " . """" . unique_val . """: """ . unique_val . """" . "`n" . "  },"
      enFormattedText := "  " . """" . A_Index """" . ": {" . "`n" . "    " . """" . unique_val . """: """ . unique_val . """" . "`n" . "  },"
    }
    else
    {
      unique_val := A_LoopField
      jaFormattedText := "  " . """" . A_Index """" . ": {" . "`n" . "    " . """" . unique_val . """: """ . unique_val . """" . "`n" . "  }"
      enFormattedText := "  " . """" . A_Index """" . ": {" . "`n" . "    " . """" . unique_val . """: """ . """" . "`n" . "  }"
    }

    FileAppend, %jaFormattedText%, dumps/ja/%1%.json
    FileAppend, %enFormattedText%, dumps/en/%1%.json
  }
}
FileAppend, `r`n}, dumps/ja/%1%.json
FileAppend, `r`n}, dumps/en/%1%.json

;; with the finished json, we need to make sure our json stays valid.
;; there are some escaped characters in dqx that we need to account for.
FileRead, jaFinalJson, dumps/ja/%1%.json
FileRead, enFinalJson, dumps/en/%1%.json
FileDelete, dumps/ja/%1%.json
FileDelete, dumps/en/%1%.json
jaReplace := StrReplace(jaFinalJson, "\s", "\\s")
jaReplace := StrReplace(jaReplace, "\m", "\\m")
jaReplace := StrReplace(jaReplace, "\e", "\\e")
enReplace := StrReplace(enFinalJson, "\s", "\\s")
enReplace := StrReplace(enReplace, "\m", "\\m")
enReplace := StrReplace(enReplace, "\e", "\\e")
FileAppend, %jaReplace%, dumps/ja/%1%.json
FileAppend, %enReplace%, dumps/en/%1%.json

;; rename the files to their appropriate names if we know them
if (name_no_ext != "")
{
  FileMove, %A_ScriptDir%\dumps\ja\%1%.json, %A_ScriptDir%\completed\known\ja\%name_no_ext%.json
  FileMove, %A_ScriptDir%\dumps\en\%1%.json, %A_ScriptDir%\completed\known\en\%name_no_ext%.json
}
else
{
  FileMove, %A_ScriptDir%\dumps\ja\%1%.json, %A_ScriptDir%\completed\unknown\ja\%1%.json
  FileMove, %A_ScriptDir%\dumps\en\%1%.json, %A_ScriptDir%\completed\unknown\en\%1%.json
}
