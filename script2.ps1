# Скрипт 2: Блокировка учетных записей

# Путь к файлу с белым списком пользователей
$WhitelistPath = "C:\ExpiredUsers\whitelist.txt" # Пример: задать "C:\ExpiredUsers\whitelist.txt"

# Путь к файлу с подготовленными к блокировке учетными записями
$UsersToDisablePath = "C:\ExpiredUsers\UsersToDisable.txt" # Пример: задать "C:\ExpiredUsers\UsersToDisable.txt"

# Подключение модуля ActiveDirectory
Import-Module ActiveDirectory

# Чтение белого списка из файла
$Whitelist = Get-Content -Path $WhitelistPath -ErrorAction SilentlyContinue

# Чтение списка пользователей подлежащих блокировке
$UsersToDisable = Get-Content -Path $UsersToDisablePath -ErrorAction SilentlyContinue

# Фильтрация списка, исключая учетные записи из белого списка
$UsersToDisable = $UsersToDisable | Where-Object { $Whitelist -notcontains $_ }

# Тело письма
$MailBody = @"
Следующие пользователи УЖЕ были отключены из-за неактивности:
$($UsersToDisable -join ', ')

Пожалуйста, просмотрите белый список по адресу $WhitelistPath, если вам нужно добавить исключания из блокировки.
"@

# Блокировка учетных записей
$UsersToDisable | ForEach-Object {
    $user = Get-ADUser -Identity $_
    if ($user) {
        Disable-ADAccount -Identity $user
        # Здесь вы можете добавить дополнительную логику, такую как запись в журнал
    }
}

$SMTPServer = "1.1.1.1"    # SMTP сервер
$SMTPPort = 25     # Порт SMTP сервера
$SMTPUseAuthentication = $false     # Использовать авторизацию SMTP или нет
$SMTPUsername = ""                  # Имя пользователя SMTP
$SMTPPassword = ""                  # Пароль пользователя SMTP
$Recipient = "it@corp.local"    # Получатель уведомления
$EmailFrom = "expired.users.scheduler@it@corp.local" # Отправитель уведомления



# Параметры отправки письма
$MailParams = @{
    To = $Recipient
    From = $EmailFrom
    Subject = "Уведомление о блокировке УЗ не активных более 90 дней"
    Body = $MailBody
    SmtpServer = $SMTPServer
    Port = $SMTPPort
    ErrorAction = 'Stop'
    UseSsl = $false # Добавлено для использования SSL
    Encoding = [System.Text.Encoding]::UTF8
    }

# Добавление параметров аутентификации, если необходимо
if ($SMTPUseAuthentication) {
    $SecurePassword = ConvertTo-SecureString $SMTPPassword -AsPlainText -Force
    $Credentials = New-Object System.Management.Automation.PSCredential ($SMTPUsername, $SecurePassword)
    $MailParams.Credential = $Credentials
}

# Отправка письма
try {
    Send-MailMessage @MailParams
} catch {
    Write-Error "Не удалось отправить письмо. Ошибка: $_"
}