# PowerShell-Tests

This project represents a selection of tests that the PowerShell team
uses when testing PowerShell. More than 12 years of active 
development on PowerShell, we have created many different script based
test frameworks. Early in 2015 we started the migration process of our
internally created script based framework tests to the [Pester 
framework](https://github.com/pester/Pester) and this project represents 
the early fruits of that labor. Our plan is to continue to migrate our
current tests and release them in this Project, with the aim of having all 
of our tests available in the OSS community using OSS test frameworks.

We believe that by releasing these tests, our community can better understand
how we test, use these as models to better understand PowerShell, and
participate with us as we release future versions.

Some of the tests have either been _Skipped_ or marked as _Pending_, we 
expect that these tests will be activated as product changes are made available
in future releases.

# Feedback
This project will grow over time, but we are currently not able to take
pull requests, but we _do_ want your input. If you find issues or other
misbehavior, please create an issue and we will review them to see how we can
address it.

# Invoking the tests
You can either clone the project, or download a ZIP. Once the tests have 
been placed on your system, you can invoke them as you invoke any other
Pester test:
```
   PS> Invoke-Pester
```
Because a number of our tests create local sessions, it is suggested (for
now) that you run the tests in an elevated PowerShell session as non-admins,
by default, will not have the appropriate permissions.
