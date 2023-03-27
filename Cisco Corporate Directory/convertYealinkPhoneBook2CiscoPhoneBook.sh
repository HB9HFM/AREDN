#!/bin/sh
# $Author: Daniel HB9HFM $
# $Date: 2023/03/27 15:55:57 $
# $Revision: 1.1 $
# $Source: convertYealinkPhoneBook2CiscoPhoneBook.sh,v $
# Don't forget to convert the line breaks to Unix mode!

# Le nom du fichier
SourceFileName=phonebook
CiscoFileName=cisco-${SourceFileName}

# Copie le source PhoneBook
cp -p ${SourceFileName}.xml ${CiscoFileName}.xml

# Affiche l'encodage du fichier
file -bi ${CiscoFileName}.xml
# Conversion du fichier
iconv -f iso-8859-1 -t utf-8 ${CiscoFileName}.xml > ${CiscoFileName}-new.xml
mv ${CiscoFileName}-new.xml ${CiscoFileName}.xml

# Enlève les lignes vides, ou celles qui commence par des tabulateurs ou des espaces
sed -i 's/^ *$//g' ${CiscoFileName}.xml
sed -i 's/^\t*$//g' ${CiscoFileName}.xml
sed -i '/^$/d' ${CiscoFileName}.xml

# Remplace le titre du fichier XML
sed -i 's/YealinkIPPhoneDirectory/CiscoIPPhoneDirectory/g' ${CiscoFileName}.xml

# Enlève les tabulateurs et espaces devant la balise <DirectoryEntry>
sed -i 's/^ *<DirectoryEntry>/<DirectoryEntry>/g' ${CiscoFileName}.xml
sed -i 's/^\t *<DirectoryEntry>/<DirectoryEntry>/g' ${CiscoFileName}.xml

# Ajoute un tab devant les occurences suivantes
sed -i 's!^ *</DirectoryEntry>!\t</DirectoryEntry>!g' ${CiscoFileName}.xml
sed -i 's/^ *<Name>/\t<Name>/g' ${CiscoFileName}.xml
sed -i 's/^ *<Telephone>/\t<Telephone>/g' ${CiscoFileName}.xml

# Ajoute le titre et le prompt
if [ -f ${CiscoFileName}_00.patch ]
then
  ed ${CiscoFileName}.xml < ${CiscoFileName}_00.patch 2>&1
fi

# Compte le nombre d'enregistrement
Status=`grep "<DirectoryEntry>" ${CiscoFileName}.xml | wc -l`
echo "_Number of records : ${Status}"
