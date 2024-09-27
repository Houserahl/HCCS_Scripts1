try {  
    #CSV File Path.Change this location accordingly  
    $filePath = "C:\Temp\CreateBulkTeams.csv"  
    #read the input file  
    $loadFile = Import-Csv -Path $filePath  
    foreach($row in $loadFile) {  
        $teamName = $row.TeamName
        $teamDescription = $row.TeamDescription
        $teamOwner = $row.Owner  
        $teamVisibility = $row.Visibility  
        #create the team with specified parameters  
        $groupID = New-Team -DisplayName $teamName -Owner $teamOwner -Description $teamDescription -Visibility $teamVisibility  
        Write - Host "Team " 
        $teamName
    }  
    Write - Host $loadFile.Count " teams were created" -ForegroundColor Green -BackgroundColor Black  
} catch {  
    Write - Host "An error occurred:"  
    Write - Host $_  
}  