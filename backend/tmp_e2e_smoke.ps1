$ErrorActionPreference = 'Stop'
$base = 'http://localhost:5000/api/v1'
$apiKey = 'fake-api-key'
$pwd = 'Test@1234'
$ts = [int][double]::Parse((Get-Date -UFormat %s))
$patientEmail = "pt$ts@test.com"
$caregiverEmail = "cg$ts@test.com"
$seed = $ts % 9000000
$patientPhone = ('07' + ($seed + 1000000).ToString('D7'))
$caregiverPhone = ('07' + ($seed + 2000000).ToString('D7'))

function PostJson($url, $body, $headers = $null) {
  $json = $body | ConvertTo-Json -Depth 10
  if ($headers) {
    return Invoke-RestMethod -Method Post -Uri $url -Headers $headers -ContentType 'application/json' -Body $json
  }
  return Invoke-RestMethod -Method Post -Uri $url -ContentType 'application/json' -Body $json
}

function GetJson($url, $headers) {
  return Invoke-RestMethod -Method Get -Uri $url -Headers $headers
}

$null = PostJson "$base/auth/signup" @{ email = $patientEmail; phone = $patientPhone; password = $pwd; name = 'E2E Patient'; role = 'patient' }
$null = PostJson "$base/auth/signup" @{ email = $caregiverEmail; phone = $caregiverPhone; password = $pwd; name = 'E2E Caregiver'; role = 'caregiver' }

$patientLogin = PostJson "$base/auth/login" @{ credential = $patientEmail; password = $pwd }
$caregiverLogin = PostJson "$base/auth/login" @{ credential = $caregiverEmail; password = $pwd }

$signInUri = "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=$apiKey"
$patientSignIn = PostJson $signInUri @{ token = $patientLogin.data.customToken; returnSecureToken = $true }
$caregiverSignIn = PostJson $signInUri @{ token = $caregiverLogin.data.customToken; returnSecureToken = $true }

$patientHeaders = @{ Authorization = "Bearer $($patientSignIn.idToken)" }
$caregiverHeaders = @{ Authorization = "Bearer $($caregiverSignIn.idToken)" }

$linkCodeResp = PostJson "$base/relationships/link-code" @{} $patientHeaders
$linkCode = $linkCodeResp.code
$attachResp = PostJson "$base/relationships/add-patient" @{ code = $linkCode; disease = 'dengue' } $caregiverHeaders
$patientId = $attachResp.relationship.patientId

$dengueRecord = PostJson "$base/records" @{
  patientId = $patientId
  disease = 'dengue'
  temperature = '38.2'
  fluidIntake = '900'
  urineOutput = '250'
  values = @{ temperature = '38.2'; fluidIntake = '900'; urineOutput = '250' }
  symptoms = @{
    feverDrop = $false
    coldClammyHandsFeet = $false
    vomiting = $true
    dizziness = $true
    severeRightUpperAbdominalPain = $false
    poorAppetite = $true
    suddenReturnOfAppetite = $false
  }
  notes = 'caregiver dengue record e2e'
} $caregiverHeaders

$recordsByPatient = GetJson "$base/records?timelineFilter=last7Days" $patientHeaders
$recordsByCaregiver = GetJson "$base/records?patientId=$patientId&timelineFilter=last7Days" $caregiverHeaders
$exportResp = GetJson "$base/records/export/pdf?patientId=$patientId&timelineFilter=last7Days" $caregiverHeaders

$result = [ordered]@{
  patientEmail = $patientEmail
  caregiverEmail = $caregiverEmail
  patientId = $patientId
  linkCode = $linkCode
  recordCreated = ($dengueRecord.record.id -ne $null)
  patientRecordCount = $recordsByPatient.records.Count
  caregiverRecordCount = $recordsByCaregiver.records.Count
  exportUrlPresent = ([string]::IsNullOrWhiteSpace($exportResp.pdf.url) -eq $false)
  exportUrlSample = $exportResp.pdf.url.Substring(0, [Math]::Min(90, $exportResp.pdf.url.Length))
}

$result | ConvertTo-Json -Depth 6