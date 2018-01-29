@{
    RootModule = 'r-install'
    ModuleVersion = '0.1'
    GUID = 'aba7cd98-2211-4b00-9595-f10847898e57'
    Author = 'Atif Aziz'
    Copyright = '(c) 2018 Atif Aziz. All rights reserved.'
    Description = 'Functions for installing R and packages for reproducibility'

    # TODO Minimum version of the Windows PowerShell engine required by this module
    # PowerShellVersion = ''

    FunctionsToExport = @(
        'Get-RVersions',
        'Install-R',
        'Install-RPackages'
    )

    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess.
    # This may also contain a PSData hashtable with additional module metadata
    # used by PowerShell.

    PrivateData = @{

        PSData = @{
            Tags = @('R')
            LicenseUri = 'https://opensource.org/licenses/MIT'
            ProjectUri = 'https://github.com/atifaziz/r-install.ps'
            ReleaseNotes = 'https://github.com/atifaziz/r-install.ps/releases'
        }
    }
}
