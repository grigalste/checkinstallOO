# Check post installation and after update ONLYOFFICE Workspace

		Usage: checkinstall.sh [OPTIONS]
		  -h, --help          Display this help and exit;
 		  --color             Color the output;";
		  --checkdb           Check connecthion to MySQL database.

## Example
### Check installation and connecthion to MySQL database:
		bash checkinstall.sh --checkdb --color
### Output in `checkinstall.log` file and disable color the output:
		bash checkinstall.sh --checkdb > checkinstall.log
