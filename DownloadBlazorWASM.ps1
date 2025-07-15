$artifact = "drop"
$release = "Release"
$project = "EDR-NotifPush"
$serverUrl = "https://dev.azure.com/nextsourcia"

Add-Type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

$PATToken = "cundo6r2jkwn34lxqs7gnp76tyc63mvnpjhcdgmuvgavhtrfmpva"
# $PATToken64 = "Onl5c3E1cG1hbDR2bGZ6M3JtdGR5Z3lsdzZ5aWF6dHl5cXp2ZXA0dHlxeWJzY3BncmF4ZGE="
$AuthHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PATToken)")) }
# $AuthHeader = @{Authorization = 'Basic ' + $PATToken64 }

$uri = "$serverUrl/$project/_apis/build/definitions/1?includeLatestBuilds=true&api-version=6.0"
$latest = Invoke-RestMethod -Uri $uri -Method get -Headers $AuthHeader
# -Credential $cred

if ($latest.latestBuild.status -ne "completed")
{
    Write-Output "Pas encore terminé"
    exit
}

$latestbuilId = $latest.latestBuild.id
$filename = $latest.latestBuild.buildNumber + " NotifPush.zip"
$uri = "$serverUrl/$project/_apis/build/builds/" + $latestbuilId +  "/artifacts?artifactName=$artifact&api-version=6.0"
$drop = Invoke-RestMethod -Uri $uri -Method get -Headers $AuthHeader
$fileid = $drop[0].resource.data.substring(1)
$sourcefile = "$serverUrl/_apis/resources/Containers" + $fileid + "?itemPath=$artifact%2FServer.zip"
Invoke-WebRequest -Uri $sourcefile -OutFile $filename -Header $AuthHeader