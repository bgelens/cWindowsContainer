enum Ensure {
    Absent
    Present
}

enum ContainerType {
    Default
    HyperV
}

[DscResource()]
class cWindowsContainer {
    [DscProperty(Key)]
    [String] $Name

    [DscProperty(Mandatory)]
    [Ensure] $Ensure

    [DscProperty(Mandatory)]
    [String] $ContainerImageName

    [DscProperty()]
    [String] $ContainerImagePublisher

    [DscProperty()]
    [String] $ContainerImageVersion

    [DscProperty()]
    [String] $SwitchName

    [DscProperty()]
    [String] $StartUpScript

    [DscProperty(NotConfigurable)]
    [String] $IPAddress

    [DscProperty(NotConfigurable)]
    [String] $ContainerId

    [DscProperty()]
    [String] $ContainerComputerName

    [DscProperty()]
    [ContainerType] $ContainerType = [ContainerType]::Default

    [void] Set () {
        try {
            if ($this.Ensure -eq [Ensure]::Present) {
                Write-Verbose -Message 'Starting creation of new Container'

                #region start build New-Container parameters
                $ContainerNewParams = [System.Collections.Hashtable]::new()
                $ContainerNewParams.Add('Name',$this.Name)
                $ContainerNewParams.Add('RuntimeType',$this.ContainerType)
                if ($null -ne $this.ContainerComputerName) {
                    $ContainerNewParams.Add('ContainerComputerName',$this.ContainerComputerName)
                }
                #endregion start build New-Container parameters

                #region ContainerImage
                $ContainerImageParams = [System.Collections.Hashtable]::new()
                $ContainerImageParams.Add('Name',$this.ContainerImageName)
                if ($null -ne $this.ContainerImagePublisher) {
                    $ContainerImageParams.Add('Publisher',$this.ContainerImagePublisher)
                }
                if ($null -ne $this.ContainerImageVersion) {
                    $ContainerImageParams.Add('Version',$this.ContainerImageVersion)
                }
                Write-Verbose -Message "Searching for image: $($ContainerImageParams | Out-String)"
                if ($null -eq ($Image = Get-ContainerImage @ContainerImageParams)) {
                    Write-Error -Message "ContainerImage with properties $($ContainerImageParams | Out-String) was not found" -ErrorAction Stop
                } else {
                    $ContainerNewParams.Add('ContainerImage',$Image)
                }
                #endregion ContainerImage

                #region Switch
                Write-Verbose -Message "Searching for specified switch: $($this.SwitchName)"
                if ($this.SwitchName -and ($null -ne (Get-VMSwitch -Name $this.SwitchName))) {
                    Write-Verbose -Message 'Switch was found and will be bound'
                    $ContainerNewParams.Add('SwitchName',$this.SwitchName)
                } elseif ($this.SwitchName -and ($null -eq (Get-VMSwitch -Name $this.SwitchName))) {
                    Write-Error -Message "Switch with name $($this.SwitchName) was not found" -ErrorAction Stop
                }
                #endregion Switch

                #region Create and start Container
                Write-Verbose -Message "Creating Container: $($ContainerNewParams | Out-String)"
                $Container = New-Container @ContainerNewParams
                $Container | Start-Container
                #endregion Create and start Container

                #region run startup script
                if ($null -ne $this.StartUpScript) {
                    Write-Verbose -Message 'Startup Script specified, passing script to InvokeScript method'
                    [void] $this.InvokeScript(([scriptblock]::Create($this.StartUpScript)),$Container.ContainerId)
                }
                #endregion run startup script
            } else {
                Write-Verbose -Message 'Removing Container'
                Get-Container -Name $this.Name | Stop-Container -Passthru | Remove-Container -Force
            }
        } catch {
            Write-Error -ErrorRecord $_ -ErrorAction Stop
        }
    }

    [bool] Test () {
        if ((Get-Container -Name $this.Name -ErrorAction SilentlyContinue) -and ($this.Ensure -eq [Ensure]::Present)) {
            return $true
        } else {
            return $false
        }
    }

    [String] InvokeScript ([String] $Script, [String] $ContainerId) {
        $Output = Invoke-Command -ContainerId $ContainerId -RunAsAdministrator -ScriptBlock ([scriptblock]::Create($Script)) -ErrorAction Stop
        return $Output
    }

    [cWindowsContainer] Get () {
        $Configuration = [System.Collections.Hashtable]::new()
        $Configuration.Add('Name',$this.Name)
        $Configuration.Add('ContainerComputerName',$this.ContainerComputerName)
        $Configuration.Add('ContainerImageName',$this.ContainerImageName)
        $Configuration.Add('ContainerImagePublisher',$this.ContainerImagePublisher)
        $Configuration.Add('ContainerImageVersion',$this.ContainerImageVersion)
        $Configuration.Add('SwitchName',$this.SwitchName)
        $Configuration.Add('StartUpScript',$this.StartUpScript)
        $Configuration.Add('ContainerType',$this.ContainerType)
        if (($this.Ensure -eq [Ensure]::Present) -and ($this.Test())) {
            Write-Verbose -Message 'Acquiring ContainerId'
            $Configuration.Add('ContainerId',(Get-Container -Name $this.Name).ContainerId)
            $Configuration.Add('Ensure','Present')
            Write-Verbose -Message 'Acquiring IPAddress'
            if ($null -ne $this.SwitchName) {
                $Configuration.Add('IPAddress',$this.InvokeScript('(Get-NetIPAddress -AddressFamily IPv4 -PrefixOrigin Manual).IPAddress',$Configuration.ContainerId))
            }
        } else {
            $Configuration.Add('Ensure','Absent')
        }
        return $Configuration
    }
}