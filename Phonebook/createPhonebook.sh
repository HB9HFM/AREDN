#!/bin/sh
# $Author: Daniel HB9HFM $
# $Date: 2023/03/23 11:55:57 $
# $Revision: 1.1 $
# $Source: createPhonebook.sh,v $
# Don't forget to convert the line breaks to Unix mode!

function Help()
{
	echo "Usage: $1 [ -v | --verbose ]"
	exit 2
}

function LOGInformation ()
{
	if [ ${DEBUG:-test} = "true" ]
	then
		/bin/echo "-`/bin/date +%d.%m.%Y-%H:%M:%S`-: $1" | ${LOG}
	fi
}

function GetCSVFile ()
{
	LOGInformation "_GetCSVFile"

	LOGInformation "wget --timeout=1 -q -4 -P ${HOME} -O test.del http://${RemoteHostName}/${RemoteDirectory}/${RemoteCSVFileName}"
	wget --timeout=1 -q -4 -P ${HOME} -O test.del http://${RemoteHostName}/${RemoteDirectory}/${RemoteCSVFileName}

	case $? in
		"0")	LOGInformation "No problems occurred"
			;;
		"1")	LOGInformation "Generic error code"
			RemoveTempFile
			exit 3
			;;
		"2")	LOGInformation "Parse error — for instance, when parsing command-line options, the .wgetrc or .netrc…"
			RemoveTempFile
			exit 3
			;;
		"3")	LOGInformation "File I/O error"
			RemoveTempFile
			exit 3
			;;
		"4")	LOGInformation "Network failure"
			RemoveTempFile
			exit 3
			;;
		"5")	LOGInformation "SSL verification failure"
			RemoveTempFile
			exit 3
			;;
		"6")	LOGInformation "Username/password authentication failure"
			RemoveTempFile
			exit 3
			;;
		"7")	LOGInformation "Protocol errors"
			RemoveTempFile
			exit 3
			;;
		"8")	LOGInformation "Server issued an error response"
			RemoveTempFile
			exit 3
			;;
	esac			

#	if [ ! -s "${FILENAME}" ]
	if [ ! -s "test.del" ]
	then
		LOGInformation "File is empty"
	else
		LOGInformation "File is not empty"
	fi
}


function ConvertCSVFile2XMLFile()
{
	LOGInformation "_ConvertCSVFile2XMLFile"

	case ${PhoneName} in
		"cisco") XMLTitle="CiscoIPPhoneDirectory"
			LOGInformation "Cisco Phone detected"
			;;
		"yealink") XMLTitle="YealinkIPPhoneDirectory"
			LOGInformation "Yealink Phone detected"
			;;
		"*") XMLTitle="XXXXXIPPhoneDirectory"
			LOGInformation "Unknow Phone"
			;;
	esac

	echo "<${XMLTitle}>" > ${XMLFileName}
	echo -e '\t<Title>AREDN Swiss Phone Directory</Title>' >> ${XMLFileName}
	echo -e '\t<Prompt>Select the User</Prompt>' >> ${XMLFileName}


	sed 1d ${CSVFileName} | while IFS=$',' read -r CSVLine
	do
		echo -e '<DirectoryEntry>' >> ${XMLFileName}
		echo -e '\t<Name>'$(printf "${CSVLine}" | awk -F',' {'print$1'})'</Name>' >> ${XMLFileName}

		if [ ${PBXDialing:-test} = "true" ]
		then
			echo -e '\t<Telephone>'$(printf "${CSVLine}" | awk -F',' {'print$2'})'</Telephone>' >> ${XMLFileName}
		fi

		if [ ${IPDialing:-test} = "true" ]
		then
			echo -e '\t<Telephone>'$(printf "${CSVLine}" | awk -F',' {'print$3'})'</Telephone>' >> ${XMLFileName}
		fi

		echo -e '</DirectoryEntry>' >> ${XMLFileName}
	done

	echo "</${XMLTitle}>" >> ${XMLFileName}
}

function CheckNeededInformation ()
{

	LOGInformation "_CheckNeededInformation"

	if [ ! -f ${CSVFileName} ]
	then
		LOGInformation "${CSVFileName} is missing"
		exit -2
	else
		LOGInformation "${CSVFileName} was found :-)"
	fi
}

function RemoveTempFile ()
{
	if [ ${DEBUG:-test} = "true" ]
	then
		if [ -f ${LOGFile} ]
		then
			rm -f ${LOGFile}
		fi
	fi

	if [ -f ${HOME}/${RemoteCSVFileName} ]
	then
		rm -f ${HOME}/${RemoteCSVFileName}
	fi
}


# Turn debuging information on or off
DEBUG=false
DEBUG=true

# Parse command line arguments
while [[ $# -gt 0 ]]
do
	case "$1" in
	-p | --phone )
		PhoneName=`echo "$2" | tr '[A-Z]' '[a-z]'`
		shift
		shift
		;;
	-i | --ipdialing)
		IPDialing="true"
		shift
		;;
	-x | --pbxdialing)
		PBXDialing="true"
		shift
		;;
	-h | --help)
		Help $0
		;;
	*)
		echo "Unexpected option: $1"
		Help $0
		;;
	esac
done


# Variables
SIPPort=5060
DomaineName=local.mesh
CSVFileName="hb9hfm.csv"
XMLFileName="hb9hfm.xml"

RemoteHostName=hb-aredn-srvt01.${DomaineName}
RemoteDirectory=phonebook
RemoteCSVFileName=phonebook.xml


# Create a temp file for debuging purpose only
if [ ${DEBUG:-test} = "true" ]
then
	LOGFile=`/bin/mktemp /tmp/$0.XXXXXX`
	# If DEBUG= true, Display on stdout and write to the log file at the same time
	LOG="/usr/bin/tee -a ${LOGFile}"
fi

GetCSVFile
CheckNeededInformation
ConvertCSVFile2XMLFile

# Delete the created LOG File
RemoveTempFile

# Exit with the state of the listener
# 0 : OK and running
# 1 : Failure
exit 0 
