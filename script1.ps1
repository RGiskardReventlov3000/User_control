# Скрипт 1: Подготовка к блокировке учетных записей

# Параметры скрипта
$InactiveDays = 60                  # Дни бездействия для блокировки
$DomainController = "corp.local"          # Доменный контроллер
$WhitelistPath = "C:\ExpiredUsers\whitelist.txt" # Файл белого списка
$UsersToDisablePath = "C:\ExpiredUsers\UsersToDisable.txt" # Файл пользователей к блокировке
$SMTPServer = "1.1.1.1"    # SMTP сервер
$SMTPPort = 25     # Порт SMTP сервера
$Recipient = "it@corp.local"    # Получатель уведомления
$EmailFrom = "expired.users.scheduler@it@corp.local" # Отправитель уведомления

# Подключение модуля ActiveDirectory
Import-Module ActiveDirectory




# Вычисление даты для сравнения
$CurrentDate = Get-Date
$DateToCompare = $CurrentDate.AddDays(-$InactiveDays)
echo $DateToCompare

# Чтение белого списка из файла
$Whitelist = Get-Content -Path $WhitelistPath -ErrorAction SilentlyContinue

# Получение списка пользователей
$allUsers = Get-ADUser -Filter * -Properties DistinguishedName, GivenName, Name, Surname, SamAccountName, UserPrincipalName, Department, Organization, Title, Description, LastLogonDate, PasswordLastSet, whenCreated -Server $DomainController | where { $_.Enabled -eq $true } 
# Сегодняшняя дата
$today = (Get-Date)
# Список учетных записей, где дата последнего входа более $InactiveDays дней  
$UsersToDisable = $allUsers | Where-Object { $_.LastLogonDate -ne $null -and ($today - $_.LastLogonDate).Days -gt $InactiveDays } |
    Where-Object { $Whitelist -notcontains $_.SamAccountName } |
    Select-Object SamAccountName



echo $UsersToDisable
# Сохранение подготовленных к блокировке учетных записей в файл
$UsersToDisable | ForEach-Object { $_.SamAccountName } | Set-Content -Path $UsersToDisablePath

# Тело письма
$MailBody = @"
Следующие пользователи БУДУТ отключены из-за неактивности:
$($UsersToDisable.SamAccountName -join ', ')

Пожалуйста, просмотрите белый список по адресу $WhitelistPath, если вам нужно добавить исключания из блокировки.
"@

# Параметры отправки письма
$MailParams = @{
    To = $Recipient
    From = $EmailFrom
    Subject = "Уведомление о подготовке к блокировке УЗ не активных более 90 дней"
    Body = $MailBody
    SmtpServer = $SMTPServer
    Port = $SMTPPort
    ErrorAction = 'Stop'
    UseSsl = $false # Добавлено для использования SSL
    Encoding = [System.Text.Encoding]::UTF8
    }


# Отправка письма
try {
    Send-MailMessage @MailParams
} catch {
    Write-Error "Не удалось отправить письмо. Ошибка: $_"
}
