proj=${PWD##*/} # get project name based on current directory
export proj=${proj%.*} # strip extension (on macs i add .nosync to avoid iCloud sync issues)
