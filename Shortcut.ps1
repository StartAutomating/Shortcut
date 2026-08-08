<#
.SYNOPSIS
    Simple Shortcut
.DESCRIPTION
    Simple Shortcuts with PowerShell
.EXAMPLE
    # Create a `.url` shortcut (Windows Only)
    Shortcut ./psturtle.com.url "https://psturtle.com"
.EXAMPLE
    # Create a `.lnk` shortcut (Windows Only)
    Shortcut ./pwsh.lnk -TargetPath pwsh
.EXAMPLE
    # Create a `.lnk` shortcut to PowerShell
    Shortcut ./pwsh-fullscreen.lnk -TargetPath pwsh -Fullscreen
.EXAMPLE
    # Create a `.lnk` shortcut to a PowerShell script.    
    Shortcut ./pwsh-hello-world.lnk -PowerShell { "hello world" }
.EXAMPLE    
    # Create a `.desktop` shortcut to a PowerShell script

#>
[CmdletBinding(PositionalBinding=$false)]
param(
# The name of the shortcut file.
[Parameter(Position=0,ValueFromPipelineByPropertyName)]
[AllowNull()]
[AllowEmptyString()]
[string]
$ShortcutFile,

# The shortcut url
[Parameter(Position=1,ValueFromPipelineByPropertyName)]
[Alias('Uri', 'Href')]
[uri]
$Url,

# Any PowerShell to run.
# This must be either a ScriptBlock or a .ps1 path
# If it is a ScriptBlock,
# a file will be created in the same location as the link.
[ValidateScript({
    if ($_ -is [ScriptBlock]) { return $true }
    $file = try { Get-Item -Path $_ -ErrorAction Ignore } catch {} 
    if ($file.Extension -eq '.ps1') {
        return $true
    }
    throw "Must be a ScriptBlock or .ps1"
})]
[PSObject]
$PowerShell,

# The content of a simple url shortcut.
# If only a -Url or a -Url and -Content and provided, 
# will create an HTML shortcut `<a href>`
[Parameter(ValueFromPipelineByPropertyName)]
[object[]]
$Content,

# A description of the shortcut.
# This is ignored for .url shortcut files.
[Parameter(ValueFromPipelineByPropertyName)]
[Alias('Comment')]
[string]
$Description,

# The target path of the link.
[Parameter(ValueFromPipelineByPropertyName)]
[string]
$TargetPath,

# The hotkey.
# This is theoretically supported by the shortcut object
# but may be ignored by explorer.
[Parameter(ValueFromPipelineByPropertyName)]
[string]
$HotKey,

# The icon location
# The path containing an icon, 
# followed by the index in that path.
[Parameter(ValueFromPipelineByPropertyName)]
[string]
$IconLocation,

# The working directory
[Parameter(ValueFromPipelineByPropertyName)]
[string]
$WorkingDirectory,

# The window style.
[Parameter(ValueFromPipelineByPropertyName)]
[int]
$WindowStyle,

# If set, will make a fullscreen shortcut.
# Ignored for url shortcuts
# This is equivalent to using `-WindowStyle 3`
[Parameter(ValueFromPipelineByPropertyName)]
[switch]
$Fullscreen,

# Any arguments to the application
[Parameter(ValueFromPipelineByPropertyName)]
[string[]]
$Arguments,

# If set, will show the PowerShell logo
# This is ignored if `-PowerShell` is not passed
[Parameter(ValueFromPipelineByPropertyName)]
[switch]
$ShowLogo,

# If set, will automatically exit upon completion
# This is ignored if `-PowerShell` is not passed.
[Parameter(ValueFromPipelineByPropertyName)]
[switch]
$AutoExit,

# Any Desktop Entry settings
# Settings provided by other parameters will be automatically mapped
# (where possible)
[Parameter(ValueFromPipelineByPropertyName)]
[Collections.IDictionary]
$DesktopEntry = [Ordered]@{}
)

process {
    # We are not actually using parameter sets 
    # because of the binding difficulty they would present.

    # It is, however, still a useful way to think of how we will handle each input

    $parameterSet = 
        # `.desktop` files or any `-DesktopEntry`
        if ($ShortcutFile -match '\.desktop$' -or $DesktopEntry.Count) {
            'DesktopEntry' # will make it a `DesktopEntry`
        } elseif (
            # `.lnk` and `.url` shortcut files
            $ShortcutFile -match '\.(?>lnk|url)$'
        ) {
            'WindowsShortcut' # indicate a `WindowsShortcut`
        } elseif ($url -and -not $shortcutPath) {
            # A url without a path indicates an `Href`
            'Href'
        }   

    # Copy our parameters for easier debugging
    $parameters = [Ordered]@{} + $PSBoundParameters    

    # If a Script Block was provided
    if ($PowerShell -is [ScriptBlock] -and $ShortcutFile) {
        # make a .ps1 file for simplicity and security.
        $ps1Path = "$($ShortcutFile).ps1"
        "$PowerShell" > $ps1Path
        # and output that file before creating the shortcut.
        $ps1 = Get-Item -Path $ps1Path
        $ps1
        $PowerShell = $ps1.FullName
    }

    # and switch things up based off of the parameter set.
    switch ($parameterSet) {
        DesktopEntry {            
            # For desktop entries,
            $desktopEntryLines = @(
                "[Desktop Entry]" # construct the file
                # Default to application if no `Type` was provided
                if (-not $DesktopEntry.Type) {"Type=Application"}
                # Use `-Description` for `Comment`
                if ($Description -and -not $DesktopEntry.Comment) {
                    "Comment=$Description"
                }
                # Use `-TargetPath` for `Exec`
                if ($TargetPath -and -not $DesktopEntry.Exec) {
                    "Exec=$TargetPath $arguments" -replace '\s$'
                }
                elseif ($parameters.PowerShell -and -not $DesktopEntry.Exec) {
                    
                
                    "Exec=/usr/bin/pwsh $(
                        if (-not $AutoExit) {
                            '-noexit'
                        }
                        if (-not $ShowLogo) {
                            '-nologo'
                        }
                        "-file $PowerShell"
                    )" -replace '\s$'
                }
                # and output any additional values.
                foreach ($key in $DesktopEntry.Keys) {
                    "$key=$($DesktopEntry[$key])"
                }
            )
            # If a shortcut file path was provided
            if ($ShortcutFile) {
                # write to that file,
                $desktopEntryLines > $ShortcutFile
                # make it executable,
                
                if ($ExecutionContext.InvokeCommand.GetCommand("chmod", "Application")) {
                    chmod +x $ShortcutFile
                    # mark it as trusted,
                }
                
                if ($ExecutionContext.InvokeCommand.GetCommand("gio", "Application")) {
                    gio set $ShortcutFile metadata::trusted true
                }                
                # and output the file.
                Get-Item $ShortcutFile
            } else {
                # Otherwise, output the lines.
                $desktopEntryLines
            }
            
            return # and return
        }
        Href {
            # For hrefs, just stick the content into a `<a>` tag.
            return "<a href='$($Url)'>$(
                foreach ($item in $Content) {
                    if ($item.OuterXml) {
                        $item.OuterXml    
                    } elseif ($($itemHtml = $item.Html; $itemHtml)) {
                        $itemHtml
                    } else {
                        "$item"
                    }
                }
            )</a>"
        }
        default {
            # For windows shortcuts, create a `WScript.Shell` object
            $wsh = New-Object -ComObject WScript.Shell
            # If that did not work, we are most likely not on Windows.
            if (-not $wsh.CreateShortcut) { return }
            # Get our shortcut path
            $shortcutPath = # (it may not exist yet)
                $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(
                    $ShortcutFile
                )
            # Try to create the shortcut
            # (this will also get an existing shortcut)
            $shortcutObject = $wsh.CreateShortcut($shortcutPath)

            # If no shortcut object is present, return

            if (-not $shortcutObject) { return }

            # If no other parameters were passed, output our shortcut object
            if ($parameters.Count -eq 1) {
                return $shortcutObject
            }

            # If arguments exist, clear them.
            if ($shortcutObject.Arguments) {
                $shortcutObject.Arguments = ''
            }
            # Set any properties
            foreach ($prop in $parameters.Keys) {
                # that exist on the shortcut object.
                if (-not $shortcutObject.psobject.properties[$prop].IsSettable) {
                    continue
                }
                $shortcutObject.$prop = "$($parameters[$prop] -join ' ')"                
            }
            # If we want `-Fullscreen`
            if ($Fullscreen) {
                # use the right window style
                $shortcutObject.WindowStyle = 3
            }
            # If we provided PowerShell
            if ($parameters['PowerShell']) {
                # launch our own exe
                $shortcutObject.TargetPath = 
                    (Get-Process -Id $pid).Path
                # If -AutoExit was not provided
                if (-not $AutoExit) {
                    # add -NoExit
                    $shortcutObject.Arguments += "-noexit "
                }
                # If -ShowLogo was not provided
                if (-not $ShowLogo) {
                    # add -NoLogo
                    $shortcutObject.Arguments += "-nologo "
                }                
                $shortcutObject.Arguments += "-file $PowerShell"                
            }
            # If a Url was provided
            elseif ($parameters['Url']) {
                # that is the TargetPath
                $shortcutObject.TargetPath = $url    
            }

            # Save our shortcut object
            $shortcutObject.Save()
            # and get our shortcut file.
            Get-Item -Path $shortcutObject.Fullname
        }
    }    
}