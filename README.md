# localize-cs
This program (originally designed for my CS246 class at UWaterloo) is intended for maintaining and syncing a local version of a remote environment.

## Setup
This program uses ssh and scp quite a bit, so you may want to set up an ssh key so that you don't have to type in your password repeatedly. Instructions can be found here: https://cs.uwaterloo.ca/cscf/howto/ssh/public_key/. Note that if you choose to not use a password you are sacrificing security for convenience. 

To get setup, first create a folder on your local machine where you want to store all the files in. This folder will be referred to as your local cshome.

`localize.sh` is not an executable, but rather is to be used by exectuables that you create. You should create one executable for each folder that you want to localize. In the executable you must define values for `LCL_USERNAME`, `LCL_LOCALHOME`, `LCL_REMOTEHOME` and `LCL_SERVER` and then add `localize.sh` as a source. Check the `example` folder for a demonstration.

Finally, I recommend moving the executable files to somewhere in your path for ease of execution.


## How to use
### Syntax

All paths provided to this program should be relative to your local and remote lclhome.
For example if your cshome is set up at `~/CS246Remote/` on your local and `~/cs246/1189/` on the remote environment, then to push `~/CS246Remote/a1/tests/` to the remote, run `cs246 push ./a1/tests/`.



## Commands

To describe the use of commands, we are going to assume that you have created an executable called `cs246` and placed it in your path, the file should look similar to `example/cs246`

### exec

**Usage:** `cs246 exec ['option'] 'commands'`
If you are going to run multiple commands, put the commands in quotes so that the semicolon does not end the cs246 command. For example, `cs246 exec "ls; pwd"` instead of `cs246 exec ls; pwd`.

**Description:** Runs commands on the remote environment. Note that the command will be run from your remote cshome directory. Currently globbing patterns are not supported in the commands.

**Options:**	

​	**`-o, --open`**		Keeps the connection to the server open after running the commands.

​	**`-c, --close`**		Closes the connection to the server after running the commands (default behaviour).


### connect

**Usage:** `cs246 connect`

**Description:** Connects to the remote server via ssh.


### get

**Usage:** `cs246 get 'value'`

**Description:** Returns values that you set in the file.

**Values:**

​	**`local_home, lh`**		the path of your local cshome

​	**`remote_home, rh`**	  the path of your remote cshome

​	**`username, usr, u`**	your username used for connecting to the server

​	**`server, svr, s`**		the server that gets connected to (e.g. `linux.student.cs.uwaterloo.ca`)

​	**`connection, c`**			the ssh connection in the form `username@server`


### push

**Usage:** `cs246 push ['path' ...]`

**Description:** Copies all specified files and folders from remote cshome to local cshome. If you do not specify any file paths, the entire local cshome will be pushed. It will not delete files on the remote if you have deleted them on local. File paths must be relative to cshome.


### pull

**Usage:** `cs246 pull ['path' ...]`

**Description:** Copies all specified files and folders from the remote cshome to your local cshome. If you do not specify any file paths, the entire remote cshome will be pulled. It will not delete files on your local if you have deleted them on the remote. File paths must be relative to cshome.


### diff

**Usage:** `cs246 diff`

**Description:** Produces an output describing the difference between the local and remote cshomes. `l: file` denotes that the file only exists locally, `r: file` denotes that the file only exists remotely, and `d: file` denotes that the files differ between the local and remote.


### sync

**Usage:** `cs246 sync`

**Description:** Allows user to sync files that differ between the remote and local. You will be prompted to either take the remote (r) version, take the local version (l), or ignore the difference (i).

**Note:** Currently this command is a buggy and has trouble working with directories.
