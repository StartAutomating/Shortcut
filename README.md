# Shortcut
[![Shortcut](https://img.shields.io/powershellgallery/dt/Shortcut)](https://www.powershellgallery.com/packages/Shortcut/)
## Simple Shortcuts with PowerShell
Shortcuts can be handy.

They let us launch things at the click of a button.

This can be extra handy for people who are allergic to terminals.

Shortcut is a simple module to create shortcuts with scripts.

## Installing and Importing

You can install Shortcut from the [PowerShell gallery](https://powershellgallery.com/)

~~~PowerShell
Install-Module Shortcut -Scope CurrentUser -Force
~~~

Once installed, you can import the module with:

~~~PowerShell
Import-Module Shortcut -PassThru
~~~


You can also clone the repo and import the module locally:

~~~PowerShell
git clone https://github.com/StartAutomating/Shortcut
cd ./Shortcut
Import-Module ./ -PassThru
~~~

## Functions
Shortcut has 1 function
### Get-Shortcut
#### Simple Shortcut
Simple Shortcuts with PowerShell
##### Parameters

|Name|Type|Description|
|-|-|-|
|ShortcutFile|String|The name of the shortcut file.|
|Url|Uri|The shortcut url|
|PowerShell|PSObject|Any PowerShell to run.<br/>This must be either a ScriptBlock or a .ps1 path<br/>If it is a ScriptBlock,<br/>a file will be created in the same location as the link.|
|Content|Object[]|The content of a simple url shortcut.<br/>If only a -Url or a -Url and -Content and provided, <br/>will create an HTML shortcut `<a href>`|
|Description|String|A description of the shortcut.<br/>This is ignored for .url shortcut files.|
|TargetPath|String|The target path of the link.|
|HotKey|String|The hotkey.<br/>This is theoretically supported by the shortcut object<br/>but may be ignored by explorer.|
|IconLocation|String|The icon location<br/>The path containing an icon, <br/>followed by the index in that path.|
|WorkingDirectory|String|The working directory|
|WindowStyle|Int32|The window style.|
|Fullscreen|SwitchParameter|If set, will make a fullscreen shortcut.<br/>Ignored for url shortcuts<br/>This is equivalent to using `-WindowStyle 3`|
|Arguments|String[]|Any arguments to the application|
|ShowLogo|SwitchParameter|If set, will show the PowerShell logo<br/>This is ignored if `-PowerShell` is not passed|
|AutoExit|SwitchParameter|If set, will automatically exit upon completion<br/>This is ignored if `-PowerShell` is not passed.|
|DesktopEntry|IDictionary|Any Desktop Entry settings<br/>Settings provided by other parameters will be automatically mapped<br/>(where possible)|

##### Examples
###### Example 1
Create a `.url` shortcut (Windows Only)
~~~PowerShell
Shortcut ./psturtle.com.url "https://psturtle.com"
~~~
###### Example 2
Create a `.lnk` shortcut (Windows Only)
~~~PowerShell
Shortcut ./pwsh.lnk -TargetPath pwsh
~~~
###### Example 3
Create a `.lnk` shortcut to PowerShell
~~~PowerShell
Shortcut ./pwsh-fullscreen.lnk -TargetPath pwsh -Fullscreen
~~~
###### Example 4
Create a `.lnk` shortcut to a PowerShell script.    
~~~PowerShell
Shortcut ./pwsh-hello-world.lnk -PowerShell { "hello world" }
~~~
###### Example 5
Create a `.desktop` shortcut to a PowerShell script
~~~PowerShell
Shortcut ./pwsh.desktop -TargetPath /usr/bin/pwsh
~~~
