#
# Manifeste de module pour le module "CodeMap"
#
# Généré le : 05/05/2019
@{
  Author="Laurent Dardenne"
  CompanyName=""
  Copyright="2019, Laurent Dardenne, released under Copyleft"
  Description="CodeMap"
  CLRVersion="2.0"
  GUID = 'fc908210-538a-4697-bf6d-b6f9c66828e7'
  ModuleToProcess="CodeMap.psm1"
  ModuleVersion="1.0.0"
  PowerShellVersion="5.1"
#  FunctionsToExport ='',  VariablesToExport ='LogDefaultColors','LogJobName'

  RequiredAssemblies=@('.\PSADigraph.dll')

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
