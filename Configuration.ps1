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