# PiTXi - Paypal Income To Xero Invoices #

##Introduction##
Xero has the ability to capture Paypal transactions, treating it more or less like a bank account. But in some cases a LOT of transactions are created every day, and matching invoices are not created in Xero automatically. Compounding the problem, all that ends up in Xero is the name and email of the payee (which might or might not be the name of your customer -e.g. if a parent or friend pays for someone), a transaction number (which Paypal generates and does NOT match any invoice numbers your Point Of Sale system might have generated), date etc. This is often not enough to quickly identify and code the transaction. Paypal does have a lot more info on their system about the transaction though - and in my case Paypal's `ItemName` field has a description like _Registration for 'Oceania and National Lead and Speed Climbing Championships' (17 Jun 2016 4:00 PM - 19 Jun 2016 4:00 PM, Sydne_ and this tells me everything I need to know about what `AccountCode` to apply in Xero, what `TaxType` to apply, what `TrackingName` and `TrackingOption`(s) to apply, and what `InventoryItemCode` to apply (if applicable).

So there needs to be a way to collect the extra transaction data from Paypal, and transform it into a format that can be imported as Invoices into Xero. 
Enter PiTXi.

##What it does##
This script downloads the latest daily CSV file(s) from from sftp://reports.paypal.com, merges them, and creates a csv that can be imported to Xero as new invoices.

If you have a separate file (lookupvalues.csv) with descriptions and AccountCode, TaxType, TrackingNames and TrackingOptions and InventoryItem Code listed in additional columns, then PiTXi will look them up and enter them into the output file for you.

So after the import into Xero, you just need to go to your Paypal bank account, click on the "reconcile" tab and click "OK" to confirm each payment matches up with the correct uploaded invoice. Much faster than manually coding hundreds/thousands of transactions!

##Requirements##
* This is a shell script, and I'm running on OSX, though it will likely work on all UNIX systems
* Must have signed up for sftp access from Paypal. Basically involves sending an email to paypal - [see this link for more info](https://www.paypalobjects.com/webstatic/en_US/developer/docs/pdf/PP_LRD_SecureFTP.pdf)
* Must create a sftp access username and password, and set your "Transactions detail" reports to be delivered as CSV via Secure FTP (Paypal > Reports > Transactions > Transactions detail > Manage Subscription)
* Test your sftp credentials with `$ sftp username@reports.paypal.com:/ppreports/outgoing`. You should be able to log in and see the daily csv files there (`$ ls -1`). If you only just signed up there won't be any there until tomorrow.

##Installation##
#####Via Homebrew#####
simply `$ brew tap ajlowndes/tap`, then
`$ brew install pitxi`

#####Manual Installation#####
Download PiTXi to a folder on your machine. The only required file is pitxi.
Open up a shell prompt and navigate to your folder. Run `$ chmod u+x pitxi` to make it executable. From here on out you'll need to prepend pitxi with a `./` to make it work (i.e. `./pitxi -d`)
Make sure you have this dependency also installed:
csvfix from http://neilb.bitbucket.org/csvfix/. [Here are some instructions for linux](http://www.interesting2me.com/install-csvfix-ubuntu/)


##Usage##
```
pitxi [-d -u -v -t -a -h] {one option only}
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

2.  Once it's there, open up a shell prompt and navigate to your folder. Run `$ pitxi -d` which will connect to the sftp server, collect a list of files and download them all to a new folder called "PPLCSVFiles". In future if you run this command it will only download new files.

3.  The list of files that have been recently downloaded is in a file called "newfiles.txt". That list defines what will be combined later.

4.  Run `$ pitxi -v`. This will spit out a list of `ItemNames` that couldn't be found in lookupvalues.csv. If the file doesn't exist, PiTXi will create it for you - so you can then run `$ open lookupvalues.csv`

5.  Run `$ pitxi -t`. This will create a new file called "importToXero[DATE].csv". You are welcome to run this again and again until all of the AccountCodes and extra data are there, or you are happy with the ones that are missing (note: if you enter an AccountCode then the TaxType column must also be filled or your upload will fail - that's Xero's requirement)

6.  Log into Xero, go to "Invoices" and click the "Import" button. There you can upload the csv file. The invoices will be imported as drafts, which you can probably "Select All" and "Approve".

7.  Now you should be able to go back to your Paypal account in Xero and click the "Reconcile" tab. There you will find that most of the transactions have matching invoices, all ready for you to click "OK". Make sure you check the match carefully before you click "OK"!

##Where it won't work for you##
Unfortunately Paypal's sftp service only allows transaction level reporting - that means that "Shopping Cart" items are not detailed in separate lines. So in other words, a proper description (and proper coding to your AccountCodes) will only show up if the payment was being made for just one item, not a shopping cart of them. If you have many "Shopping Cart" transactions, perhaps check out Zapier's [Create new Xero invoices for new PayPal sales](https://zapier.com/zapbook/zaps/2122/create-new-xero-invoices-for-new-paypal-sales/) instead as it has a different way of doing this.

##Disclaimer##
I take no responsibility if you mess things up using this tool, I wrote it for my workflow and it works for me. Fiddle with the CSV file before you upload, check the draft invoices in Xero before you approve them etc.
