# function Start-HttpServer {
#     [CmdletBinding()]
#     param (
#         # Specify a port for the server to listen on
#         [Parameter(Mandatory = $false)]
#         [ValidateRange(1024, 29999)]
#         [Int32]
#         $ListenPort = 8080
#     )
    
#     begin {
#         if ($ListenPort -eq 8080) {
#             Write-Warning "No, or default, port specified. Using port 8080..."
#             # Start a listener on the specified port
#             $listener = New-Object System.Net.HttpListener
#             $listener.Prefixes.Add("http://localhost:$ListenPort/")
#             $listener.Start()
#         }
#     }
    
#     process {
#         Write-Host "Press Esc to stop the server..."
#         # Start a loop that will stop if the user inputs the Esc key
#         while (!([console]::ReadKey($true).Key -eq "Escape")) {
            
#             # Wait for a request to come in
#             $context = $listener.GetContext()
            
#             # Get the request and response objects
#             $request = $context.Request
#             $response = $context.Response
            
#             # Get the requested file
#             $filePath = $request.Url.AbsolutePath
#             $filePath = $filePath.Substring(1)
#             $filePath = Resolve-Path $filePath
            
#             # Check if the file exists
#             if (Test-Path $filePath) {
#                 # If the file exists, read it and send it to the client
#                 $fileBytes = [System.IO.File]::ReadAllBytes($filePath)
#                 $response.OutputStream.Write($fileBytes, 0, $fileBytes.Length)
#             }
#             else {
#                 # If the file doesn't exist, send a 404
#                 $response.StatusCode = 404
#             }
#         }
#     }
    
#     end {
#         # Close the response stream
#         $response.Close()
            
#         # Stop the listener
#         $listener.Stop()        
#     }
# }