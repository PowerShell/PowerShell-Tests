#
# Tests for PowerShell Remoting Cmdlets with regards to WSMan No-Reboot feature
# 2015
#

function Get-PluginDetails([string]$name = $(throw "Endpoint name not provided.")) 
{
	function Unescape-Xml($s) {
		if ($s) {
			$s = $s.Replace("&lt;", "<");
			$s = $s.Replace("&gt;", ">");
			$s = $s.Replace("&quot;", '"');
			$s = $s.Replace("&quot;", '"');
			$s = $s.Replace("&apos;", "'");
			$s = $s.Replace("&amp;", "&");
		}
		
		return $s;
	}

	$hashprovider = new-object system.collections.CaseInsensitiveHashCodeProvider
	$comparer=new-object system.collections.CaseInsensitiveComparer
	$h = new-object system.collections.hashtable([System.Collections.IHashCodeProvider]$hashprovider, [System.Collections.IComparer]$comparer)
	$wfendpoint = $false
	
	if (test-path wsman:\localhost\plugin\"$name") {
		function Get-Details([string]$path, [hashtable]$h) {
			 foreach ($o in (get-childitem $path)) {
				if ($o.PSIsContainer) {
					Get-Details $o.PSPath $h
				} else {
					$h[$o.Name] = $o.Value
				}
			}
		}
		
		Get-Details wsman:\localhost\plugin\""$name"" $h
		
		$sddl = $h["Sddl"]
		if ($sddl) {
			$h.Remove("Sddl")
			$h["SecurityDescriptorSddl"] = $sddl
		}

		if ($h["PSSessionConfigurationTypeName"] -eq "Microsoft.PowerShell.Workflow.PSWorkflowSessionConfiguration") {
			import-module psworkflow -Scope local
			$wf = new-psworkflowexecutionoption

			foreach ($o in $wf.GetType().GetProperties()) {
				$h[$o.Name] = $o.GetValue($wf, $null)
			}
		}

		if (test-path wsman:\localhost\plugin\"$name"\InitializationParameters\SessionConfigurationData) {
			$xscd = [xml](Unescape-Xml (Unescape-Xml (get-item wsman:\localhost\plugin\"$name"\InitializationParameters\SessionConfigurationData).Value))

			foreach ($o in $xscd.SessionConfigurationData.Param) {
				if ($o.Name -eq "PrivateData") {
					foreach($wf in $o.PrivateData.Param) {
						$h[$wf.Name] = $wf.Value
					}
				} else {
					$h[$o.Name] = $o.Value
				}
			}
		}
	}

	return $h 
}

Describe "Remoting Cmdlets WinRM Noreboot Tests" {

    BeforeAll {
        $testName = 'abc'
        $checkRebootSession = $null
        $sc = 'SilentlyContinue'

        if ((Get-Service -Name 'WinRM').Status -ne 'Running'){ Start-Service -Name 'WinRM' }
        Unregister-PSSessionConfiguration -Name abc -Force -ErrorAction $sc

        function Restart-WinRM
        {
            # This removes all of the output to the screen
            Restart-Service -Name WinRM -Force -Confirm:$false 3>$null
        }

    }
    
    Context "Register-PSSessionConfiguration" {
        BeforeEach{
            Restart-WinRM
            $checkRebootSession = New-PSSession -ComputerName localhost
            $checkRebootSession.State | Should be 'Opened'
        }

        AfterEach{                         
            Remove-PSSession $checkRebootSession -Confirm:$false
            Unregister-PSSessionConfiguration -Name abc -Force -ErrorAction $sc
        }

        It "Registering without a reboot" {
            
            $checkRebootSession.State | Should be 'Opened'
            $c = Register-PSSessionConfiguration -Name $testName -WarningAction $sc -WarningVariable $null
            $checkRebootSession.State | Should be 'Opened'

            $h = Get-PluginDetails $testName
            $h["Enabled"] | Should Be "True"
        }

        It "Registering without a reboot with -Force" {
            
            $checkRebootSession.State | Should be 'Opened'
            $c = Register-PSSessionConfiguration -Force -Name $testName -WarningAction $sc -WarningVariable $null
            $checkRebootSession.State | Should be 'Opened'

            $h = Get-PluginDetails $testName
            $h["Enabled"] | Should Be "True"
        }

        It "Error on re-register" {
            
            $checkRebootSession.State | Should be 'Opened'
            $c = Register-PSSessionConfiguration -Name $testName -WarningAction $sc -WarningVariable $null
            $checkRebootSession.State | Should be 'Opened'

            #now should fail while still not rebooting
            { Register-PSSessionConfiguration -Name $testName -WarningAction $sc -WarningVariable $null } | Should Throw

            $checkRebootSession.State | Should be 'Opened'
        }

        It "Re-register with -Force should reboot and work" {
            
            # first instance of register does not require a reboot
            $checkRebootSession.State | Should be 'Opened'
            $c = Register-PSSessionConfiguration -Name $testName -WarningAction $sc -WarningVariable $null -Force
            $checkRebootSession.State | Should be 'Opened'

            Unregister-PSSessionConfiguration -Name $testName -WarningAction $sc -WarningVariable $null

            # Now reboot of WinRM is required with -Force, the cmdlet should reboot WinRM for us
            { Register-PSSessionConfiguration -Name $testName -Force 3>$null } | Should not Throw

            $checkRebootSession.State | Should not be 'Opened'

            $newTestSession = New-PSSession -ComputerName localhost -ConfigurationName $testName
            $newTestSession.State | Should be 'Opened'
            Remove-PSSession $newTestSession -Confirm:$false
        }

        It "Re-register WITHOUT -Force should not reboot and session won't work" {
            
            # first instance of register does not require a reboot
            $checkRebootSession.State | Should be 'Opened'
            $c = Register-PSSessionConfiguration -Name $testName -WarningAction $sc -WarningVariable $null
            $checkRebootSession.State | Should be 'Opened'

            Unregister-PSSessionConfiguration -Name $testName -WarningAction $sc -WarningVariable $null

            # Now reboot of WinRM is required with -Force, the cmdlet should reboot WinRM for us
            { Register-PSSessionConfiguration -Name $testName -WarningAction $sc -WarningVariable $null } | Should not Throw

            $checkRebootSession.State | Should be 'Opened'

            { $newTestSession = New-PSSession -ComputerName localhost -ConfigurationName $testName -ErrorAction Stop } | Should Throw
            $newTestSession.State | Should not be 'Opened'
        }
    }

    Context "Unregister-PSSessionConfiguration" {
        BeforeEach{
            Restart-WinRM
            $checkRebootSession = New-PSSession -ComputerName localhost
            $checkRebootSession.State | Should be 'Opened'
        }

        AfterEach{                         
            Remove-PSSession $checkRebootSession -Confirm:$false
            Unregister-PSSessionConfiguration -Name abc -Force -ErrorAction $sc
        }

        It "Unregistering without a reboot" {
            
            Register-PSSessionConfiguration -Name $testName -WarningAction $sc -WarningVariable $null

            $checkRebootSession.State | Should be 'Opened'
            Unregister-PSSessionConfiguration -Name $testName -WarningAction $sc -WarningVariable $null
            $checkRebootSession.State | Should be 'Opened'
        }

        It "Unregistering without a reboot with -Force" {
            
            Register-PSSessionConfiguration -Name $testName -WarningAction $sc -WarningVariable $null

            $checkRebootSession.State | Should be 'Opened'
            Unregister-PSSessionConfiguration -Force -Name $testName -WarningAction $sc -WarningVariable $null
            $checkRebootSession.State | Should be 'Opened'
        }

        It "Error on Unregistering a non-existing plugin" {
            
            $checkRebootSession.State | Should be 'Opened'
            { Unregister-PSSessionConfiguration -Name $testName -WarningAction $sc -WarningVariable $null -ErrorAction Stop } | Should Throw
            $checkRebootSession.State | Should be 'Opened'
        }
    }

    Context "Disable-PSSessionConfiguration" {
        BeforeEach{
            Restart-WinRM
            $checkRebootSession = New-PSSession -ComputerName localhost
            $checkRebootSession.State | Should be 'Opened'
        }

        AfterEach{                         
            Remove-PSSession $checkRebootSession -Confirm:$false
            Unregister-PSSessionConfiguration -Name abc -Force -ErrorAction $sc
        }

        It "Disabling without a reboot" {
            
            Register-PSSessionConfiguration -Name $testName -WarningAction $sc -WarningVariable $null

            $checkRebootSession.State | Should be 'Opened'
            Disable-PSSessionConfiguration -Name $testName -WarningAction $sc -WarningVariable $null
            $checkRebootSession.State | Should be 'Opened'

            $h = Get-PluginDetails $testName
            $h["Enabled"] | Should Be "False"
        }

        It "Disabling without a reboot with -Force" {
            
            Register-PSSessionConfiguration -Name $testName -WarningAction $sc -WarningVariable $null

            $checkRebootSession.State | Should be 'Opened'
            Disable-PSSessionConfiguration -Force -Name $testName -WarningAction $sc -WarningVariable $null
            $checkRebootSession.State | Should be 'Opened'

            $h = Get-PluginDetails $testName
            $h["Enabled"] | Should Be "False"
        }
    }

    Context "Enable-PSSessionConfiguration" {
        BeforeEach{
            Restart-WinRM
            $checkRebootSession = New-PSSession -ComputerName localhost
            $checkRebootSession.State | Should be 'Opened'
        }

        AfterEach{                         
            Remove-PSSession $checkRebootSession -Confirm:$false
            Unregister-PSSessionConfiguration -Name abc -Force -ErrorAction $sc
        }

        It "Enabling without a reboot" {
            # Ensure session configuration commands work in strict mode
            Set-StrictMode -Version 5.0
            
            Register-PSSessionConfiguration -Name $testName -WarningAction $sc -WarningVariable $null

            $checkRebootSession.State | Should be 'Opened'
            Enable-PSSessionConfiguration -Name $testName -WarningAction $sc -WarningVariable $null
            $checkRebootSession.State | Should be 'Opened'

            $h = Get-PluginDetails $testName
            $h["Enabled"] | Should Be "True"
        }

        It "Enabling without a reboot with -Force" {
            # Ensure session configuration commands work in strict mode
            Set-StrictMode -Version 5.0

            Register-PSSessionConfiguration -Name $testName -WarningAction $sc -WarningVariable $null

            $checkRebootSession.State | Should be 'Opened'
            Enable-PSSessionConfiguration -Force -Name $testName -WarningAction $sc -WarningVariable $null
            $checkRebootSession.State | Should be 'Opened'

            $h = Get-PluginDetails $testName
            $h["Enabled"] | Should Be "True"
        }
    }
}



