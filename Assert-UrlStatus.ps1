# Michael Duncan
# 6/21/2017
# Asserts that a website has a specified status

param (
  [Parameter(Mandatory=$True,Position=1)]
  [string]$Url,
  [Parameter(Position=2)]
  [int]$StatusCode=200,
  [int]$Timeout=100,
  [switch]$AllowRedirects,
  [switch]$IgnoreCertificate
)

#Ignore certificates
if($IgnoreCertificate){
if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type)
{
$certCallback=@"
	using System;
	using System.Net;
	using System.Net.Security;
	using System.Security.Cryptography.X509Certificates;
	public class ServerCertificateValidationCallback
	{
		public static void Ignore()
		{
			if(ServicePointManager.ServerCertificateValidationCallback ==null)
			{
				ServicePointManager.ServerCertificateValidationCallback += 
					delegate
					(
						Object obj, 
						X509Certificate certificate, 
						X509Chain chain, 
						SslPolicyErrors errors
					)
					{
						return true;
					};
			}
		}
	}
"@
	Add-Type $certCallback
}

  [ServerCertificateValidationCallback]::Ignore();
}

#Request the URL
#Needs to be surrounded with try/catch otherwise it will error at 404/500 (which we may want to test)
try{
  if(-not $AllowRedirects)
  {
	$maxRedirects = 0;
  }else{
	$maxRedirects = 5;
  }
  $R = Invoke-WebRequest $Url -TimeoutSec $Timeout -usebasicparsing -MaximumRedirection $maxRedirects -ErrorAction SilentlyContinue
  $RSC = $R.StatusCode
}catch{
  write-host "Invoke-WebRequest error. This could be caused from a 4XX or 5XX server response. Response code will be extracted and test will continue."
  $RSC = $_.Exception.Response.StatusCode.Value__
  $_.Exception
}

#Test that status code is what is expected
write-host -NoNewline "Asserting $url responds with status code $StatusCode... "
if($RSC -eq $StatusCode){
  write-host "OK" -foreground "green"
  exit 0
}else{
  write-host "FAIL" -foreground "red"
  throw "Assertion fail: $url gives an unexpected status code! Recieved: $RSC, Expected: $StatusCode"
  exit 1
}