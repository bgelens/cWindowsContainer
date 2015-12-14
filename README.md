cWindowsContainer
=================

Class Based DSC resource to deploy Windows Containers.

**Update Sep 2015**
Get-DscConfiguration now shows ContainerId and currently assigned IP Address
![Config](https://github.com/bgelens/cWindowsContainer/blob/master/GetDSCConfigIPandID.jpg)
**Update Dec 2015**
Resource updated for TP4 (TP3 must use version 1.0).
Now supports HyperV container type and the defining of the hostname within the container.
Validated Nano Server compatibility

**Deploy container from Nano image with single line startup script**
```powershell
configuration NewContainer {
    Import-DscResource -ModuleName cWindowsContainer -ModuleVersion 1.1

    cWindowsContainer MyAppContainer {
        Ensure = 'Present'
        Name = 'MyAppContainer'
        StartUpScript = '"Hello World" | out-file c:\hello.txt'
        ContainerImageName = 'NanoServer'
    }
}
NewContainer
Start-DscConfiguration .\NewContainer -Wait -Verbose
```
![Config](https://github.com/bgelens/cWindowsContainer/blob/master/newcontainerconfig.jpg)

**Deploy container from Nano image with multi-line startup script and specifying Container Hostname**
````powershell
configuration MultiLineConfigContainer {
    param (
        [String] $StartupScript
    )
    Import-DscResource -ModuleName cWindowsContainer -ModuleVersion 1.1

    cWindowsContainer MyDCContainer {
        Ensure = 'Present'
        Name = 'MyDCContainer'
        StartUpScript = $StartupScript
        ContainerImageName = 'NanoServer'
        ContainerType = 'HyperV'
        ContainerComputerName = 'MyContainer'
    }
}

$script = @'
$computername = $env:COMPUTERNAME
$computername.tolower() | out-file c:\compname.txt
'@

MultiLineConfigContainer -StartupScript $script
Start-DscConfiguration .\MultiLineConfigContainer -Wait -Verbose
```

**Remove container**
```powershell
configuration RemContainer {
    Import-DscResource -ModuleName cWindowsContainer -ModuleVersion 1.1

    cWindowsContainer MyAppContainer {
        Ensure = 'Absent'
        Name = 'MyAppContainer'
        ContainerImageName = 'NanoServer'
    }
}
RemContainer
Start-DscConfiguration .\RemContainer -Wait -Verbose
```
**NGINX install and Network (does not work on Nano as Invoke-WebRequest is not available)**
```powershell
configuration ContainerNginX {
    param (
        [String] $StartupScript
    )
    Import-DscResource -ModuleName cWindowsContainer -ModuleVersion 1.1

    cWindowsContainer NginX {
        Ensure = 'Present'
        Name = 'NginX'
        StartUpScript = $StartupScript
        SwitchName = 'Virtual Switch'
        ContainerImageName = 'WindowsServerCore'
    }
}

$script = @'
Invoke-WebRequest -Uri 'http://nginx.org/download/nginx-1.9.4.zip' -OutFile 'c:\nginx-1.9.4.zip'
Unblock-File -Path 'c:\nginx-1.9.4.zip'
Expand-Archive -Path 'c:\nginx-1.9.4.zip' -DestinationPath C:\ -Force
Set-Location -Path C:\nginx-1.9.4
Start-Process nginx
'@

ContainerNginX -StartupScript $script
Start-DscConfiguration .\ContainerNginX -Wait -Verbose -Force
```