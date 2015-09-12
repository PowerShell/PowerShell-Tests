
Describe 'Argument transformation attribute on optional argument with explicit $null' {
    $modDefinition = @'
    using System;
    using System.Management.Automation;
    using System.Reflection;

    namespace MSFT_1407291
    {
        [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field, AllowMultiple = false)]
        public class AddressTransformationAttribute : ArgumentTransformationAttribute
        {
            public override object Transform(EngineIntrinsics engineIntrinsics, object inputData)
            {
                return (ulong) 42;
            }
        }

        [Cmdlet(VerbsLifecycle.Invoke, "CSharpCmdletTakesUInt64")]
        [OutputType(typeof(System.String))]
        public class Cmdlet1 : PSCmdlet
        {
            [Parameter(Mandatory = false)]
            [AddressTransformation]
            public ulong Address { get; set; }

            protected override void ProcessRecord()
            {
                WriteObject(Address);
            }
        }

        [Cmdlet(VerbsLifecycle.Invoke, "CSharpCmdletTakesObject")]
        [OutputType(typeof(System.String))]
        public class Cmdlet2 : PSCmdlet
        {
            [Parameter(Mandatory = false)]
            [AddressTransformation]
            public object Address { get; set; }

            protected override void ProcessRecord()
            {
                WriteObject(Address ?? "passed in null");
            }
        }
    }
'@

    $Type = "MSFT_1407291.AddressTransformationAttribute" -as "Type" 
    if ( $Type -eq $null )
    {
        $mod = Add-Type -PassThru -TypeDefinition $modDefinition
        Import-Module $mod[0].Assembly
    }
    else
    {
        import-module $type.Assembly
    }

    function Invoke-ScriptFunctionTakesObject
    {
        param([MSFT_1407291.AddressTransformation()]
              [Parameter(Mandatory = $false)]
              [object]$Address = "passed in null")

        return $Address
    }

    function Invoke-ScriptFunctionTakesUInt64
    {
        param([MSFT_1407291.AddressTransformation()]
              [Parameter(Mandatory = $false)]
              [Uint64]$Address = 11)

        return $Address
    }


    It "Script function that takes has an attribute on an object parameter should take affect" {
        Invoke-ScriptFunctionTakesObject | Should Be 42
    }
    It "Script function that takes has an attribute on an UInt parameter should take affect" {
        Invoke-ScriptFunctionTakesUInt64 | Should Be 42
    }
    It "C# cmdlet that takes has an attribute on an object parameter should take affect" {
    Invoke-CSharpCmdletTakesObject | Should Be "passed in null"
    }
    It "C# cmdlet that takes has an attribute on an uint parameter should take affect" {
        Invoke-CSharpCmdletTakesUInt64 | Should Be 0
    }

    It "Script function that takes has an attribute on a null value object parameter should take affect" {
        Invoke-ScriptFunctionTakesObject -Address $null | Should Be 42
    }
    It "Script function that takes has an attribute on a null value UInt parameter should take affect" {
        Invoke-ScriptFunctionTakesUInt64 -Address $null | Should Be 42
    }
    It "C# cmdlet that takes has an attribute on a null value object parameter should take affect" {
        Invoke-CSharpCmdletTakesObject -Address $null | Should Be 42
    }
    It "C# cmdlet that takes has an attribute on a null value uint parameter should take affect" {
        Invoke-CSharpCmdletTakesUInt64 -Address $null | Should Be 42
    }
}
