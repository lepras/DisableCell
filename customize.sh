#!/system/bin/sh

# Magisk Module Installer variable
REPLACE=""

# Module's folder
LogFolder=/storage/emulated/0/Download

# Alternative path to Internal memory
# LogFolder=/sdcard/Download

# Module's version
MyVersion=v1.5.0


# Log file
LogFile=$LogFolder/SystemlessDebloater.log
PrintLine="Magisk Module Systemless Debloater (REPLACE) $MyVersion"
echo "$PrintLine log file." > $LogFile
echo 'Copyright (c) zgfg @ xda, 2020-2022' >> $LogFile
echo "Installation time: $(date +%c)" >> $LogFile
echo '' >> $LogFile

# Log system info
Prop=$(getprop ro.build.version.release)
PrintLine='Android '$Prop
Prop=$(getprop ro.build.system_root_image)
if [ ! -z "$Prop" ] && [ "$Prop" ]
then
	PrintLine=$PrintLine' SAR'
fi
Prop=$(getprop ro.build.ab_update)
if [ ! -z "$Prop" ] && [ "$Prop" ]
then
	PrintLine=$PrintLine' A/B'
fi
Prop=$(getprop ro.boot.slot_suffix)
if [ ! -z "$Prop" ] && [ "$Prop" ]
then
	PrintLine=$PrintLine" ($Prop)"
fi
echo "$PrintLine"
echo "$PrintLine" >> $LogFile
PrintLine=$(magisk -c)
echo "$PrintLine"
echo "$PrintLine" >> $LogFile
echo '' >> $LogFile

# Default SAR mount-points (SAR partitions to search for debloating)
SarMountPointList="/product /vendor /system_ext /india /my_bigball"

# Default/empty list of app names for debloating and debloated app names 
DebloatList="Dialer messaging TelephonyProvider MmsService"
DebloatedList=""

# Verbose logging 
VerboseLog="true"

# Searching for possible several instances of Stock apps for debloating  
MultiDebloat="true"


# Simple example for DebloatList var for the input file SystemlessDebloaterList.sh:
#DebloatList="EasterEgg CatchLog Traceur wps_lite"

# Input file with a list of app names for debloating
DebloatListFile=$LogFolder/SystemlessDebloaterList.sh
PrintLine="Input debloat list file: $DebloatListFile"												 					  
echo "$PrintLine"
echo "$PrintLine" >> $LogFile
echo '' >> $LogFile

echo "Verbose logging: $VerboseLog" >> $LogFile
echo "Multiple search/debloat: $MultiDebloat" >> $LogFile
echo '' >> $LogFile


# List Stock packages
Packages=$(pm list packages -f | sed 's!^package:!!g')


# Log input SarMountPointList 
echo 'Input SarMountPointList="'"$SarMountPointList"'"' >> $LogFile
echo '' >> $LogFile

# Add /system to SarMountPointList
NewList="/system $SarMountPointList "

# Search through packages to add potential mount points
NewList="$SarMountPointList"$'\n'
for PackageInfo in $Packages
do
	# Extract potential mount point path from PackageInfo
	Path=$(echo "$PackageInfo" | cut -d '/' -f 2)

	# Append to NewList
	NewList="$NewList/$Path"$'\n'
done

# Sort NewList to remove duplicates
NewList=$(echo "$NewList" | sort -bu )

# List not valid paths for (systemless) debloating
BannedList="/data /apex /framework"

# Exclude not valid paths from SarMountPointList
SarMountPointList=""
for Path in $NewList
do
	# Skip not valid paths
	for BannedPath in $BannedList
	do
		if [ "$Path" = "$BannedPath" ]
		then
			Path=""
			break
		fi
	done

	# Append to SarMountPointList
	if [ ! -z "$Path" ]
	then
		SarMountPointList="$SarMountPointList$Path"$'\n'
	fi	
done

# Log final SarMountPointList 
echo 'Final SarMountPointList="'$'\n'"$SarMountPointList"'"' >> $LogFile
echo '' >> $LogFile


# List Stock packages
PackageInfoList=""
for PackageInfo in $Packages
do
	# Include only applications from SAR mount points
	for SarMountPoint in $SarMountPointList
	do		
		if [ -z $(echo "$PackageInfo" | grep '^$SarMountPoint/') ]
		then
			PrepPackageInfo=$PackageInfo

			# Append to the PackageInfoList
			PackageInfoList="$PackageInfoList$PrepPackageInfo"$'\n'
			
			break
		fi
	done
done

# Sort PackageInfoList
PackageInfoList=$(echo "$PackageInfoList" | sort -bu )


# Log input DebloatList 
echo 'Input DebloatList="'"$DebloatList"'"' >> $LogFile
echo '' >> $LogFile

#Search for Stock apps
StockAppList=""
for SarMountPoint in $SarMountPointList
do
	NewList=$(find "$SarMountPoint/" -type f -name "*.apk" 2> /dev/null)

	if [ ! -z "$NewList" ]
	then
		StockAppList="$StockAppList$NewList"$'\n'
	fi
done

# Sort StockAppList
#StockAppList=$(echo "$StockAppList" | sort -bu )


#Search for previously debloated Stock apps
ReplacedAppList=""
for SarMountPoint in $SarMountPointList 
do
	NewList=$(find "$SarMountPoint/" -type f -name ".replace" 2> /dev/null)

	if [ ! -z "$NewList" ]
	then
		ReplacedAppList="$ReplacedAppList$NewList"$'\n'
	fi
done

# Sort ReplacedAppList
#ReplacedAppList=$(echo "$ReplacedAppList" | sort -bu )

# Log ReplacedAppList
echo "Previously debloated Stock apps:"$'\n'"$ReplacedAppList" >> $LogFile


# Prepare service.sh file to debloat Stock but not System apps
ServiceScript="$MODPATH/service.sh"
echo "ServiceScript: $ServiceScript" >> $LogFile
echo '' >> $LogFile

echo '#!/system/bin/sh' > $ServiceScript
echo '' >> $ServiceScript

echo "#Magisk Module Systemless Debloater (REPLACE) $MyVersion" >> $ServiceScript
echo '#Copyright (c) zgfg @ xda, 2020-2022' >> $ServiceScript
echo "#Installation time: $(date +%c)" >> $ServiceScript
echo '' >> $ServiceScript

# Log file for service.sh
echo 'ServiceLogFolder=/data/local/tmp' >> $ServiceScript
echo 'ServiceLogFile=$ServiceLogFolder/SystemlessDebloater-service.log' >> $ServiceScript
echo '' >> $ServiceScript

if [ ! -z "$VerboseLog" ]
then
	echo 'echo "Execution time: $(date +%c)" > $ServiceLogFile' >> $ServiceScript
	echo 'echo "" >> $ServiceLogFile' >> $ServiceScript
else
	echo 'rm $ServiceLogFile' >> $ServiceScript
fi
echo '' >> $ServiceScript

# Module's own folder
MODDIR=$(echo "$MODPATH" | sed "s!/modules_update/!/modules/!")
echo "MODDIR=$MODDIR" >> $ServiceScript
								   

if [ ! -z "$VerboseLog" ]
then	
	echo 'echo "MODDIR: $MODDIR" >> $ServiceLogFile' >> $ServiceScript								
	echo 'echo "" >> $ServiceLogFile' >> $ServiceScript								
	echo '' >> $ServiceScript
fi

# Dummy apk used for debloating
echo 'DummyApk=$MODDIR/dummy.apk' >> $ServiceScript							   
echo 'touch $DummyApk' >> $ServiceScript							   
echo '' >> $ServiceScript

if [ ! -z "$VerboseLog" ]
then
	echo 'echo "DummyApk: $DummyApk" >> $ServiceLogFile' >> $ServiceScript							
	echo 'echo "" >> $ServiceLogFile' >> $ServiceScript							
	echo '' >> $ServiceScript
fi

# Mount and bind for debloating
echo 'MountBind="mount -o bind"' >> $ServiceScript
echo '' >> $ServiceScript

# List of apps to debloat by mounting
MountList=""


# Sort DebloatList
DebloatList=$(echo "$DebloatList" | sort -bu )

# Iterate through apps for debloating
echo 'Debloating:' >> $LogFile
for AppName in $DebloatList
do
	AppFound=""

	#Search through previously debloated Stock apps	
	SearchName=/"$AppName"/.replace
	SearchList=$(echo "$ReplacedAppList" | grep "$SearchName$")
	for FilePath in $SearchList
	do
		# Break if app already found
		if [ -z "$MultiDebloat" ]
		then
			if [ ! -z "$AppFound" ] 
			then
				break					
			fi
		fi
	
		# Remove /filename from the end of the path
		FileName=${FilePath##*/}
		FolderPath=$(echo "$FilePath" | sed "s,/$FileName$,,")
					
		if [ ! -z "FolderPath" ]
		then
			AppFound="true"

			# Log the full path
			echo "found: $FilePath" >> $LogFile
				
			if [ -z $(echo "$FolderPath" | grep '^/system/') ]
			then
				# Append to MountList with appended AppName
				MountList="$MountList$FolderPath/$AppName.apk"$'\n'			
			else
				# Append to REPLACE list
				REPLACE="$REPLACE$FolderPath"$'\n'			
			fi
			
			# Append to DebloatedList
			DebloatedList="$DebloatedList$AppName"$'\n'
		fi
	done

	#Search through Stock apps	
	SearchName=/"$AppName".apk
	SearchList=$(echo "$StockAppList" | grep "$SearchName$")
	for FilePath in $SearchList
	do
		if [ -z "$MultiDebloat" ]
		then
			if [ ! -z "$AppFound" ] 
			then
				break					
			fi
		fi

		# Find the corresponding package
		PackageInfo=$(echo "$PackageInfoList" | grep "$FilePath")
		PackageName=""

		# Extract package name
		if [ ! -z "$PackageInfo" ]
		then
			PackageName=$(echo "$PackageInfo" | sed "s!^$FilePath=!!")
			PackageName="($PackageName) "
		fi
			
		# Remove /filename from the end of the path
		FileName=${FilePath##*/}
		FolderPath=$(echo "$FilePath" | sed "s,/$FileName$,,")
					
		if [ ! -z "FolderPath" ]
		then
			AppFound="true"

			# Log the full path and package name
			echo "found: $FilePath $PackageName" >> $LogFile

			if [ -z $(echo "$FolderPath" | grep '^/system/') ]
			then
				# Append to MountList
				MountList="$MountList$FilePath"$'\n'			
			else
				# Append to REPLACE list
				REPLACE="$REPLACE$FolderPath"$'\n'			
			fi
			
			# Append to DebloatedList
			DebloatedList="$DebloatedList$AppName"$'\n'
		fi
	done
	
	if [ -z "$AppFound" ]
	then
		# Log app name if not found
		PrintLine="$AppName --- app not found!"
		echo "$PrintLine"
		echo "$PrintLine" >> $LogFile
	fi
done
echo '' >> $LogFile

if [ -z "$REPLACE" ]
then
	PrintLine="No app for debloating found!"
	echo "$PrintLine"
	echo "$PrintLine" >> $LogFile
	PrintLine='Before debloating the apps, from Settings/Applications, Uninstall (updates) and Clear Data for them!'
	echo "$PrintLine"
	echo "$PrintLine" >> $LogFile
	echo '' >> $LogFile
fi

# Sort and log DebloatedList
DebloatedList=$(echo "$DebloatedList" | sort -bu )
echo 'DebloatedList="'"$DebloatedList"$'\n"' >> $LogFile
echo '' >> $LogFile

# Sort and log REPLACE list
REPLACE=$(echo "$REPLACE" | sort -bu )
echo 'REPLACE="'"$REPLACE"$'\n"' >> $LogFile
echo '' >> $LogFile

# Sort and log MountList 
MountList=$(echo "$MountList" | sort -bu )
echo 'MountList="'"$MountList"$'\n"' >> $LogFile
echo '' >> $LogFile

# Debloat by mounting in servise.sh
for MountApk in $MountList
do
	PrintLine='$MountBind $DummyApk '"$MountApk"
	echo "$PrintLine" >> $ServiceScript
done


# Log Stock apps and packages
if [ ! -z "$VerboseLog" ]
then
	echo "Stock apps:"$'\n'"$StockAppList" >> $LogFile
	echo "Stock packages: $PackageInfoList" >> $LogFile
fi


# Note for the log file
echo "Systemless Debloater log: $LogFile"
