# PiTXi - Paypal Invoices To Xero Invoices #
(It's actually Paypal _PAYMENTS_ To Xero Invoices, but PpTXi doesn't sound as cool)

This script downloads the latest payments CSV(s) from from sftp://reports.paypal.com, merges them, and creates a csv that can be uploaded to Xero as new invoices.

If you have account codes listed in two columns in a separate file (accountcodes.csv) then it will enter them into the CSV file for you. No more coding hundreds of transactions!
```Usage : ./$bname [-d -v -t | -h] {one option only}
  -d  download missing files from Paypal, store them in /PPLCSVfiles
  -u  download using a new sftp username/password
  -v  validate against accountcodes.csv and report any missing ones
  -t  export output file. must have run -d first
  -h  display this help text.```