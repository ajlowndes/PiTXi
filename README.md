[h1] PiTXi - Paypal Invoices To Xero Invoices
(It's actually Paypal PAYMENTS To Xero Invoices, but PpTXi doesn't sound as cool)

Downloads latest payments CSV from from sftp://reports.paypal.com,
merges them and creates a csv that can be uploaded to Xero as new invoices.

Usage : ./$bname [-d -v -t | -h] {one option only}
  -d  download missing files from Paypal, store them in /PPLCSVfiles
  -u  download using a new sftp username/password
  -v  validate against accountcodes.csv and report any missing ones
  -t  export output file. must have run -d first
  -h  display this help text.
