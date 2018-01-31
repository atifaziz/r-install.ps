# r-intstall.ps

This is a PowerShell module to enable [reproducible research][repres] for
simple R projects designed to be deployed and executed in a Windows
environment. An R project is defined as loose R scripts in a directory.

The PowerShell module contains commands to do the following:

- Download and silently install R without requiring administrative
  rights. Download/Installation is skipped if it has happened before.
- Use (and therefore requires) [checkpoint][checkpoint] to install
  dependencies or packages required by the project.
- Generate convenience batch scripts called `R.cmd` and `Rscript.cmd`
  that invoke the right version of `R.exe` and `Rscript.exe` respectively.

All that is required for a the developer of an R project to take advantage of
the module and its commands is to use [checkpoint][checkpoint] like shown
in the example below:

```R
require(checkpoint)
# replace the checkpoint date below to the desired date
checkpoint('2017-12-01', scanForPackages = FALSE)

# remaining calls to `require` for loading dependencies...
```

Note that `scanForPackages` can be set to `FALSE` because it is assumed
that the packages will have been installed before.

The R project's directory can contain a file called `rversion.txt` with the
requird version of R as its sole content, like so:

```
3.4.3
```

When the R project is deployed to a new machine, open a PowerShell session,
import this module, `cd` to the directory of the project and run the
`Install-R` command.

Once R is installed sucessfully, run the `Install-RPackages` to install the
project's dependencies or the packages it requires.


[repres]: https://cran.r-project.org/web/views/ReproducibleResearch.html
[checkpoint]: https://github.com/RevolutionAnalytics/checkpoint
