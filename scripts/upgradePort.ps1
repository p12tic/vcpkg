[CmdletBinding()]
param(
    [Parameter(Mandatory=$True)][String]$Port,
    [Parameter(Mandatory=$False)][String]$TagRegex,
    [Parameter(Mandatory=$False)][Switch]$NoDryRun
)

$scriptsDir = split-path -parent $script:MyInvocation.MyCommand.Definition

$portdir = "$scriptsDir/../ports/$Port"
$portfile = "$portdir/portfile.cmake"

$portfile_contents = Get-Content $portfile -Raw

$vcpkg_from_github_invokes = @($portfile_contents | select-string $(@("vcpkg_from_github\([^)]*",
"REPO ([^)\s]+)[^)\S]+",
"REF ([^)\s]+)[^)\S]+",
"[^)]*\)") -join "") | % Matches)

if ($vcpkg_from_github_invokes.Count -eq 0)
{
    Write-Verbose "No matches for vcpkg_from_github(...)"
    return
}

$repo = $vcpkg_from_github_invokes[0].Groups[1].Value
Write-Verbose "repo=$repo"
$oldtag = $vcpkg_from_github_invokes[0].Groups[2].Value
Write-Verbose "oldtag=$oldtag"

try
{
    $newtag = Invoke-WebRequest -Uri "https://api.github.com/repos/$repo/releases/latest" | ConvertFrom-Json | % tag_name
    Write-Verbose "newtag=$newtag"
}
catch [System.Net.WebException]
{
    Write-Verbose "No Releases"
    return
}

if (!$newtag)
{
    Write-Verbose "No Releases"
    return
}

if ($newtag -ne $oldtag)
{
    Write-Verbose "Replacing"
    $filename = $($repo -replace "/","-") + "-$newtag.tar.gz"
    $downloaded_filename = "$scriptsDir/../downloads/$filename"
    Write-Verbose "Archive path is $downloaded_filename"

    if (!(Test-Path "$scriptsDir/../downloads/$filename"))
    {
        Write-Verbose "Downloading"
        Invoke-WebRequest -Uri "https://github.com/$repo/archive/$newtag.tar.gz" -OutFile $downloaded_filename
    }
    $sha = $(cmake -E sha512sum "$downloaded_filename") -replace " .*",""
    Write-Verbose "SHA512=$sha"

    $oldcall = $vcpkg_from_github_invokes[0].Groups[0].Value
    $newcall = $oldcall -replace "REF[\s]+$oldtag","REF $newtag" -replace "SHA512[\s]+[^)\s]+","SHA512 $sha"
    Write-Verbose "oldcall is $oldcall"
    Write-Verbose "newcall is $newcall"
    $new_portfile_contents = $portfile_contents -replace [regex]::escape($oldcall),$newcall

    $libname = $repo -replace ".*/", ""
    Write-Verbose "libname is $libname"

    $newtag_without_v = $newtag -replace "^v([\d])","`$1" -replace "^$libname-",""
    Write-Verbose "processed newtag is $newtag_without_v"

    $oldcontrol = Get-Content "$portdir/CONTROL" -Raw
    $newcontrol = $oldcontrol -replace "\nVersion:[^\n]*","`nVersion: $newtag_without_v"

    if($NoDryRun)
    {
        Set-Content $portfile $new_portfile_contents -encoding Ascii
        Set-Content "$portdir/CONTROL" $newcontrol -encoding Ascii
        "Upgraded $Port from $oldtag to $newtag"
    }
    else
    {
        "# $portdir/CONTROL"
        $newcontrol
        "# $portfile"
        $new_portfile_contents
    }
}
