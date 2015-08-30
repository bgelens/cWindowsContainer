enum Ensure {
   Absent;
   Present;
}

[DscResource()]
class cWindowsContainer {
    [DscProperty(Key)]
    [String] $Name

    [DscProperty(Mandatory)]
    [Ensure] $Ensure

    [DscProperty()]
    [String] $ContainerImage = 'WindowsServerCore'

    [DscProperty()]
    [String] $SwitchName

    [DscProperty()]
    [String] $StartUpScript

    [void] Set () {
        if ($this.Ensure -eq [Ensure]::Present) {
            if ($null -eq ($Image = Get-ContainerImage -Name $this.ContainerImage)) {
                $Image = Get-ContainerImage | Select-Object -First 1
            }

            $Params = @{
                Name = $this.Name;
                ContainerImage = $Image;
            }
            if ($this.SwitchName -and ($null -ne (Get-VMSwitch -Name $this.SwitchName))) {
                $Params += @{
                    SwitchName = $this.SwitchName;
                }
            }
            $Container = New-Container @Params;
            $Container | Start-Container | Out-Null;
            
            if ($null -ne $this.StartUpScript) {
                Invoke-Command -ContainerId $Container.ContainerId -RunAsAdministrator -ScriptBlock ([scriptblock]::Create($this.StartUpScript)) | Out-Null
            } 
        } else {
            Get-Container -Name $this.Name | Stop-Container -Passthru | Remove-Container -Force | Out-Null;
        }
    }

    [bool] Test () {
        if ((Get-Container -Name $this.Name -ErrorAction SilentlyContinue) -and ($this.Ensure -eq [Ensure]::Present)) {
            return $true;
        } else {
            return $false;
        }
    }

    [cWindowsContainer] Get () {
        $Configuration = [hashtable]::new()
        $Configuration.Add('Name',$this.Name)
        $Configuration.Add('ContainerImage',$this.ContainerImage)
        $Configuration.Add('SwitchName',$this.SwitchName)
        $Configuration.Add('StartUpScript',$this.StartUpScript)
        if (($this.Ensure -eq [Ensure]::Present) -and ($this.Test())) {
            $Configuration.Add('Ensure','Present')
        }
        else {
            $Configuration.Add('Ensure','Absent')
        }
        return $Configuration
    }
}