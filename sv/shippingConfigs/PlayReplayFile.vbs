Set fso = CreateObject("Scripting.FileSystemObject")

gameFolderPath = fso.GetParentFolderName(WScript.ScriptFullName)
replayFolderPath = gameFolderPath & "\replays"

If WScript.Arguments.Count > 0 Then
  For Each item In WScript.Arguments
    replayfull = item
  Next
Else
  replayfull = SelectFile()
  If Len(replayfull) = 0 Then 
    WScript.Quit
  End If
End If

replayname = fso.GetBaseName(replayfull)
replayextn = fso.GetExtensionName(replayfull)
replaypath = fso.GetParentFolderName(replayfull)

If StrComp(replaypath, replayFolderPath, 1) Then
  If replayextn = "rep" Then
    fso.CopyFile replayfull, replayFolderPath & "\"
  ElseIf replayextn = "zip" Then 
    Set objShell = CreateObject("Shell.Application")
    Set FilesInZip=objShell.NameSpace(replayfull).Items()
    objShell.NameSpace(replayFolderPath).copyHere FilesInZip, 16
    Set objShell = Nothing
    Set FilesInZip = Nothing
  Else
    WScript.echo("This is not a replay file.")
    WScript.Quit
  End If
End If

Set objShell = CreateObject("Wscript.Shell")
objShell.CurrentDirectory = gameFolderPath
objShell.Run "reflex.exe +play " & replayname
Set fso = Nothing
Set objShell = Nothing

Function SelectFile( )	
  Dim objExec, strMSHTA, wshShell
  SelectFile = ""
  strMSHTA = "mshta.exe ""about:<input type=file id=FILE>" & _
                         "<script>FILE.click();new ActiveXObject('Scripting.FileSystemObject')" & _
                         ".GetStandardStream(1).WriteLine(FILE.value);close();resizeTo(0,0);</script>"""
  Set wshShell = CreateObject( "WScript.Shell" )
  Set objExec = wshShell.Exec( strMSHTA )
  SelectFile = objExec.StdOut.ReadLine( )
  Set objExec = Nothing
  Set wshShell = Nothing
End Function
