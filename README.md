# localize-cs
This program (originally designed for my CS246 class at UWaterloo) is intended for maintaining and syncing a local version of a remote environment.

## Setup
This program uses ssh and scp quite a bit, so you may want to set up an ssh key so that you don't have to type in your password repeatedly. Instructions can be found here: https://cs.uwaterloo.ca/cscf/howto/ssh/public_key/. Note that if you choose to not use a password you are sacrificing security for convenience. 

To get setup, first create a folder on your local machine where you want to store all the files in. This folder will be referred to as your local cshome.

Next, clone or download the repo and change the values of `CS246_USERNAME`, `CS246_LOCALCSHOME` and `CS246_REMOTECSHOME` in the cs246 file.

Finally, I recommend moving the file to somewhere that is in your path for ease of execution.


## How to use
### Syntax

All paths provided to this program should be relative to your local and remote cshome.
For example if your cshome is set up at `~/CS246Remote/` on your local and `~/cs246/1189/` on the remote environment, then to push `~/CS246Remote/a1/tests/` to the remote, run `cs246 push ./a1/tests/`.



## Commands

### cs246 exec

**Usage:** `cs246 exec ['option'] 'commands'`
If you are going to run multiple commands, put the commands in quotes so that the semicolon does not end the cs246 command. For example, `cs246 exec "ls; pwd"` instead of `cs246 exec ls; pwd`.

**Description:** Runs commands on the remote environment. Note that the command will be run from your remote cshome directory. Currently globbing patterns are not supported in the commands.

**Options:**	

​	**`-o, --open`**		Keeps the connection to the server open after running the commands.

​	**`-c, --close`**		Closes the connection to the server after running the commands (default behaviour).


### cs246 connect

**Usage:** `cs246 connect`

**Description:** Connects to the remote server via ssh.


### cs246 get

**Usage:** `cs246 get 'value'`

**Description:** Returns values that you set in the file.

**Values:**

​	**`local_home, lh`**		the path of your local cshome

​	**`remote_home, rh`**	  the path of your remote cshome

​	**`username, usr, u`**	your username used for connecting to the server

​	**`server, svr, s`**		the server that gets connected to (e.g. `linux.student.cs.uwaterloo.ca`)

​	**`connection, c`**			the ssh connection in the form `username@server`


### cs246 push

**Usage:** `cs246 push ['path' ...]`

**Description:** Copies all specified files and folders from remote cshome to local cshome. If you do not specify any file paths, the entire local cshome will be pushed. It will not delete files on the remote if you have deleted them on local. File paths must be relative to cshome.


### cs246 pull

**Usage:** `cs246 pull ['path' ...]`

**Description:** Copies all specified files and folders from the remote cshome to your local cshome. If you do not specify any file paths, the entire remote cshome will be pulled. It will not delete files on your local if you have deleted them on the remote. File paths must be relative to cshome.


### cs246 diff

**Usage:** `cs246 diff`

**Description:** Produces an output describing the difference between the local and remote cshomes. `l: file` denotes that the file only exists locally, `r: file` denotes that the file only exists remotely, and `d: file` denotes that the files differ between the local and remote.


### cs246 sync

**Usage:** `cs246 sync`

**Description:** Allows user to sync files that differ between the remote and local. You will be prompted to either take the remote (r) version, take the local version (l), or ignore the difference (i).

**Note:** Currently this command is a buggy and has trouble working with directories.
