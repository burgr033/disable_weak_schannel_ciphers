param (

    $action1 = "check"

)

$scriptversion = "2019.03.06"

Start-Transcript "$PSScriptRoot\disable_weak_schannel_ciphers.ps1-$action1.log"

Write-Host "Action: $action1"

function Test-RegistryValue {

    param (

     [parameter(Mandatory=$true)]
     [ValidateNotNullOrEmpty()]$Path,

     [parameter(Mandatory=$true)]
     [ValidateNotNullOrEmpty()]$Name,

    [parameter(Mandatory=$true)]
     [ValidateNotNullOrEmpty()]$Value

    
    )

    try {

    if((Get-ItemProperty -Path $Path).$Name -eq $Value){
    return $true
    }else{
    
        return $false
    }
     }

    catch {

    return $false

    }

}


$parentpath = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL'

$key_sslv3 = "$parentpath\Protocols\SSL 3.0"

$key_sslv3_server = "$parentpath\Protocols\SSL 3.0\Server"

$key_sslv3_client = "$parentpath\Protocols\SSL 3.0\Client"

$key_schannel_dotnet = "HKLM:\SOFTWARE\Microsoft\.NetFramework\v4.0.30319"

$regkey_cipher_array = @($key_sslv3_server, $key_sslv3_client)

switch ($action1.ToLower()) {
	"check" {
        
        $counter = 0

        if(!(Test-RegistryValue -Path "$parentpath" -Name "scriptversion" -Value "$scriptversion")){Write-Host "version mismatch";$counter++}
        
        foreach ($path in $regkey_cipher_array){
        
            if(Test-Path $path){

                if (!(Test-RegistryValue -Path "$path" -Name "Enabled" -Value "0")){Write-Host $path;$counter++}

                if (!(Test-RegistryValue -Path "$path" -Name "DisabledByDefault" -Value "1")){Write-Host $path;$counter++}

            }else{
            
                $counter++
            
            }
        
        }

        if(!(Test-RegistryValue -Path "$key_schannel_dotnet" -Name "SchUseStrongCrypto" -Value "1")){Write-Host "version mismatch";$counter++}
  
        #return 0 if check OK else return higher
        if($counter -eq 0){
            Write-Host "nothing to do; installed 100"
            Stop-Transcript
            exit 100

        }else{
            Write-Host "oops, not installed correctly $(100+$counter)"
            Stop-Transcript
            exit 100+$counter
        
        }
	}
	"install" {
        foreach ($path in $regkey_cipher_array){

            New-Item $path -Force | Out-Null
            New-ItemProperty -path $path -name 'Enabled' -value '0' -PropertyType 'DWord' -Force | Out-Null
            New-ItemProperty -path $path -name 'DisabledByDefault' -value '1' -PropertyType 'DWord' -Force | Out-Null

        }

        New-ItemProperty -path $key_schannel_dotnet -name 'SchUseStrongCrypto' -value "1" -PropertyType 'Dword' -Force  | Out-Null

        New-ItemProperty -path $parentpath -name 'scriptversion' -value $scriptversion -PropertyType 'String' -Force  | Out-Null


        Write-Host 200
        Stop-Transcript
        exit 200
	}
	"remove" {

        foreach ($path in $regkey_cipher_array){

            Remove-ItemProperty -path $path -name 'Enabled' -Force  | Out-Null
            Remove-ItemProperty -path $path -name 'DisabledByDefault' -Force  | Out-Null
            Remove-Item $path -Force  | Out-Null


        }

        Remove-ItemProperty -path $key_schannel_dotnet -name 'SchUseStrongCrypto' -Force  | Out-Null

        Remove-Item $key_sslv3 -Force | Out-Null

        Write-Host 300
        Stop-Transcript
        exit 300

	}	

   
}

Stop-Transcript
