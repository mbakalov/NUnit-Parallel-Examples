param([switch] $UseWindowsContainer)

$saPassword = "h4rdc0dedThr0wAw4yPwd!"

if ($UseWindowsContainer) {
    $image = "microsoft/mssql-server-windows-developer"
    $sqlcmd = "sqlcmd"
} else {
    $image = "mcr.microsoft.com/mssql/server"
    $sqlcmd = "/opt/mssql-tools/bin/sqlcmd"
}

& docker pull $image
& docker run --name tcdemo-sql-001 -e "ACCEPT_EULA=Y" -e "sa_password=$saPassword" -p 1444:1433 -d $image

Start-Sleep -Seconds 10 # Let the SQL Server start...

& docker exec -it tcdemo-sql-001 $sqlcmd `
    -S localhost -U sa -P "$saPassword" `
    -Q "CREATE LOGIN [testuser] WITH PASSWORD=N'testpassword', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF"
& docker exec -it tcdemo-sql-001 $sqlcmd `
    -S localhost -U sa -P "$saPassword" `
    -Q "ALTER SERVER ROLE [sysadmin] ADD MEMBER [testuser]"

if (-not (Test-Path .\output))
{
    mkdir .\output
}
    
& msbuild .\FrameworkApp.sln /t:Build /p:FixtureCount=4 /p:TestsPerFixtureCount=2

& .\packages\NUnit.ConsoleRunner.3.11.1\tools\nunit3-console.exe `
    .\FrameworkApp.Tests\bin\Debug\FrameworkApp.Tests.dll --work=.\output