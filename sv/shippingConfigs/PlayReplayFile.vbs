Set fso = CreateObject("Scripting.FileSystemObject")
gameFolderPath = fso.GetParentFolderName(WScript.ScriptFullName)
replayFolderPath = gameFolderPath & "\replays"

' Check if there's a filepath reference via drag and drop
If WScript.Arguments.Count > 0 Then
  For Each item In WScript.Arguments
    replayfull = item
  Next
Else
  replayfull = GetFileDlg(replayFolderPath & "\*.rep", "Replay File (.rep)|*.rep|Compressed (zipped) File (.zip)|*.zip", "Select replay file...", "no")
  If Len(replayfull) = 0 Then 
    WScript.Quit
  End If
End If

replayname = fso.GetBaseName(replayfull)
replayextn = fso.GetExtensionName(replayfull)
replaypath = fso.GetParentFolderName(replayfull)

' Extract or copy replay file to the replays folder.
If replayextn = "zip" Then
  Set objShell = CreateObject("Shell.Application")
  Set FilesInZip = objShell.NameSpace(replayfull).Items()
  zipname = replayname
  For Each item in FilesInZip
    replayname = fso.GetBaseName(item)
    If replayname = zipname Then
      Exit For
    End If
  Next
  objShell.NameSpace(replayFolderPath).copyHere FilesInZip, 16
  Set objShell = Nothing
  Set FilesInZip = Nothing
ElseIf replayextn = "rep" AND StrComp(replaypath, replayFolderPath, 1) <> 0 Then
    fso.CopyFile replayfull, replayFolderPath & "\"
End If

' Check that replay file is actually in the replays folder before running, otherwise quit.
If fso.FileExists(replayFolderPath & "\" & replayname & ".rep") Then
  Set objShell = CreateObject("Wscript.Shell")
  objShell.CurrentDirectory = gameFolderPath
  objShell.Run "reflex.exe +play " & replayname
  Set objShell = Nothing
Else
  WScript.echo "No matching replay file found."
End If

Set fso = Nothing

Function GetFileDlg(sIniDir, sFilter, sTitle, sShow)
    ' source http://forum.script-coding.com/viewtopic.php?pid=75356#p75356
    Dim sSignature, oShellWnd, oWnd, oProc
    sSignature = Left(CreateObject("Scriptlet.TypeLib").Guid, 38)
    Set oProc = CreateObject("WScript.Shell").Exec("mshta ""about:<script>moveTo(-32000,-32000);document.title=' '</script><object id=d classid=clsid:3050f4e1-98b5-11cf-bb82-00aa00bdce0b></object><object id=s classid='clsid:8856F961-340A-11D0-A96B-00C04FD705A2'><param name=RegisterAsBrowser value=1></object><script>s.putproperty('" & sSignature & "',document.parentWindow);function q(i,f,t){return d.object.openfiledlg(i,null,f,t)};</script><hta:application showintaskbar=" & sShow & "/>""")
    On Error Resume Next
    Do
        If oProc.Status > 0 Then
            GetFileDlg = ""
            Exit Function
        End If
        For Each oShellWnd In CreateObject("Shell.Application").Windows
            Err.Clear
            Set oWnd = oShellWnd.GetProperty(sSignature)
            If Err.Number = 0 Then Exit Do
        Next
    Loop
    On Error GoTo 0
    oWnd.Document.Title = sTitle
    GetFileDlg = oWnd.q(sIniDir, sFilter, sTitle)
    oWnd.Close
End Function
