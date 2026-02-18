<#
.SYNOPSIS
Using Datto RMM, attempt to send a Wake-on-LAN packet to a device using its MAC address.
Written by Lee Mackie - 5G Networks

.NOTES
Type: Script
Version 1.1 - Updated header file
#>

try {
    # Define the MAC address of the target device
    [string]$mac = $env:MacAddress

    # Define a regular expression to match a MAC address with colon separators
    $regex = '^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$'

    if ($mac -notmatch $regex) {
        Write-Host "$mac does not match required format - ensure octets are seperated with colons (:) and you have entered the correct length."
        Exit 1
    }

    # Convert the MAC address to a byte array
    $macBytes = $mac.Split(':') | ForEach-Object { [byte]('0x' + $_) }

    # Create a UDP client
    $udpClient = New-Object System.Net.Sockets.UdpClient

    # Set the broadcast address and port number
    $broadcastAddress = [System.Net.IPAddress]::Broadcast
    $port = 9  # default WoL port number

    # Construct the WoL packet
    $packet = [byte[]](,0xff * 6) + ($macBytes * 16)

    # Send the WoL packet to the broadcast address
    $bytesSent = $udpClient.Send($packet, $packet.Length, $broadcastAddress, $port)

    # Close the UDP client
    $udpClient.Close()

    if ($bytesSent -ne $packet.Length) {
        Write-Host "Failed to send Wake-on-LAN packet."
        Exit 1
    } else {
        Write-Host "Wake-on-LAN packet sent successfully."
        Write-Host "Bytes sent: $bytesSent"
    }
} catch {
    Write-Host "Error encountered!"
    Write-Host $_
}