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

    [DscProperty(NotConfigurable)]
    [String] $IPAddress

    [DscProperty(NotConfigurable)]
    [String] $ContainerId

    [void] Set () {
        $ErrorActionPreference = 'Stop'
        try {
            if ($this.Ensure -eq [Ensure]::Present) {
                Write-Verbose -Message 'Creating Container';
                if ($null -eq ($Image = Get-ContainerImage -Name $this.ContainerImage)) {
                    Write-Error -Message "ContainerImage with name $($this.ContainerImage) was not found";
                }

                $Params = @{
                    Name = $this.Name;
                    ContainerImage = $Image;
                }
                if ($this.SwitchName -and ($null -ne (Get-VMSwitch -Name $this.SwitchName))) {
                    Write-Verbose -Message 'VMSwitch was found and will be bound';
                    $Params += @{
                        SwitchName = $this.SwitchName;
                    }
                } elseif ($this.SwitchName -and ($null -eq (Get-VMSwitch -Name $this.SwitchName))) {
                    Write-Error -Message "VMSwitch with name $($this.SwitchName) was not found";
                }
                $Container = New-Container @Params;
                $Container | Start-Container | Out-Null;
            
                if ($null -ne $this.StartUpScript) {
                    Write-Verbose -Message 'Startup Script specified, passing script to InvokeScript method'
                    [void] $this.InvokeScript(([scriptblock]::Create($this.StartUpScript)),$Container.ContainerId);
                }
            } else {
                Write-Verbose -Message 'Removing Container';
                Get-Container -Name $this.Name | Stop-Container -Passthru | Remove-Container -Force | Out-Null;
            }
        } catch {
            Write-Error -ErrorRecord $_ -ErrorAction Stop;
        }
    }

    [bool] Test () {
        if ((Get-Container -Name $this.Name -ErrorAction SilentlyContinue) -and ($this.Ensure -eq [Ensure]::Present)) {
            return $true;
        } else {
            return $false;
        }
    }

    [String] InvokeScript ([String] $Script, [String] $ContainerId) {
        $Output = Invoke-Command -ContainerId $ContainerId -RunAsAdministrator -ScriptBlock ([scriptblock]::Create($Script)) -ErrorAction SilentlyContinue;
        return $Output;
    }

    [cWindowsContainer] Get () {
        $Configuration = [hashtable]::new();
        $Configuration.Add('Name',$this.Name);
        $Configuration.Add('ContainerImage',$this.ContainerImage);
        $Configuration.Add('SwitchName',$this.SwitchName);
        $Configuration.Add('StartUpScript',$this.StartUpScript);
        if (($this.Ensure -eq [Ensure]::Present) -and ($this.Test())) {
            Write-Verbose -Message 'Acquiring ContainerId';
            $Configuration.Add('ContainerId',(Get-Container -Name $this.Name).ContainerId);
            $Configuration.Add('Ensure','Present');
            Write-Verbose -Message 'Acquiring IPAddress';
            $Configuration.Add('IPAddress',$this.InvokeScript('(Get-NetIPAddress -AddressFamily IPv4 -PrefixOrigin Manual).IPAddress',$Configuration.ContainerId));
        } else {
            $Configuration.Add('Ensure','Absent');
        }
        return $Configuration;
    }
}