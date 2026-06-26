Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")

scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
repairScript = scriptDir & "\BetterDiscordRepair.ps1"
powershellPath = shell.ExpandEnvironmentStrings("%SystemRoot%") & "\System32\WindowsPowerShell\v1.0\powershell.exe"

If Not fso.FileExists(powershellPath) Then
    powershellPath = "powershell.exe"
End If

command = Chr(34) & powershellPath & Chr(34) & _
    " -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File " & _
    Chr(34) & repairScript & Chr(34) & " -CloseDiscord -Launch -Restart"

Set wmi = GetObject("winmgmts:\\.\root\cimv2")
Set startup = wmi.Get("Win32_ProcessStartup").SpawnInstance_
startup.ShowWindow = 0

result = wmi.Get("Win32_Process").Create(command, scriptDir, startup, processId)
If result <> 0 Then
    shell.Run command, 0, False
End If
