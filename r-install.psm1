<#
MIT License

Copyright (c) 2018 Atif Aziz

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

# https://github.com/PowerShell/PSScriptAnalyzer#suppressing-rules
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingCmdletAliases", "", Scope="Function", Target="*")]
param()
function Get-RVersions
{
    [CmdletBinding()]
    param()

    (Invoke-WebRequest https://rversions.r-pkg.org/r-versions).Content |
        ConvertFrom-Json |
        % { $_ } |
        select @{ Name = 'Version'; Expression = { $_.version } },
               @{ Name = 'Date'   ; Expression = { [DateTimeOffset]$_.date } }
}

Function Install-R
{
    [CmdletBinding()]
    Param(
        [Version] $Version,
        [Uri]     $CRAN = 'https://cloud.r-project.org/',
        [string]  $InstallRoot,
        [string]  $InstallPath,
        [string]  $DownloadRoot,
        [switch]  $Local,
        [switch]  $SkipProxyScripts)

    # With some inspiration from:
    # https://github.com/krlmlr/r-appveyor

    $ErrorActionPreference = 'Stop'

    if ($local)
    {
        $installPath = Join-Path ([string](pwd)) '.R'
        $installRoot = $installPath
        Write-Verbose "Local installation means R will be installed to `"$installPath`"."
    }

    if (-not $installRoot) {
        $installRoot = Join-Path $env:LOCALAPPDATA R
    }

    if (-not $downloadRoot) {
        $downloadRoot = Join-Path $env:TEMP R
    }

    if (-not $version)
    {
        $rversionFile = 'rversion.txt'
        Write-Verbose "No version specified so checking for local version specification file ($rversionFile)..."
        if (Test-Path -PathType Leaf $rversionFile)
        {
            $version = [Version](type $rversionFile | ? { $_ -match '\b[0-9](\.[0-9]){1,3}\b' } | select -First 1 | % { $matches[0] })
            Write-Verbose "Local version file ($rversionFile) says to use R $version."
        }
        else
        {
            Write-Verbose "No local version file found so determining latest R version..."
            $version = [Version](ConvertFrom-JSON (Invoke-WebRequest http://rversions.r-pkg.org/r-release-win).Content).version
        }
    }

    Write-Verbose "Processing installation request for R $version..."

    if (-not $installPath) {
        $installPath = Join-Path $installRoot "R-$version"
    }

    $isInstalled = $false

    $rBinPath    = Join-Path $installPath bin
    $rPath       = Join-Path $rBinPath R.exe
    $rScriptPath = Join-Path $rBinPath Rscript.exe

    if (Test-Path -PathType Leaf $rScriptPath)
    {
        Write-Verbose "R appears to be installed at `"$installPath`"."
        Write-Verbose "Running `"$rscriptPath`" with `"--version`" flag to determine version match."

        $testVersionText = & cmd '/c', $rScriptPath, '--version', '2>&1'

        if ($LASTEXITCODE) {
            Write-Error "Failed to determine version of R. Exit code was $LASTEXITCODE."
        }

        if ($testVersionText -match '\b[0-9](\.[0-9]){1,3}\b')
        {
            $testVersion = [Version]$matches[0]
            Write-Verbose "Installed version of R is $testVersion."
            $isInstalled = $testVersion -eq $version

            if ($local -and $testVersion -ne $version)
            {
                Write-Error (
                    "Local R version mismatch! Installed version of R is $testVersion but requested version is $version. " +
                    "Uninstall current version (e.g. run `"$(Join-Path $installPath unins000)`") before using another.")
            }
        }
        else
        {
            Write-Error "Installed R version could not be determined. Abort!"
        }
    }
    else
    {
        Write-Verbose "R $version does not appear to be installed. It will be installed now."
    }

    if ($isInstalled)
    {
        Write-Verbose "R $version is already installed so download and installation will be skipped."
    }
    else
    {
        $downloadTempPath = Join-Path $env:TEMP 'R-win.exe'
        $installerPath = [IO.Path]::Combine($downloadRoot, $version, 'R-win.exe')

        if (-not (Test-Path -PathType Leaf $installerPath))
        {
            md (Split-Path $installerPath) -Force | Out-Null
            $url = New-Object System.Uri $cran, "/bin/windows/base/R-$version-win.exe"
            Write-Verbose "Downloading R $version from $url to `"$installerPath`"..."
            Invoke-WebRequest $url -OutFile $downloadTempPath
            move $downloadTempPath $installerPath
        }
        else
        {
            Write-Verbose "R $version installer appears to have been already downloaded to `"$installerPath`"."
        }

        Write-Verbose "Running R installer..."

        $process = start -PassThru $installerPath @('/VERYSILENT', "/DIR=$installPath")
        try
        {
            Write-Verbose "R installer started (PID = $($process.Id)) and waiting for it to finish..."
            $process.WaitForExit()
            $installerExitCode = $process.ExitCode
        }
        finally
        {
            $process.Dispose()
        }

        Write-Verbose "R $version installer finished with an exit code of $installerExitCode."

        if ($installerExitCode -eq 0)
        {
            Write-Verbose "R $version appears to have installed successfully."
            Write-Verbose "To uninstall, run `"$(Join-Path $installPath unins000)`"."
        }
        else
        {
            Write-Error "R $version installer failed due to non-zero exit code ($installerExitCode)."
            return
        }
    }

    Write-Verbose "Testing R $version installation..."

    & $rScriptPath -e 'sessionInfo()'

    if ($LASTEXITCODE) {
        Write-Error "Test R $version installation failed."
    }

    Write-Verbose "Generating proxy scripts for R and RScript."

    if (-not $skipProxyScripts)
    {
        if ($local)
        {
            echo "@`"%~dp0.R\bin\Rscript.exe`" %*" | Out-File -Encoding ascii Rscript.cmd
            echo "@`"%~dp0.R\bin\R.exe`" %*"       | Out-File -Encoding ascii R.cmd
        }
        else
        {
            echo "@`"$rScriptPath`" %*" | Out-File -Encoding ascii Rscript.cmd
            echo "@`"$rPath`" %*"       | Out-File -Encoding ascii R.cmd
        }
    }
}

function Install-RPackages
{
    [CmdletBinding()]
    Param([DateTime] $CheckpointDate,
          [string]   $CheckpointLocation = (Join-Path $env:USERPROFILE '.checkpoint'))

    $ErrorActionPreference = 'Stop'

    $cd = pwd
    $rScriptPath = Join-Path $cd Rscript.cmd
    $tempScriptPath = [IO.Path]::GetTempFileName()
    Write-Verbose "Using `"$tempScriptPath`" as packge installation script."

    Write-Verbose "Check point location is `"$checkpointLocation`"."

    if (-not (Test-Path $checkpointLocation))
    {
        Write-Verbose "Creating checkpoint location `"$checkpointLocation`" because it does not exist."
        md $checkpointLocation -Force | Out-Null
    }
    if (-not $checkpointDate)
    {
        Write-Verbose "Determining checkpoint date by scanning R files..."
        [DateTime]$checkpointDate =
            dir *.R -File | % { Write-Verbose "Scanning `"$_`" for checkpoint date"; $_ } `
                          | type `
                          | ? { $_ -match '^ *checkpoint *\( *([''"])([0-9-]+)\1' } `
                          | select -First 1 `
                          | % { $Matches[2] }
    }

    if ((-not $checkpointDate) -or ($checkpointDate -eq [DateTime]::MinValue))
    {
        Write-Error ("Checkpoint date not found! " +
                     "Did you forget a call to the checkpoint function from the checkpoint package somewhere?")
    }

    Write-Verbose "Checkpoint date is $('{0:yyyy-MM-dd}' -f $checkpointDate) ($('{0:D}' -f $checkpointDate))"

    $script = "
# ============ PACKAGE INSTALLATION SCRIPT ============
install.packages('checkpoint', repos = 'https://cloud.r-project.org/')
require(checkpoint)
checkpoint('$('{0:yyyy-MM-dd}' -f $checkpointDate)',
           checkpointLocation = '$((Split-Path $checkpointLocation) -replace '\\', '/')',
           verbose = $(if ($VerbosePreference -eq 'Continue') { 'TRUE' } else { 'FALSE' }))
# -----------------------------------------------------
"
    Write-Verbose "The package installation script is:$script"

    Set-Content $tempScriptPath $script.Trim()
    & $rScriptPath $tempScriptPath

    if ($LASTEXITCODE) {
        Write-Error "Error installing packages."
    }
}
