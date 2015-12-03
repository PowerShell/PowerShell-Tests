<#
 .EXTERNALHELP ClassHelpMod-Help.xml
#>

class ClassHelpClass
{
	[string[]] $myTestField

    [int] $myTestField2

    [void] MyFunc($param1 , [string] $param2, [int] $param3 = 10)
    {
    }

    [int] MyFunc2()
    {
        return 0
    }
}


