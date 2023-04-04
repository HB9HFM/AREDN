#!/bin/sh
# $Author: Daniel HB9HFM $
# $Date: 2023/03/23 11:55:57 $
# $Revision: 1.1 $
# $Source: checkTFTPService.sh,v $
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


function ConvertCSVFile2XMLFile()
{
	LOGInformation "Add the TFTP needed configuration in ${TFTPConfigFile} for DNSMasq"
	echo '<YealinkIPPhoneDirectory>' > ${XMLFileName}

	while IFS=$',' read -r CSVLine
	do
		echo -e '\t<DirectoryEntry>' >> ${XMLFileName}
		echo -e '\t\t<Name>'$(printf "${CSVLine}" | awk -F',' {'print$1'})'</Name>' >> ${XMLFileName}
		echo -e '\t\t<Telephone>'$(printf "${CSVLine}" | awk -F',' {'print$2'})'</Telephone>' >> ${XMLFileName}
		echo -e '\t\t<TelephoneIP>'$(printf "${CSVLine}" | awk -F',' {'print$3'})'</TelephoneIP>' >> ${XMLFileName}
		echo -e '\t</DirectoryEntry>' >> ${XMLFileName}
done < ${CSVFileName}

echo '</YealinkIPPhoneDirectory>' >> ${XMLFileName}


}

function RemoveTempFile ()
{
	if [ ${DEBUG:-test} = "true" ]
	then
		rm -f ${LOGFile}
	fi
}


# Turn debuging information on or off
DEBUG=false

# Parse command line arguments
while [[ $# -gt 0 ]]
do
	case "$1" in
	--phone )
		PhoneName=`echo "$2" | tr [:upper:] [:lower:] | sed 's/.*/\u&/')`
		shift
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

# Create a temp file for debuging purpose only
if [ ${DEBUG:-test} = "true" ]
then
	LOGFile=`/bin/mktemp /tmp/$0.XXXXXX`
	# If DEBUG= true, Display on stdout and write to the log file at the same time
	LOG="/usr/bin/tee -a ${LOGFile}"
fi



# Delete the created LOG File
RemoveTempFile

# Exit with the state of the listener
# 0 : OK and running
# 1 : Failure
exit ${myStatusTFTPPort}
