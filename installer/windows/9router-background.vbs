Option Explicit

' Chay 9Router nen de user chi can bam shortcut la mo dashboard.
Dim shell, fso, scriptDir, command, port
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
port = shell.ExpandEnvironmentStrings("%PORT%")
If port = "%PORT%" Then
  port = "20128"
End If

command = "cmd /c """ & scriptDir & "\9router.cmd"""
shell.Run command, 0, False

WScript.Sleep 3000
shell.Run "http://localhost:" & port & "/dashboard", 1, False
