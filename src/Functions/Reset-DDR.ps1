function ResetDDR {
    Remove-Item -Path "C:\Data_Dev2\TrustInvestmentApplications\CashSweep\Dividend Accrual Reports\*" -Recurse -Force
    Remove-Item -Path "C:\Data_Dev2\TrustInvestmentApplications\CashSweep\NDMFile\DividendAccrualsFile\*" -Recurse -Force
    Remove-Item -Path "C:\Data_Dev2\TrustInvestmentApplications\CashSweep\NDMFileArchive\*" -Recurse -Force
    Copy-Item -Path "C:\Data_Dev2\TrustInvestmentApplications\CashSweep\JF548SAE_extract.txt.1241111.092339" -Destination "C:\Data_Dev2\TrustInvestmentApplications\CashSweep\NDMFile\DividendAccrualsFile" -Force
}

function ResetDDRDev {
    Remove-Item -Path "\\csafscct01\CCT_Root\Data_Dev2\TrustInvestmentApplications\CashSweep\Dividend Accrual Reports\*" -Recurse -Force
    Remove-Item -Path "\\csafscct01\CCT_Root\Data_Dev2\TrustInvestmentApplications\CashSweep\NDMFile\DividendAccrualsFile\*" -Recurse -Force
    Remove-Item -Path "\\csafscct01\CCT_Root\Data_Dev2\TrustInvestmentApplications\CashSweep\NDMFileArchive\*" -Recurse -Force
    Copy-Item -Path "\\csafscct01\CCT_Root\Data_Dev2\TrustInvestmentApplications\CashSweep\Sample Files\*" -Destination "\\csafscct01\CCT_Root\Data_Dev2\TrustInvestmentApplications\CashSweep\NDMFile\DividendAccrualsFile" -Force
}
    
function ResetDDRSit {
    Remove-Item -Path "\\csafscct01\CCT_Root\Data_Sit2\TrustInvestmentApplications\CashSweep\Dividend Accrual Reports\*" -Recurse -Force
    Remove-Item -Path "\\csafscct01\CCT_Root\Data_Sit2\TrustInvestmentApplications\CashSweep\NDMFile\DividendAccrualsFile\*" -Recurse -Force
    Remove-Item -Path "\\csafscct01\CCT_Root\Data_Sit2\TrustInvestmentApplications\CashSweep\NDMFileArchive\*" -Recurse -Force
    Copy-Item -Path "\\csafscct01\CCT_Root\Data_Sit2\TrustInvestmentApplications\CashSweep\Sample Files\*" -Destination "\\csafscct01\CCT_Root\Data_Sit2\TrustInvestmentApplications\CashSweep\NDMFile\DividendAccrualsFile" -Force
}

function CleanDDRDev {
    ResetDDRDev
    Remove-Item -Path "\\csafscct01\CCT_Root\Data_Dev2\TrustInvestmentApplications\CashSweep\NDMFile\DividendAccrualsFile\*" -Recurse -Force
}
    
function CleanDDRSit {
    ResetDDRSit
    Remove-Item -Path "\\csafscct01\CCT_Root\Data_Sit2\TrustInvestmentApplications\CashSweep\NDMFile\DividendAccrualsFile\*" -Recurse -Force
}