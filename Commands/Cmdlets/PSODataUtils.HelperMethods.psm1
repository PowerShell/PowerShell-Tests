<############################################################################################ 
 # File: PSODataUtils.HelperMethods.psm1
 # This file contains helper methods that will be used by Microsoft.PowerShell.ODataUtils Test's.
 #
 ############################################################################################>

 Import-Module Microsoft.PowerShell.ODataUtils -Force -Global
 Include Asserts.psm1

 <############################################################################################ 
 # 
 # Name: GetOutPutDir
 # Description: This is a helper method used to fetch the directory where the Proxy for the
 # server side endpoint would be saved.
 #
 ############################################################################################>
function GetOutPutDir 
{
    return "$pwd\ODataDemoProxy"
}

 <############################################################################################ 
 # 
 # Name: GetEndPointUri
 # Description: This is a helper method used to fetch the URI of the server side OData endpoint
 #
 ############################################################################################>
function GetEndPointUri 
{
    return "http://services.odata.org/V3/(S(fhleiief23wrm5a5nhf542q5))/OData/OData.svc/"
}

 <############################################################################################ 
 # 
 # Name: HelperMethodToValidateProxyCreation
 # Description: This is a helper method generate the proxy for the server side OData endpoint
 #
 ############################################################################################>
function HelperMethodToValidateProxyCreation {

    param 
    (
        [string] $metadataUri
    )

    try
    {
        $outputDir = GetOutPutDir
        $endPointUri = GetEndPointUri
        if($null -ne $metadataUri -and $metadataUri -ne [string]::Empty)
        {
            Log -Message "MetaDataUri: $($metadataUri)."
            Export-ODataEndpointProxy -Uri $endPointUri -OutputModule $outputDir -MetadataUri $metaDataUri -Verbose -AllowUnsecureConnection -Force -AllowClobber
        }
        else
        {
            Export-ODataEndpointProxy -Uri $endPointUri -OutputModule $outputDir -Verbose -AllowUnsecureConnection -Force -AllowClobber
        }
    }
    catch
    {
        $fullyQualifiedErrorId  = $_.FullyQualifiedErrorId 
        Assert ($false) "Failed to generate Powershell cmdlets for the $endPointUri. The FullyQualifiedErrorId is $fullyQualifiedErrorId"
    }
    finally
    {
        Remove-Item "$outputDir" -Force -Recurse -ErrorAction SilentlyContinue
    }
}


# Test class used to validate Type conversion using 
# ConvertTo() and ConvertPSObjectToType() from PS object 
# when default constructor does not exist. 
class SampleClass
{
  SampleClass([int] $i) { }
  [int]$Id; 
  [string]$Name;
}

# Test class used to validate Type conversion using 
# ConvertTo() and ConvertPSObjectToType() from PS object 
# when default constructor exists. 
class SampleClass1
{
  [int]$Id; 
  [string]$Name;
  [int]$sp;
}

function ConvertPSObjectToTypeWithOutDefaultConstructor 
{
    $p = New-Object psobject -Property @{"Id"=1;"Name"="Some user Name"}

    try
    {
        # Try the same conversion using type casting which uses ConverTo() API
        [SampleClass]$p
        Assert ($false) "Failed to successfully detect that 'SampleClass' does not have a default constructor. Hence the type conversion may not be going through ConvertViaNoArgumentConstructor."
    }
    catch
    {
        if($null -eq $_ -or $null -eq $_.FullyQualifiedErrorId -or $_.FullyQualifiedErrorId -ne "ConvertToFinalInvalidCastException")
        {
            $fullyQualifiedErrorId  = $_.FullyQualifiedErrorId 
            Assert ($false) "Failed to successfully detect that 'SampleClass' does not have a default constructor. Hence the type conversion may not be going through ConvertViaNoArgumentConstructor."
        }
    }

    try
    {
        # Now Try the same conversion using ConvertPSObjectToType API
        [System.Management.Automation.LanguagePrimitives]::ConvertPSObjectToType($p, [SampleClass], $true, [cultureinfo]::InvariantCulture, $false)
        Assert ($false) "Failed to successfully detect that 'SampleClass' does not have a default constructor. Hence the type conversion may not be going through ConvertViaNoArgumentConstructor."
    }
    catch
    {
        if($null -eq $_ -or $null -eq $_.FullyQualifiedErrorId -or $_.FullyQualifiedErrorId -ne "ArgumentException")
        {
            $fullyQualifiedErrorId  = $_.FullyQualifiedErrorId 
            Assert ($false) "Failed to successfully detect that 'SampleClass' does not have a default constructor. Hence the type conversion may not be going through ConvertViaNoArgumentConstructor."
        }
    }
}

function ConvertPSObjectToTypeWithDefaultConstructor 
{
    try
    {
        $p = New-Object psobject -Property @{"Id"=1;"Name"="Some user Name"; "sp"=2}
        $a = [SampleClass1]$p

        Assert ($a -ne $null -and $a.GetType().ToString() -eq 'SampleClass1') "Failed to successfully type cast PSObject to Type 'SampleClass1'."
        Assert ($a.Id -eq 1 -and $a.Name -eq 'Some user Name' -and $a.sp -eq 2) "Failed to successfully type cast PSObject to Type 'SampleClass1'."
    }
    catch
    {
        $fullyQualifiedErrorId  = $_.FullyQualifiedErrorId
        Assert ($false) "Failed to successfully type cast PSObject to Type 'SampleClass1'. FullyQualifiedErrorId is $fullyQualifiedErrorId"
    }
}


# Common function to generate cmdlets for NetworkControllerAdapter
function GenerateNetworkControllerCmdlet
{
    $endPointUri = GetEndPointUri
    $metaDataUri = GetNetworkControllerMetadataUri
    $outputDir = GetOutPutDir
    $resourceNameMapping = @{Microsoft_Windows_Networking_NetworkController_Framework_NbContracts_Credential="NetworkControllerCredential"}
    $customData = @{Microsoft_Windows_Networking_NetworkController_Framework_NbContracts_Credential="/networking/v1/credentials/[ResourceId]"}

    Export-ODataEndpointProxy -Uri $endPointUri -MetadataUri $metaDataUri -OutputModule $outputDir -CmdletAdapter NetworkControllerAdapter -ResourceNameMapping $resourceNameMapping -CustomData $customData -Force -AllowUnsecureConnection -CreateRequestMethod "Put" -UpdateRequestMethod "Put"
}

# Common function to fetch NetworkController metadata file
function GetNetworkControllerMetadataUri
{
    return "$pwd\NCMetadata.xml"   
}

# Helper method to validate output of NetworkControllerAdapter
# This method validates that parameters specific to 
# NetworkControllerAdapter are present in the output directory.
function ValidateNetworkControllerExecution
{
    try
    {
        $outputDir = GetOutPutDir
        $credFilePath = "$outputDir\NetworkControllerCredential.cdxml"

        # Validate that Credential cmdlet is generated while Device cmdlet is not
        $credGenerated = Test-Path -Path $credFilePath
        $deviceGenerated = Test-Path -Path "$outputDir\NetworkControllerDevice.cdxml"
        Assert ($credGenerated -eq $true) "Failed to generate NetworkControllerAdapter cmdlet"
        Assert ($deviceGenerated -eq $false) "Cmdlet generated for parameter not present in CustomData"

        # Validate the NetworkControllerCredential cdxml file
        $fileContent = Get-Content -Path $credFilePath
        [xml] $cdxmlContent = $fileContent

        # Validate that Set cmdlet isn't generated
        $staticCmdlets = $cdxmlContent.PowerShellMetadata.Class.StaticCmdlets.ChildNodes
        Assert ($staticCmdlets.Count -eq 2) "Static cmdlets count isn't 2"
        $setCmdlet = $staticCmdlets | Where-Object {$_.CmdletMetadata.Verb -eq "Set"}
        Assert ($setCmdlet -eq $null) "Set cmdlet generated for NetworkControllerAdapter"

        # Validate that VersionId is a parameter for both New and Remove cmdlet
        $staticCmdlets | ForEach-Object {
            $versionIdParam = $_.Method.Parameters.ChildNodes | Where-Object {$_.CmdletParameterMetadata.PSName -eq "VersionId"}
            Assert ($versionIdParam -ne $null) "VersionId not generated for static cmdlet"
        }

        # Validate PrivateData
        $privateData = $cdxmlContent.PowerShellMetadata.Class.CmdletAdapterPrivateData
        $customUriSuffix = $privateData.ChildNodes | Where-Object {$_.Name -eq "CustomUriSuffix"}
        $createRequestMethod = $privateData.ChildNodes | Where-Object {$_.Name -eq "CreateRequestMethod"}
        $updateRequestMethod = $privateData.ChildNodes | Where-Object {$_.Name -eq "UpdateRequestMethod"}
        Assert ($customUriSuffix -ne $null) "CustomUriSuffix not found in PrivateData"
        Assert ($createRequestMethod -ne $null) "CreateRequestMethod not found in PrivateData"
        Assert ($updateRequestMethod -ne $null) "UpdateRequestMethod not found in PrivateData"
    }
    catch
    {
        $fullyQualifiedErrorId = $_.FullyQualifiedErrorId
        Assert ($false) "Failed to validate cmdlet output for NetworkControllerAdapter"
    }
}

# Helper method to validate RequestMethod in generated cdxml
function ValidateRequestMethod
{
    try
    {
        $outputDir = GetOutPutDir
        $credFilePath = "$outputDir\NetworkControllerCredential.cdxml"

        # Validate that Credential cmdlet is generated
        $credGenerated = Test-Path -Path $credFilePath
        Assert ($credGenerated -eq $true) "Failed to generate NetworkControllerAdapter cmdlet"

        # Validate the NetworkControllerCredential cdxml file
        $fileContent = Get-Content -Path $credFilePath
        [xml] $cdxmlContent = $fileContent

        # Validate PrivateData
        $privateData = $cdxmlContent.PowerShellMetadata.Class.CmdletAdapterPrivateData
        $createRequestMethod = $privateData.ChildNodes | Where-Object {$_.Name -eq "CreateRequestMethod"}
        $updateRequestMethod = $privateData.ChildNodes | Where-Object {$_.Name -eq "UpdateRequestMethod"}
        Assert ($createRequestMethod -ne $null -And $createRequestMethod.'#text' -eq 'Put') "CreateRequestMethod not configured properly in PrivateData"
        Assert ($updateRequestMethod -ne $null -And $updateRequestMethod.'#text' -eq 'Put') "UpdateRequestMethod not configured properly in PrivateData"
    }
    catch
    {
        $fullyQualifiedErrorId = $_.FullyQualifiedErrorId
        Assert ($false) "Failed to validate cmdlet output for NetworkControllerAdapter"
    }
}

# Helper method to validate parameters of NetworkControllerAdapter
# This method validates that parameters specific to 
# NetworkControllerAdapter are present in the generated cdxml
function ValidateNetworkControllerParameters
{
    try
    {
        $outputDir = GetOutPutDir
        $credFilePath = "$outputDir\NetworkControllerCredential.cdxml"

        # Validate that Credential cmdlet is generated
        $credGenerated = Test-Path -Path $credFilePath
        Assert ($credGenerated -eq $true) "Failed to generate NetworkControllerAdapter cmdlet"

        # Validate the NetworkControllerCredential cdxml file
        $fileContent = Get-Content -Path $credFilePath
        [xml] $cdxmlContent = $fileContent

        # Validate the Get cmdlet params
        $instanceCmdlet = $cdxmlContent.PowerShellMetadata.Class.InstanceCmdlets
        Assert ($instanceCmdlet -ne $null) "Instance cmdlet not generated"
        $paramsNode = $instanceCmdlet.ChildNodes | Where-Object {$_.Name -eq "GetCmdletParameters"}
        $propertyNodes = $paramsNode.QueryableProperties.ChildNodes | Where-Object {$_.Name -eq "Property"}
        Assert ($propertyNodes.Count -eq $null) "Parameter count mismatch for Get cmdlet"
        Assert($propertyNodes.PropertyName -eq "ResourceId" -And $propertyNodes.Type.PSType -eq "String") "Validation failed for parameter ResourceId in Get cmdlet"

        # Validate that New cmdlet params
        $staticCmdlets = $cdxmlContent.PowerShellMetadata.Class.StaticCmdlets.ChildNodes
        Assert ($staticCmdlets.Count -eq 2) "Static cmdlets count isn't 2"
        $newCmdlet = $staticCmdlets | Where-Object {$_.CmdletMetadata.Verb -eq "New"}
        Assert ($newCmdlet -ne $null) "New cmdlet not generated for NetworkControllerAdapter"
        $propertiesParam = $newCmdlet.Method.Parameters.ChildNodes | Where-Object {$_.ParameterName -eq "Properties"}
        Assert ($propertiesParam -ne $null -And $propertiesParam.Type.PSType -eq "Microsoft.Windows.NetworkController.CredentialProperties") "Validation failed for param Properties in New cmdlet"
        Assert ($propertiesParam -ne $null -And $propertiesParam.CmdletParameterMetadata.IsMandatory -eq "true") "Properties parameter isn't mandatory for New cmdlet"
    }
    catch
    {
        $fullyQualifiedErrorId = $_.FullyQualifiedErrorId
        Assert ($false) "Failed to validate cmdlet output for NetworkControllerAdapter"
    }
}

