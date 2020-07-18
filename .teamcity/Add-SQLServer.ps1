$saPassword = "h4rdc0dedThr0wAw4yPwd!"
& docker pull microsoft/mssql-server-windows-developer
& docker run `
    --name tcdemo-sql-001 `
    -e "ACCEPT_EULA=Y" `
    -e "SA_PASSWORD=$saPassword" `
    -p 1444:1433 -d --isolation=hyperv `
    microsoft/mssql-server-windows-developer

Start-Sleep -Seconds 30 # Wait for SQL Server to start up (get rid of this later)

& docker exec tcdemo-sql-001 sqlcmd `
    -S localhost -U sa -P "$saPassword" `
    -Q "CREATE LOGIN [testuser] WITH PASSWORD=N'testpassword', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF"
& docker exec tcdemo-sql-001 sqlcmd `
    -S localhost -U sa -P "$saPassword" `
    -Q "ALTER SERVER ROLE [sysadmin] ADD MEMBER [testuser]"