$saPassword = "h4rdc0dedThr0wAw4yPwd!"
& docker pull microsoft/mssql-server-windows-developer
& docker run `
    --name tcdemo-sql-001 `
    -e "ACCEPT_EULA=Y" `
    -e "SA_PASSWORD=$saPassword" `
    -p 1444:1433 -d --isolation=hyperv `
    microsoft/mssql-server-windows-developer

for ($i = 0; $i -lt 20; $i++) {
    & docker exec tcdemo-sql-001 sqlcmd `
        -S localhost -U sa -P "$saPassword" `
        -Q "CREATE LOGIN [testuser] WITH PASSWORD=N'testpassword', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF"

    if ($LASTEXITCODE -eq 0) {
        Write-Host "testuser created"
        break
    } else {
        Write-Host "Failed to create testuser, probably SQL Server hasn't started yet. Will retry in 15 seconds. Attempt $i/20"
        Start-Sleep -Seconds 15
    }
}

& docker exec tcdemo-sql-001 sqlcmd `
    -S localhost -U sa -P "$saPassword" `
    -Q "ALTER SERVER ROLE [sysadmin] ADD MEMBER [testuser]"