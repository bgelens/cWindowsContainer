configuration NewContainer {
    Import-DscResource -ModuleName cWindowsContainer

    cWindowsContainer MyAppContainer {
        Ensure = 'Present'
        Name = 'MyAppContainer'
        StartUpScript = '"Hello World" | out-file c:\hello.txt'
    }
}
NewContainer
Start-DscConfiguration .\NewContainer -Wait -Verbose

configuration MultiLineConfigContainer {
    param (
        [String] $StartupScript
    )
    Import-DscResource -ModuleName cWindowsContainer

    cWindowsContainer MyDCContainer {
        Ensure = 'Present'
        Name = 'MyDCContainer'
        StartUpScript = $StartupScript
    }
}

$script = @'
$computername = $env:COMPUTERNAME
$computername.tolower() | out-file c:\compname.txt
'@

MultiLineConfigContainer -StartupScript $script
Start-DscConfiguration .\MultiLineConfigContainer -Wait -Verbose


configuration RemContainer {
    Import-DscResource -ModuleName cWindowsContainer

    cWindowsContainer MyAppContainer {
        Ensure = 'Absent'
        Name = 'MyAppContainer'
    }
}
RemContainer
Start-DscConfiguration .\RemContainer -Wait -Verbose

configuration ContainerNginX {
    param (
        [String] $StartupScript
    )
    Import-DscResource -ModuleName cWindowsContainer

    cWindowsContainer NginX {
        Ensure = 'Present'
        Name = 'NginX'
        StartUpScript = $StartupScript
        SwitchName = 'Virtual Switch'
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