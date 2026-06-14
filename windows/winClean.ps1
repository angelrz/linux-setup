# Script para eliminar aplicaciones de Windows
# Ejecutar como Administrador

$apps = @(
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxApp",
    "Microsoft.WindowsSoundRecorder",
    "Microsoft.WindowsMaps",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.People",
    "Microsoft.MixedReality.Portal",
    "Microsoft.Getstarted",
    "Microsoft.GetHelp",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.WindowsAlarms",
    "Microsoft.ZuneMusic",
    "Microsoft.YourPhone",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.BingWeather",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.MicrosoftStickyNotes",
    "Microsoft.MSPaint",
    "Microsoft.Office.OneNote",
    "Microsoft.SkypeApp",
    "Microsoft.ZuneVideo",
    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.XboxGameCallableUI",
    "Microsoft.549981C3F5F10",
    "Microsoft.BingSearch",
    "Microsoft.Copilot"
)

foreach ($app in $apps) {
    Write-Host "Eliminando: $app" -ForegroundColor Yellow
    
    # Elimina del usuario actual
    Get-AppxPackage -Name $app | Remove-AppxPackage
    
    # Elimina de todos los usuarios
    Get-AppxPackage -AllUsers -Name $app | Remove-AppxPackage -AllUsers
    
    # Elimina el aprovisionamiento
    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like "*$app*" | Remove-AppxProvisionedPackage -Online
    
    Write-Host "Completado: $app" -ForegroundColor Green
}

Write-Host "`nProceso finalizado" -ForegroundColor Cyan