Describe "Get-Credential" -Tags "innerloop" {
    It "throws error on a long message" {
        Get-Credential -Message ('a'*2MB) -ErrorVariable credentialError -ErrorAction SilentlyContinue
        $credentialError.FullyQualifiedErrorId | Should be "CouldNotPromptForCredential,Microsoft.PowerShell.Commands.GetCredentialCommand"
    }
}