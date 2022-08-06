# Check post installation and after update ONLYOFFICE Workspace

		Usage: checkinstall.sh [OPTIONS]
		  -h, --help          Display this help and exit;
		  --checkdb           Check connecthion to MySQL database;
		  --nocolor           Do not color the output.
## Example
### Check installation and connecthion to MySQL database:
		bash checkinstall.sh --checkdb 
### Output in `checkinstall.log` file and disable color the output:
		bash checkinstall.sh --checkdb --nocolor > checkinstall.log
