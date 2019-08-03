#
# Manifeste de module pour le module "CodeMap"
#
# Généré le : 30/07/2019
@{
  Author="Laurent Dardenne"
  CompanyName=""
  Copyright="2019, Laurent Dardenne, released under Copyleft"
  Description="Retrieve the dependencies of a powershell code."
  CLRVersion="2.0"
  GUID = '68182e63-a349-49c2-b78d-bbd5bb029e19'
  ModuleToProcess="Dependency.psm1"
  ModuleVersion="1.0.0"
  PowerShellVersion="5.1"
  RequiredModules=@(
    @{ModuleName="Log4Posh";GUID="f796dd07-541c-4ad8-bfac-a6f15c4b06a0"; ModuleVersion="3.0.3"}
  )  
  
#  FunctionsToExport ='',  VariablesToExport ='LogDefaultColors','LogJobName'

    # Supported PSEditions
  CompatiblePSEditions = 'Desktop'

  PrivateData = @{

    PSData = @{

        Tags = @('PSEdition_Desktop')

        LicenseUri = 'https://creativecommons.org/licenses/by-nc-sa/4.0'

        ProjectUri = 'https://github.com/LaurentDardenne/PSMap'

        # A URL to an icon representing this module.
        #IconUri = 'https://github.com/LaurentDardenne/PSMap/blob/master/Icon/Log4Posh.png'

        ReleaseNotes = 'Initial version.'
    } 
  } 
}
