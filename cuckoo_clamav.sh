#!bin/bash

FILE_NAME=$1

# Check if file is exist or not
if [ ! -f $FILE_NAME ]; then
	echo "File $(FILE_NAME) not exist."
	echo "Exit."
	exit 1
fi

echo "-------- ANALYZING --------"
# Submit file to cuckoo
cuckoo submit $FILE_NAME

# Waiting for cuckoo to create folder "latest"
inotifywait -e create --exclude "[^s][^t]$" /home/ubuntu/.cuckoo/storage/analyses
echo "-------- ANALYSIS RESULT --------"
SCORE=$(jq .info.score ~/.cuckoo/storage/analyses/latest/reports/report.json)
echo "Score: " $SCORE
if [ "'echo "${SCORE} > 4.0" | bc'" -eq 1 ]; then
	cat signature.hdb > signature0.hdb
	# Use sigtool to generate md5 hash of a file and add it to new database
	sigtool --md5 $FILE_NAME >> signature0.hdb
	echo "-------- SIGNATURES --------"
	uniq signature0.hdb signature.hdb
	rm signature0.hdb
	cat signature.hdb
	echo "-------- SCANNING & REMOVING --------"
	# Use clamscan to scan and remove file if it's a malware
	clamscan -r -i --remove -d ~/Demo/signature.hdb /home/ubuntu
else
	echo "This file is safe"
fi

exit 0