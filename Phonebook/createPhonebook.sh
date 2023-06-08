#!/bin/sh
# $Author: Daniel HB9HFM $
# $Date: 2023/06/08 11:55:57 $
# $Revision: 1.1 $
# $Source: createPhonebook.sh,v $
# Don't forget to convert the line breaks to Unix mode!

function Help()
{
	echo "Usage: $1 [ -p | --phone -i | --ipdialing]"
	echo "Usage: $1 [ -p | --phone -x | --pbxdialing]"
	exit 2
}

function LOGInformation ()
{
	if [ ${DEBUG:-test} = "true" ]
	then
		/bin/echo "-`/bin/date +%d.%m.%Y-%H:%M:%S`-: $1" | ${LOG}
	fi
}

function PingRemoteHost ()
{
	LOGInformation "_PingRemoteHost"
	LOGInformation "/bin/ping -c 1 -W 1 ${RemoteHostName} &> /dev/null"

	/bin/ping -c 1 -W 1 ${RemoteHostName} &> /dev/null
	case $? in
		"0")	LOGInformation "No problems occurred"
                        ;;
		"1")	LOGInformation "No reply"
			RemoveTempFile
			exit 3
			;;
		"2")	LOGInformation "Other error"
			RemoveTempFile
			exit 3
			;;
		*)	LOGInformation "Unexpected option"
			RemoveTempFile
			exit 3
			;;
	esac
	LOGInformation "_PingRemoteHost Down"
}

function CheckDNSEntry ()
{
	LOGInformation "_CheckDNSEntry"
	LOGInformation "/usr/bin/nslookup -timeout=1 ${RemoteHostName} &> /dev/null"

	/usr/bin/nslookup -timeout=1 ${RemoteHostName} &> /dev/null
	case $? in
		"0")	LOGInformation "No problems occurred"
                        ;;
		"1")	LOGInformation "Query Format Error"
			RemoveTempFile
			exit 3
			;;
		"2")	LOGInformation "Server failed to complete the DNS request"
			RemoveTempFile
			exit 3
			;;
		"3")	LOGInformation "Domain name does not exist"
			RemoveTempFile
			exit 3
			;;
		"4")	LOGInformation " Function not implemented"
			RemoveTempFile
			exit 3
			;;
		"5")	LOGInformation "The server refused to answer for the query"
			RemoveTempFile
			exit 3
			;;
		"6")	LOGInformation "Name that should not exist, does exist"
			RemoveTempFile
			exit 3
			;;
		"7")	LOGInformation "Rset that should not exist, does exist"
			RemoveTempFile
			exit 3
			;;
		"8")	LOGInformation "Server not authoritative for the zone"
			RemoveTempFile
			exit 3
			;;
		"9")	LOGInformation "Name not in zone"
			RemoveTempFile
			exit 3
			;;
		*)	LOGInformation "Unexpected option"
			RemoveTempFile
			exit 3
			;;
	esac
	LOGInformation "_CheckDNSEntry Down"
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
	LOGInformation "_GetCSVFile Down"
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

	LOGInformation "_ConvertCSVFile2XMLFile Down"
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
	LOGInformation "_CheckNeededInformation Down"
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
while [[ $# -ne 3 ]]
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
	*)	echo "Unexpected option: $1"
		Help $0
		;;
	esac
done


# Variables
SIPPort=5060
DomaineName=local.mesh
CSVFileName="hb9hfm.csv"
XMLFileName="hb9hfm.xml"

#RemoteHostName=hb-aredn-srvt01.${DomaineName}
RemoteHostName=localhost.${DomaineName}
RemoteDirectory=phonebook
#RemoteCSVFileName=phonebook.csv
RemoteCSVFileName=phonebook.xml


# Create a temp file for debuging purpose only
if [ ${DEBUG:-test} = "true" ]
then
	LOGFile=`/bin/mktemp /tmp/$0.XXXXXX`
	# If DEBUG= true, Display on stdout and write to the log file at the same time
	LOG="/usr/bin/tee -a ${LOGFile}"
fi

CheckDNSEntry
PingRemoteHost
#GetCSVFile
CheckNeededInformation
ConvertCSVFile2XMLFile

# Delete the created LOG File
RemoveTempFile

# Exit with the state of the listener
# 0 : OK and running
# 1 : Failure
exit 0 
