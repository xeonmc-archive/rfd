Set fso = CreateObject("Scripting.FileSystemObject")
gameFolderPath = fso.GetParentFolderName(WScript.ScriptFullName)
replayFolderPath = gameFolderPath & "\replays"
If WScript.Arguments.Count > 0 Then
  For Each item In WScript.Arguments
    replayfull = item
    replayname = fso.GetBaseName(replayfull)
    replaypath = fso.GetParentFolderName(replayfull)
  Next
Else
  replayfull = SelectFile()
  If Len(replayfull) = 0 Then 
    WScript.Quit
  End If
  replayname = fso.GetBaseName(replayfull)
  replaypath = fso.GetParentFolderName(replayfull)
End If
If StrComp(replaypath, replayFolderPath, 1) Then
  fso.CopyFile replayfull, replayFolderPath & "\"
End If

Set objShell = CreateObject("Wscript.Shell")
objShell.CurrentDirectory = gameFolderPath
objShell.Run "reflex.exe +play " & replayname



Function SelectFile( )	

Dim objExec, strMSHTA, wshShell

SelectFile = ""

' For use in "plain" VBScript only:
strMSHTA = "mshta.exe ""about:<input type=file id=FILE>" & "<script>FILE.click();new ActiveXObject('Scripting.FileSystemObject')" & ".GetStandardStream(1).WriteLine(FILE.value);close();resizeTo(0,0);</script>"""

Set wshShell = CreateObject( "WScript.Shell" )
Set objExec = wshShell.Exec( strMSHTA )

SelectFile = objExec.StdOut.ReadLine( )

Set objExec = Nothing
Set wshShell = Nothing
End Function
