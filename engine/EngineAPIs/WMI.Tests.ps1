Describe -tags 'Innerloop', 'DRT' "COM ComplexMethodInvoke" {
    BeforeAll {
        $wmiclass=[WMICLass]"win32_processstartup"

        $ai = $wmiclass.createinstance()
        $ai.ShowWindow = 0
        $ai.X = 0
        $ai.Y = 0
        $wmiclass = [WMICLass]"win32_process"
        $pInfo = $wmiclass.Create("cmd.exe",[Environment]::CurrentDirectory,$ai)

        $tempId = $pInfo.ProcessId
        $result = get-WmiObject -query "select * from win32_process where processid=$tempId"
    }
	It "class name should be win32_process" {
		$wmiclass.Name | Should Be win32_Process
	}

	It "ProcessId should not be null" {
		$pInfo.ProcessId | Should Not BeNullOrEmpty
	}

	It "get-WmiObject -query can find process id" {
		$result.ProcessId | Should be $pInfo.ProcessId
	}

    AfterAll {
        $p= get-process -id $pInfo.ProcessId -ea SilentlyContinue
        if ( $null -ne $null) 
        {
            $p.Kill()
        }
    }
}

Describe -tags 'Innerloop', 'DRT' "DateTimeConversions" {
#    <summary>WMI adapter testcase</summary>
	It "Conversion can round trip" {
        $wmiclass = [wmiclass]"win32_processstartup"
        $currentDate = [DateTime]::Now
        $dmtfDate = $wmiclass.ConvertFromDateTime($currentDate)
        $result  = $wmiclass.ConvertToDateTime($dmtfDate)
		"$currentDate" | Should Be "$result"
	}
}

Describe -tags 'Innerloop', 'DRT' "GetMemberWMI" {
#    <summary>WMI adapter testcase</summary>
    BeforeAll {
        $processes = get-wmiobject win32_process
        $commandFromDotNet = New-Object wmisearcher -ArgumentList "select * from win32_process"
        $commandFromDotNetGet = $commandFromDotNet.get()
        $countMemberFromDotnet = ($commandFromDotNetGet | Get-Member).count
        $countMemberMemberTypeFromDotNet = ($commandFromDotNetGet | Get-Member -MemberType Properties).count
    }

    AfterAll {
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    }

	It "get-wmiobject win32_process should return at least 2 objects" {
		$processes.Count -gt 1 | Should Be $true
	}

	It "win32_process object returns correct number of members" {
        $members = $processes[0] | Get-Member
        $count = $members.Count
		$count | Should Be $countMemberFromDotnet
	}

	It "win32_process object returns correct number of properties" {
        $members = $processes[0] | Get-Member  -membertype properties
        $members.Count | Should Be $countMemberMemberTypeFromDotNet
	}
}
Describe -tags 'Innerloop', 'DRT' "GetRelatedVariations" {
#    <summary>WMI adapter testcase</summary>

    BeforeAll {
        $wmiclass = [wmiclass]"win32_service"
        }

	It "win32_service should return atleast 1 related class" {
        $rClasses = $wmiclass.GetRelatedClasses()
		$rClasses.Count | Should Not Be 0
	}

	It "win32_service should return win32_wmisetting related class" {
        $rClasses = $wmiclass.GetRelatedClasses("Win32_WMISetting")
		$rClasses | Should Not BeNullOrEmpty
	}

	It "exception was thrown when calling GetRelationshipClasses(1,2,3,4,5)" {
        try {
            $wmiclass.GetRelationshipClasses(1,2,3,4,5)
            throw "Execution OK"
        }
        catch {
            $_.FullyQualifiedErrorId | should be "MethodCountCouldNotFindBest"
        }
	}
}
Describe -tags 'Innerloop', 'DRT' "GetWMIQuery" {
#    <summary>WMI adapter testcase</summary>
	It "Query returns at least one result" {
        $wmisearch1 = get-wmiobject -query 'Select * from Win32_process where Name="lsass.exe"'
		$wmisearch1 | Should Not BeNullOrEmpty
	}

	It "Associators of {win32_Service} should return 0 objects" {
        $wmisearch2 = get-wmiobject -query 'Associators of {win32_service}'
		$wmisearch2 | Should BeNullOrEmpty
	}
}
Describe -tags 'Innerloop', 'DRT' "GetWMIType" {
#    <summary>WMI adapter testcase</summary>

	It "GetType() on a [WMIClass] should return a ManagementClass" {
        $wmiclass = [wmiclass]"win32_process"
        $wmiclass.GetType() | Should be ([System.Management.ManagementClass])
	}

	It "[wmi]'win32_process.handle=0' should return management object" {
        $wmiobj = [wmi]"win32_process.Handle=0"
		$wmiobj.getType() | Should Be ([system.management.managementobject])
	}
}
Describe -tags 'Innerloop', 'DRT' "InParameters" {
#    <summary>Accessing InParameters of a Method should not throw exceptions.</summary>
	It "InParameters should not be null" {
        $wmiclass = [WMICLass]"win32_process"
        $method = @($wmiclass.Methods)[0]
        $parameters = $method.InParameters
		$parameters | Should Not BeNullOrEmpty
	}
}
Describe -tags 'Innerloop', 'DRT' "MethodInvokeStringNull" {
#    <summary>WMI adapter testcase</summary>
#  Refer Bug938036 : Invocation of WMI method with $null argument is problematic
    BeforeAll {
        $wmiclass = [WMIClass]"Win32_Process"
        $pInfo1 = $wmiclass.Create("ipconfig.exe",$null,$null)

        $mp=$wmiclass.psbase.GetMethodParameters("Create")
        $mp.CommandLine = "cmd.exe"
        $mp.CurrentDirectory = $null
        $mp.ProcessStartupInformation = $null
        $pInfo2=$wmiclass.psbase.InvokeMethod("Create",$mp,$null)
    }
    AfterAll {
        $p = get-process -id $pInfo1.ProcessId -ea silentlycontinue
        if ( $null -ne $p ) { $p.Kill() }
        $p = get-process -id $pInfo2.ProcessId -ea silentlycontinue
        if ( $null -ne $p ) { $p.Kill() }
    }

	It "WMI Create method call should succeed" {
		$pInfo1.ReturnValue | Should Be 0
	}

	It "ProcessId is not null" {
		$pInfo1.ProcessId | Should Not BeNullOrEmpty
	}

	It "Create method call should succeed" {
		$pInfo2.ReturnValue | Should Be 0
	}
	It "ProcessId is not null" {
		$pInfo2.ProcessId | Should Not BeNullOrEmpty
	}
}
Describe -tags 'Innerloop', 'DRT' "Searcher MethodInvokeWMI" {
#    <summary>WMI adapter testcase</summary>

	It "[WMISearcher] found process from id" {
        $searcher = [WMISearcher]"select * from win32_process where processid=$PID"
        $pInfo = $searcher.Get()
        @($pInfo).Count | should be 1
	}
}

Describe -tags 'Innerloop', 'DRT' "win8_238481" {
#    <summary>Win8: 238481:Name property does not work when pipelined from Get-WMIObject cmdlet.</summary>
    BeforeAll {
        $actual = @(get-WmiObject -list | select -first 1 | % { $_.name } )
        $w32p = get-WmiObject -list win32_process
    }

	It "get-WmiObject -list | select -first 1 | % { $_.name } returns 1 result" {
		$actual.count | Should Be 1
	}

	It "AliasProperty Name is not working for win32_process ManagementClass" {
        $w32p.Name | Should be "win32_process"
	}

	It "Setting a new value for AliasProperty works" {
        $w32p.Name = "blah"
		$w32p.Name | Should Be "blah"
	}
}

Describe -tags 'Innerloop', 'DRT' "WMI" {
#    <summary>WMI adapter testcase</summary>
	It "retrieving single service should return 1 object" {
        $wmi = [WMI]"win32_service.Name='winmgmt'"
		@($wmi).Count | Should Be 1
	}
}

Describe -tags 'Innerloop', 'DRT' "WMIBaseObjectSetProperty" {
#    <summary>Setting property on a ManagementBaseObject object</summary>

    BeforeAll {
        $procClass=[WMICLass]"win32_processstartup"
        $ai = $procClass.createinstance()
        $ai.ShowWindow = 0
        $ai.X = 0
        $ai.Y = 0
        $wmiclass = [wmiclass]"win32_process"
        $wmiMethodParameters = $wmiclass.psbase.GetMethodParameters("Create")
        $wmiMethodParameters.CommandLine = "cmd.exe"
        $wmiMethodParameters.CurrentDirectory = "."
        $wmiMethodParameters.ProcessStartupInformation = $ai
        $pInfoCreate = $wmiclass.psbase.InvokeMethod("Create",$wmiMethodParameters,$null);
        $tempId = $pInfoCreate.ProcessId
        $pInfoObject = get-WmiObject -query "select * from win32_process where processid=$tempId"
    }
    AfterAll {
        $pInfoObject.Terminate() > $null
    }

	It "Win32_Process.PsBase.InvokeMethod() method returned null" {
		$pInfoCreate.ReturnValue | Should Be 0
	}
	It "ProcessId is set" {
		$pInfoCreate.ProcessId | Should Not BeNullOrEmpty
	}

	It "get-WmiObject -query found process via id" {
        $pInfoObject.ProcessId | should be $pInfoCreate.ProcessId
	}
}
Describe -tags 'Innerloop', 'DRT' "WMIClass" {
#    <summary>WMI adapter testcase</summary>
    It "Cast to improper WMIClass fails" {
        try {
            [WMIClass]"non-existent-class"
            throw "Execution OK"
        } catch {
            $_.FullyQualifiedErrorId | Should be "InvalidCastToWMIClass"
        }
    }
}
Describe -tags 'Innerloop', 'DRT' "WMIClassExceptions" {
#    <summary>WMI adapter testcase</summary>
	It "setting non-existent instance property throws" {
        $wmiclass = [wmiclass]"win32_processstartup"
        try {
            $wmiclass.X="10"
            throw "Execution OK"
        } catch {
            $_.FullyQualifiedErrorId | should be "ExceptionWhenSetting"
        }
	}
}
Describe -tags 'Innerloop', 'DRT' "WMIObjectExceptions" {
#    <summary>WMI adapter testcase</summary>

	It "Calling incorrect method from an instance throws correctly" {
        try {
            $wmiobject = [wmisearcher]"select * from win32_process"
            $wmiobject.Create("cmd.exe")
            Throw "Execution OK"
        } catch {
            $_.FullyQualifiedErrorId | should be "MethodNotFound"
        }
	}

	It "Invalid cast throws correctly" {
        try {
            $wmiobject=[wmi]'win32_process.Name="nonexistentprocess"'
            Throw "Execution OK"
        } catch {
            $_.FullyQualifiedErrorId | should be "InvalidCastToWMI"
        }
	}

}
Describe -tags 'Innerloop', 'P1' "WMISearcher" {
#    <summary>WMI adapter testcase</summary>
    BeforeAll {
        $wmiSearcher = [WMISearcher]"Select * from Win32_Process"
        $searchResult = $wmiSearcher.Get()
        $expected = get-process
    }
    It "process count should be approximately the same" {
        $diff = $expected.Count - $searchResult.Count
        [math]::Abs($diff) -lt 5 | should be $true
    }

	It "WMI search should return atleast one result" {
        $system = ([WMISearcher]'Select * from win32_process where Name="System"').Get()
		$system | Should Not BeNullOrEmpty
	}

	It "associators of win32_service should return 0 objects" {
        $wmisearcher = [WMISearcher]'Associators of {win32_service}'
        $wmisearcher.Get().Count | Should be 0
	}

	It "associators of WinMgmt should return at least 1 object." {
        # added a where to reduce time - it still finds associators
        $wmisearcher = [WMISearcher]'Associators of {win32_service="WinMgmt"} WHERE ResultClass=Win32_ComputerSystem'
		$wmisearcher.Get().Count | Should Not Be 0
	}

}
Describe -tags 'Innerloop', 'DRT' "WrongArguments" {
#    <summary>WMI adapter testcase</summary>
    BeforeAll {
        $wmiclass = [WMIClass]"win32_process"
    }
	It "WMIClass.Create() with 5 wrong arguments should throw" {
        try {
            $wmiclass.Create("cmd.exe",1,2,3,4,5)
            Throw "Execution OK"
        } catch {
            $_.FullyQualifiedErrorId | Should be "MethodCountCouldNotFindBest"
        }
	}

	It "Create() with wrong parameter type should throw" {
        try {
            $wmiclass.Create("cmd.exe",1,2)
            Throw "Execution OK"
        } catch {
            $_.FullyQualifiedErrorId | Should Be "CatchFromBaseAdapterMethodInvoke"
        }
    }

	It "Create() with wrong type should not create process" {
        $pInfo = $wmiclass.Create(1)
		$pInfo.ReturnValue | Should Not Be 0
	}
}
