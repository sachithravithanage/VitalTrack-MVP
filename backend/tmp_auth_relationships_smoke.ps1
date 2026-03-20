$ErrorActionPreference = 'Stop'

function Exchange-CustomToken([string]$customToken) {
  $emuUrl = 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=fake-key'
  $resp = Invoke-RestMethod -Uri $emuUrl -Method Post -ContentType 'application/json' -Body (@{ token = $customToken; returnSecureToken = $true } | ConvertTo-Json)
  return $resp.idToken
}

function New-Phone() {
  $n = Get-Random -Minimum 10000000 -Maximum 99999999
  return "07$n"
}

$base = 'http://localhost:5000/api/v1'

$patientPhone = New-Phone
$patientEmail = "phoneonly.$([Guid]::NewGuid().ToString('N').Substring(0,8))@example.com"
$patientSignup = Invoke-RestMethod -Uri "$base/auth/signup" -Method Post -ContentType 'application/json' -Body (@{ phone = $patientPhone; password = 'Pass1234!'; name = 'Phone Only Patient'; role = 'patient' } | ConvertTo-Json)
$patientToken = Exchange-CustomToken -customToken $patientSignup.data.customToken
$patientHeaders = @{ Authorization = "Bearer $patientToken" }

$profileUpdate = Invoke-RestMethod -Uri "$base/users/profile" -Method Put -Headers $patientHeaders -ContentType 'application/json' -Body (@{ email = $patientEmail } | ConvertTo-Json)
$verifyEmail = Invoke-RestMethod -Uri "$base/users/verify-email" -Method Post -Headers $patientHeaders -ContentType 'application/json' -Body '{}'
$enableCaregiver = Invoke-RestMethod -Uri "$base/users/roles/caregiver" -Method Post -Headers $patientHeaders -ContentType 'application/json' -Body '{}'
$caregiversList = Invoke-RestMethod -Uri "$base/relationships/caregivers" -Method Get -Headers $patientHeaders
$linkCodeResp = Invoke-RestMethod -Uri "$base/relationships/link-code" -Method Post -Headers $patientHeaders -ContentType 'application/json' -Body '{}'
$linkCode = $linkCodeResp.data.code

$caregiverPhone = New-Phone
$caregiverSignup = Invoke-RestMethod -Uri "$base/auth/signup" -Method Post -ContentType 'application/json' -Body (@{ phone = $caregiverPhone; password = 'Pass1234!'; name = 'Caregiver User'; role = 'caregiver' } | ConvertTo-Json)
$caregiverToken = Exchange-CustomToken -customToken $caregiverSignup.data.customToken
$caregiverHeaders = @{ Authorization = "Bearer $caregiverToken" }

$manualCreate = Invoke-RestMethod -Uri "$base/relationships/create-patient" -Method Post -Headers $caregiverHeaders -ContentType 'application/json' -Body (@{ name = 'Managed Patient'; disease = 'dengue' } | ConvertTo-Json)
$addByCode = Invoke-RestMethod -Uri "$base/relationships/add-patient" -Method Post -Headers $caregiverHeaders -ContentType 'application/json' -Body (@{ code = $linkCode; disease = 'ratFever' } | ConvertTo-Json)
$patientsList = Invoke-RestMethod -Uri "$base/relationships/patients" -Method Get -Headers $caregiverHeaders

$result = [ordered]@{
  patientPhoneOnlySignup = [bool]$patientSignup.success
  addEmailAuthorized = [bool]$profileUpdate.success
  verifyEmailAuthorized = [bool]$verifyEmail.success
  enableCaregiverAuthorized = [bool]$enableCaregiver.success
  loadCaregiversAuthorized = [bool]$caregiversList.success
  generateCaregiverCodeAuthorized = [bool]$linkCodeResp.success
  caregiverManualCreateAuthorized = [bool]$manualCreate.success
  caregiverAddByCodeAuthorized = [bool]$addByCode.success
  caregiverLoadPatientsAuthorized = [bool]$patientsList.success
  generatedCode = $linkCode
}

$result | ConvertTo-Json -Compress
