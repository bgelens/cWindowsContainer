cWindowsContainer
=================

Class Based DSC resource to deploy Windows Containers with.

```powershell
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


configuration RemContainer {
    Import-DscResource -ModuleName cWindowsContainer

    cWindowsContainer MyAppContainer {
        Ensure = 'Absent'
        Name = 'MyAppContainer'
    }
}
RemContainer
Start-DscConfiguration .\RemContainer -Wait -Verbose
```