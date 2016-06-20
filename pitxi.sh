#!/bin/sh

bname=`basename $0`
usage () #usage instructions
{
  cat <<EOF

  PiTXi - Paypal Invoices To Xero Invoices
  (It's actually Paypal SALES To Xero Invoices, but PsTXi doesn't sound as cool)

  Downloads latest payments CSV from from sftp://reports.paypal.com,
  merges them and creates a csv that can be uploaded to Xero as new invoices.

  Usage : ./$bname [-d -v -t | -h] {one option only}
    -d  download missing files from Paypal, store them in /PPLCSVfiles
    -u  download using a new sftp username/password
    -v  validate against accountcodes.csv and report any missing ones
    -t  export output file. must have run -d first
    -h  display this help text.

EOF
  exit 0
}

dl () # connects to sftp://reports.paypal.com, downloads any missing files to /PPLCSVFiles
{
  if [ ! -d PPLCSVFiles ]; then
    read -p "The PPLCSVFiles directory doesn't exist. This means the last 45 days of transactions will be downloaded. Are you happy with this?
y/n " yn
    while true; do
      case $yn in
        [Yy]* )
          echo "Okay, creating the folder. Feel free to edit missingfiles.txt to determine which files will be combined when you run ./"$bname" -d"
          mkdir PPLCSVFiles
          break
          ;;
        [Nn]* )
          echo "Aborting."
          exit 1
          ;;
        * ) echo "Please answer yes or no.
y/n ";;
      esac
    done
  fi
  security find-generic-password -s paypalsftp >/dev/null 2>/dev/null #test if entry exists in osx keychain
  if [ $? -ne 0 ] || [ "$1" == "useNewCredentials" ]; then
    echo "Please enter username for sftp://reports.paypal.com"
    read username
    echo $username > .credentials_tmp
    read -p "Password:" -s pass
    echo $pass >> .credentials_tmp
  else
    echo `security find-generic-password -s paypalsftp | grep "acct" | cut -d \" -f 4` > .credentials_tmp
    echo `security find-generic-password -s paypalsftp -w` >> .credentials_tmp
  fi
  echo "
Connecting to Paypal and downloading missing files
	"
	expect << 'EOS'
  log_user 0
	set send_human {.1 .3 1 .05 2}
	spawn sftp [exec sed "1p;d" .credentials_tmp]@reports.paypal.com:/ppreports/outgoing
  expect "password:"
	send "[exec sed "2p;d" .credentials_tmp]\n"
  expect {
    "sftp>" {
    # exp_continue
    } timeout {
    send_user "
  *** Connection timed out. Check connection and verify the username/password"; exit 1
    }
  }
  puts "Getting Remote File List"
  log_file -noappend .RemoteFileList.txt
  send -h "ls -1\n"
	expect "sftp>"
  log_file
	system sed -i '' '/ls -1/d' ./.RemoteFileList.txt
	system sed -i '' '/sftp>/d' ./.RemoteFileList.txt
	system ls -1 PPLCSVFiles/ > .LocalFileList.txt
  puts "Comparing with files in /PPLCSVFiles"
	sleep 1
  set rc [catch {exec diff -aw --changed-group-format=%< --unchanged-group-format= .RemoteFileList.txt .LocalFileList.txt} output]
  if {$rc == 0} {
    puts "no difference"
  } else {
    if {[lindex $::errorCode 0] eq "CHILDSTATUS"} {
      if {[lindex $::errorCode 2] == 1} {
        # send output without "child process exited abnormally" message
        set filename "missingfiles.txt"
        set fileId [open $filename "w"]
        puts -nonewline $fileId [string replace $output end-31 end ""]
        close $fileId
      } else {
        puts "diff error: $output"
      }
    } else {
      puts "error calling diff: $output"
    }
  }
  sleep 1
  if {[file size missingfiles.txt] == 0} {
    sleep 1
    send "bye\n"
    puts "
There are no new files on the Paypal server."
    interact
  } else {
		set f [open "missingfiles.txt"]
		while {[gets $f line] != -1} {
			send "get $line PPLCSVFiles/$line\n"
			expect "sftp>"
	}
	close $f
	send "bye\r"
	puts "
Missing Files have been downloaded, the list is stored in missingfiles.txt."
	}
EOS
security find-generic-password -s paypalsftp >/dev/null 2>/dev/null #test if entry exists in osx keychain
if [ $? -ne 0 ] || [ "$1" == "useNewCredentials" ]; then
  while true; do
  read -p "
Do you want to save these login details for next time?
y/n " yn
    case $yn in
      [Yy]* )
        security add-generic-password -s paypalsftp -a `sed '1p;d' .credentials_tmp` -w `sed '2p;d' .credentials_tmp` -U
        rm -f .credentials_tmp
        echo "new credentials saved."
        break
        ;;
      [Nn]* )
        rm -f .credentials_tmp
        exit 1
        ;;
      * ) echo "Please answer yes or no.
y/n ";;
    esac
  done
fi
rm -f .credentials_tmp
}

vl () #Validates the paypal data against Account Codes in a separate file (kind of like a vlookup).
{
	#test for existence of the PPLCSVFiles folder
  if [ ! -d PPLCSVFiles ]; then
    echo "the folder PPLCSVFiles doesn't exist. run ./"$bname" -d first"
    exit 1
  fi
  #test for existence of .val_AccountCodes.txt, create it if not there.
	if [ ! -f .val_AccountCodes.txt ]; then
		echo "# .val_AccountCodes.txt
required    23
lookup      *      23:1  ../accountcodes.csv" > .val_AccountCodes.txt
	fi
	#test for existence of accountcodes.txt
	if [ ! -f accountcodes.csv ]; then
		echo "accountcodes.csv missing. Nothing to validate against!
		"
		exit 1
	fi
	#test for existence of missingfiles.txt.
	if [ ! -f missingfiles.txt ]; then
		echo "missingfiles.txt not there. Run ./"$bname" -d first.
		"
		exit 1
	fi
	b=$(tr -s '\r\n' " " <missingfiles.txt)
	if test "$b" != ''; then
    echo "Checking new data against the 'PaypalItemName' column in accountcodes.txt. These items are missing from that column:
    "
    cd PPLCSVFiles/
  	csvfix unique $b |
  	csvfix remove -fc 0:6 |
  	csvfix validate -vf ../.val_AccountCodes.txt -ec -ifn |
  	grep "lookup of '" |
    #sed 's/.{10}//;s/.{27}$//'
    sed -l "s/lookup of '//;s/' in ..\/accountcodes.csv failed//"
  	cd ..
  	echo "
You need to add the missing account data above (if any) to accountcodes.csv. Then run ./"$bname" -t"
  else
    echo "There were no new files on the Paypal server. Check again with ./"$bname" -d"
  fi
  rm -f .val_AccountCodes
}

tl () #performs the merging and conversion from paypal csv files into to a file that can be uploaded to Xero.
{
	#test for existence of accountcodes.txt
	if [ ! -f accountcodes.csv ]; then
  		while true; do
	  		read -p "accountcodes.csv missing. Run anyway?
y/n " yn
	     	case $yn in
	  	    [Yy]* )
					   touch accountcodes.csv
					   echo "Warning: the AccountCodes column will be empty.
					   "
					  break
					  ;;
				  [Nn]* )
					  exit 1
					;;
				* ) echo "Please answer yes or no.
y/n ";;
			esac
		done
	fi
	#test for existence of missingfiles.txt.
	if [ ! -f missingfiles.txt ]; then
  		echo "missingfiles.txt not there. Run ./"$bname" -d first.
  		"
  		exit 1
	fi
  b=$(tr -s '\r\n' " " <missingfiles.txt)
  if test "$b" != ''; then
  	cd PPLCSVFiles/
  	csvfix unique $b |
  	csvfix remove -fc 0:6 |
  	csvfix trim -f 7,8 -w 10,10 |
  	csvfix date_iso -f 7,8 -m 'y/m/d' |
  	csvfix date_format -f 7,8 -fmt 'dd/mm/yyyy' |
  	csvfix edit -e s/^0*// -f 3 |
  	csvfix merge -f 2,3 -s " | " -p 2 -k |
  	csvfix eval -r 11,'($11)/100' -ifn |
  	csvfix eval -if 'match($10,"DR")' -r '11,-$11' -r '11,$11' |
    csvfix put -p 71 -v "1" |
  	csvfix join -f 24:1 -oj - ../accountcodes.csv |
  	csvfix order -f 50,22,33,34,79,79,35:38,4,2,8,9,78,24,71,11,79,72:77,12,79 -hdr "*ContactName,EmailAddress,POAddressLine1,POAddressLine2,POAddressLine3,POAddressLine4,POCity,PORegion,POPostalCode,POCountry,*InvoiceNumber,Reference,*InvoiceDate,*DueDate,InventoryItemCode,*Description,*Quantity,*UnitAmount,Discount,*AccountCode,*TaxType,TrackingName1,TrackingOption1,TrackingName2,TrackingOption2,Currency,BrandingTheme" -o ../importToXero$(date +%F).csv
  	cd ..

  	echo "A file named 'importToXero"$(date +%F)".csv' has been created, this can be uploaded to Xero.
Note that some transactions will require manual feeding - such as 'Shopping Cart' lines.
    "
  else
    echo "There were no new files on the Paypal server. Check again with ./"$bname" -d"
  fi
}

# From here down is all to do with handling the flags you type into the command line, after the name of the script.
if [ ! $# == 1 ] || [ "$1" = "-h" ] || [ "$1" = "-" ]
then
	usage
fi

while getopts ":dvtau" opt; do
  case $opt in
    d)
	  dl
      exit 0
      ;;
    v)
	  vl
      exit 0
      ;;
    t)
	  tl
      exit 0
      ;;
    u)
      dl useNewCredentials
      exit 0
      ;;
    a)
      echo "Downloading, validating (simply for the excercise) and creating the file
	  "
	  dl
    vl
	  tl
	  echo "Beware of the missing AccountCodes - these need to be added to a separate file called 'AccountCodes.csv' for this program to work in future.
	  "
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG
      type ./"$bname" -h for help
      " >&2
      exit 1
      ;;

  esac
done