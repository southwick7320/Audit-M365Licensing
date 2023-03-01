Connect-MgGraph
$groups = Get-MgGroup -Filter "startswith(displayname,'M365_')" 
$skus = Get-MgSubscribedSku
Write-host "Collected $(($groups | Measure-Object).count)" -ForegroundColor Green
$UsersWithErrors = $groups | ForEach-Object {
    $GroupInfo = $_
    $userAccounts = Get-MgGroupMemberWithLicenseError -GroupId $GroupInfo.id
    
    $userAccounts | ForEach-Object {
        Get-MgUser -UserId $_.id  -property DisplayName, UserPrincipalName, AssignedLicenses, AssignedPlans, LicenseAssignmentStates, LicenseDetails | Select-Object DisplayName, `
         UserPrincipalName, `
          AssignedLicenses, `
           AssignedPlans, `
            LicenseAssignmentStates, `
             LicenseDetails, `
              @{name="GroupID"; Expression = {$GroupInfo.ID} }, `
               @{name="GroupName"; Expression = {$GroupInfo.DisplayName} }, `
                @{name="GroupDescription"; Expression = {$GroupInfo.Description} }, `
                 @{name="Error"; Expression = {($_.licenseAssignmentStates.Error|Where-Object {$_ -notlike 'None'} | Select-Object -Unique) -join ";"} }, `
                  @{name="LicensesWithError"; Expression = {$_.licenseAssignmentStates | Where-Object {$_.error -notlike 'None'} | ForEach-Object {

                        $skuid = $_.skuid
                        $skuid | ForEach-Object {
                            $skuIDDetail = $_
                            $skus | where {$_.skuid -like $skuIDDetail} | Select-Object Skuid, Skupartnumber
                            }

                        }
                    }

                }, `
                @{name = "OtherLicenseGroups"; Expression = {$_.licenseAssignmentStates | Where-Object {$_.state -eq 'active' -and $_.AssignedbyGroup -ne $GroupInfo.ID -and ($_.AssignedbyGroup)} | ForEach-Object {

                    Get-MgGroup -GroupId $_.assignedbygroup | Select-Object id, displayname
                
                        }
                    }
                
                },
                @{name = "DirectAssignedLicenses"; Expression = {$_.licenseAssignmentStates | Where-Object {$_.state -eq 'active' -and -not($_.AssignedbyGroup)} | ForEach-Object {

                        $skuid = $_.skuid
                        $skuid | ForEach-Object {
                            $skuIDDetail = $_
                            $skus | where {$_.skuid -like $skuIDDetail} | Select-Object Skuid, Skupartnumber
                            }
                
                        }
                    }
                
                }
        }    
}    
$UsersWithErrors
