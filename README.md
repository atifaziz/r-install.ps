# r-intstall.ps

This is a PowerShell module to enable [reproducible research][repres] for
simple R projects designed to be deployed and executed in a Windows
environment. An R project is defined as loose R scripts in a directory.
The PowerShell module contains commands to do the following:

- Downloads and silently installs R without requiring administrative
  rights if it is not already installed.
- It uses (and therefore requires) [checkpoint][checkpoint] to install
  dependencies or packages required by the project.
- It generates convenience batch scripts called `R.cmd` and `Rscript.cmd`
  that invoke the right version of `R.exe` and `Rscript.exe` respectively.

All that is required for a the developer of an R project to take advantage of
the module and its commands is to use [checkpoint][checkpoint]:

```R
require(checkpoint)
# replace the checkpoint date below to the desired date
checkpoint('2017-12-01', scanForPackages = FALSE)

# remaining calls to `require` for loading dependencies...
```

Note that `scanForPackages` can be set to `FALSE` because it is assumed
that the packages will already have been installed.

Additionally, the R project's directory can contain a file called
`rversion.txt` containing the requird version of R. The content of the file
require just the version number, like so:

```
3.4.3
```

When the R project is deployed to a new machine, open a PowerShell session,
import this module and the `Install-R` command.

Once R is installed sucessfully, run the `Install-RPackages` to install the
project's dependencies or the packages it requires.


[repres]: https://cran.r-project.org/web/views/ReproducibleResearch.html
[checkpoint]: https://github.com/RevolutionAnalytics/checkpoint
