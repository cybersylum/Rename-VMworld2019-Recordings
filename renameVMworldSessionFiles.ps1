param(
		[Parameter(Mandatory=$false,HelpMessage="file of vmworld sessions & descriptions",ValueFromPipeline=$true)][string]$sessionsDescriptionFile="us.txt",
        [Parameter(Mandatory=$false,HelpMessage="Directory containing VMworld Session Recordings",ValueFromPipeline=$true)][string]$RecordingPath="E:\VMworld 2019"
)

if (!(test-path($sessionsDescriptionFile))) {
    Write-host "Cannot continue - Session Description File not found: " $sessionsDescriptionFile -ForegroundColor "red"
    break
}

if (!(test-path($RecordingPath))) {
    Write-host "Cannot continue - Sessions Recording folder not found: " $RecordingPath -ForegroundColor "red"
    break
}

 
#Build the Session lookup table
$lines = Get-Content -Path $sessionsDescriptionFile | Where-Object { $_.Trim() -ne '' }

$Sessions = @{}
foreach ($line in $lines) {
    ($title,$url) = $line -split "#"
    ($SessionNumber,$SessionDescription) = $title -split "-"

    $SessionNumber = $SessionNumber.replace("[",'')
    $SessionNumber = $SessionNumber.replace("]",'')
    $SessionNumber = $SessionNumber.trim()
  
    $SessionDescription = $SessionDescription.replace("`:",'')
    $SessionDescription = $SessionDescription.replace("`;",'')    
    $SessionDescription = $SessionDescription.replace(".",'')
    $SessionDescription = $SessionDescription.replace("(",'')
    $SessionDescription = $SessionDescription.replace(")",'')    
    $SessionDescription = $SessionDescription.replace("&",'')
    $SessionDescription = $SessionDescription.replace(",",'')        
    $SessionDescription = $SessionDescription.replace("`'",'')
    $SessionDescription = $SessionDescription.replace("/",'_')
    $SessionDescription = $SessionDescription.replace("\",'_')
    $SessionDescription = $SessionDescription.replace("?",'')
    $SessionDescription = $SessionDescription.trim()

    $Sessions.add($SessionNumber,$SessionDescription)
}

$DFSFolders = get-childitem -path $RecordingPath | where-object {$_.Psiscontainer -eq "True"} |select-object name

#Loop through folders in the Recordings directory
foreach ($DFSfolder in $DFSfolders) {

    $recordings = get-childitem -path "$RecordingPath\$($DFSfolder.name)" -recurse -filter *.mp4

    foreach ($Recording in $Recordings) {
        ($RecordingSessionID,$ext) = ($Recording.Name).split(".")
        $RecordingDescription = $Sessions[$RecordingSessionID]
        if ($RecordingDescription.length -gt 0) {   
            $OldName = $Recording.DirectoryName + "\" + $Recording.Name
            $NewName ="$RecordingSessionID - $RecordingDescription.mp4"
            write-host "Renaming $RecordingSessionID"
            try {
                Rename-Item -path $OldName -newname $NewName
            } catch {
                write-host -ForegroundColor Red "   Rename failed..."
            }
        } else {
            # no match in us.txt - dump debug text
            write-host "[$recording] - "
        }
    }

}