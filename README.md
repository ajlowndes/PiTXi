# PiTXi - Paypal Invoices To Xero Invoices #
(It's actually Paypal _SALES_ To Xero Invoices, but PsTXi doesn't sound as cool)

##Introduction##
Xero has the ability to capture Paypal transactions, treating it more or less like a bank account. But in some cases a LOT of transactions are created every day, and matching invoices are not created in Xero automatically. Compounding the problem, all that ends up in Xero is the name and email of the payee (which might or might not be the name of your customer -e.g. if a parent or friend pays for someone), a transaction number (which Paypal generates and does NOT match any invoice numbers your Point Of Sale system might have generated), date etc. This is often not enough to quickly identify and code the transaction. Paypal does have a lot more info on their system about the transaction though.

So there needs to be a way to collect the extra transaction data from Paypal, transform it into a format that can be imported as Invoices into Xero. Enter PiTXi.

##What it does##
This command line script downloads the latest daily CSV file(s) from from sftp://reports.paypal.com, merges them, and creates a csv that can be imported to Xero as new invoices.

If you have a separate file (lookupvalues.csv) with descriptions and AccountCode, TaxType, TrackingNames, and Tracking Options listed in two columns then PiTXi will enter them into the CSV file for you. Note that at least the TaxTypes must be entered or the upload will fail.

So after the import into Xero, you just need to go to your Paypal bank account, click on the "reconcile" tab and click "OK" to confirm each payment matches up with the correct uploaded invoice. Much faster than manually coding hundreds/thousands of transactions!

##Requirements##
* This is a shell script, and I'm running on OSX, though it will likely work on all UNIX systems
* Must have signed up for sftp access from Paypal. Basically involves sending an email to paypal - [see this link for more info](https://www.paypalobjects.com/webstatic/en_US/developer/docs/pdf/PP_LRD_SecureFTP.pdf)
* Must create a sftp access username and password, and set your "Transactions detail" reports to be delivered as CSV via Secure FTP (Paypal > Reports > Transactions > Transactions detail > Manage Subscription)
* Test your sftp credentials with `sftp username@reports.paypal.com:/ppreports/outgoing`. You should be able to log in and see the daily csv files there (`ls -1`). If you only just signed up there won't be any there until tomorrow.


##Dependencies##
csvfix from http://neilb.bitbucket.org/csvfix/. Can be installed via homebrew (`brew install csv-fix`) or [here are some instructions for linux](http://www.interesting2me.com/install-csvfix-ubuntu/)

##Installation##
Download PiTXi to a folder on your machine. The only required file is pitxi.sh. The lookupvalues.csv file is an example only - it shows you what you would enter - the Paypal description on the left, the account code on the right.

Open up a shell prompt and navigate to your folder. Run `chmod u+x pitxi.sh` to make it executable.

##Usage##
```
./pitxi.sh [-d -u -v -t -a -h] {one option only}
  -d  download missing files from Paypal, store them in /PPLCSVfiles
  -u  download using a new sftp username/password
  -v  validate against lookupvalues.csv and report any missing ones
  -t  export output file. must have run -d first
  -a  same as d + v + t together.
  -h  display this help text.
```

##Recommended workflow##
Once you've set up PiTXi for the first time and have your sftp credentials, here's what I would do:

1.  Wait a day for the first CSV file to show up in the sftp server. Sorry that's a Paypal thing.

2.  Once it's there, open up a shell prompt and navigate to your folder. Run `./pitxi.sh -d` which will connect to the sftp server, collect a list of files and download them all to a new folder called "PPLCSVFiles". In future if you run this command it will only download new files.

3.  The list of files that have been downloaded is in a file called "newfiles.txt". That list defines what will be combined later.

4.  Run `./pitxi.sh -v`. This will spit out a list of descriptions that couldn't be found in lookupvalues.csv, if it exists. You can update this file, adding any new data by opening it (`open lookupvalues.csv`)

5.  Run `./pitxi.sh -t`. This will create a new file called "importToXero[DATE].csv". You are welcome to run this again and again until all of the AccountCodes and extra data are there, or you are happy with the ones that are missing (note: the TaxType column must be entered or your upload will fail)

6.  Log into Xero, go to "Invoices" and click the "Import" button. There you can upload the csv file. The invoices will be imported as drafts, which you can probably "Select All" and "Approve".

7.  Now you should be able to go back to your Paypal account in Xero and click the "Reconcile" tab. There you will find that most of the transactions have matching invoices, all ready for you to click "OK". Make sure you check the match carefully before you click "OK"!

##Where it won't work for you##
Unfortunately Paypal's sftp service only allows transaction level reporting - that means that "Shopping Cart" items are not detailed in separate lines. So in other words, a proper description (and proper coding to your AccountCodes) will only show up if the payment was being made for just one item, not a shopping cart of them. If you have many "Shopping Cart" transactions, perhaps check out Zapier's [Create new Xero invoices for new PayPal sales](https://zapier.com/zapbook/zaps/2122/create-new-xero-invoices-for-new-paypal-sales/) instead as it has a different way of doing this.

##Disclaimer##
I take no responsibility if you mess things up using this tool, I wrote it for my workflow and it works for me. Fiddle with the CSV file before you upload, check the draft invoices in Xero before you approve them etc.
