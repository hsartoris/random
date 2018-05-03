#!/usr/bin/env python3

"""
Put file(s) on lab computers.
Without any arguments, runs in interactive mode.

Usage:
    fileDrop [--interactive]
    fileDrop <file>... [--user=<user>] [--targetDir=<targetDir>] 
        [--hosts=<hostnameFmt>] [--from=<minIdx>] [--to=<maxIdx] 
        [--admin=<admin>]
    fileDrop -h | --help

Options:
    -h --help                   Show this screen
    --interactive               Run in interactive mode [default: True]
    <file>...                   File(s) to send
    --user=<user>         User to give files to
    --targetDir=<targetDir>     Directory to place files in within target user's
                                home directory, e.g. Desktop/folder
    --hosts=<hostnameFmt>       Hostname format. Use # to indicate replacement 
                                with number, e.g. rkc100-##.bard.edu
    --from=<minIdx>             Minimum host index [default: 1]
    --to=<maxIdx>               Maximum host index [default: 20]
    --admin=<admin>             Account to ssh as [default: sysadmin]
"""

__version__     = ".01"

__author__      = "Hayden Sartoris"
__email__       = "hsartoris@gmail.com"
__maintainer__  = "Hayden Sartoris"
__status__      = "alpha"

import sys, os, shutil, warnings
import subprocess, base64
from docopt import docopt

def getDefaults():
    return { "hosts":"rkc100-##.bard.edu", "from":1, "to":20, 
            "targetDir":"Desktop/", "interactive":True, "admin":"sysadmin", 
            "user":"sc150" }

def processArguments(arguments):
    params = getDefaults()
    for key, _ in params.items():
        if arguments['--' + key]:
            params[key] = arguments['--' + key]
    try:
        params['from'] = int(params['from'])
        params['to'] = int(params['to'])
    except ValueError:
        warnings.warn("Bad index format.")
        if type(params['from']) is str:
            params['from'] = None
        else:
            params['to'] = None
    return params

def getTargetDir(params):
    targetDir = input("Enter a target directory: ") or None
    if targetDir is None:
        print("No directory entered; exiting")
        exit()

    params['targetDir'] = targetDir

def generateScript2(params):
    script = "cd /Users/" + params['user'] + "/; "
    script += "su " + params['user'] + " << EOSU; "
    script += ('if [ -d "' + params['targetDir'] + '" ]; then cd ' + 
        params['targetDir'] + '; ')
    script += ('else mkdir -p' + params['targetDir']  + ' && cd ' + 
        params['targetDir'] + '; fi; ')
    script += 'curl -O ' + params['fileURL'] + '; '
    script += 'unzip files.zip; '
    script += 'rm files.zip; '
    script += "exit; EOSU"
    return script

def generateScript(params):
    script = "#!/bin/bash\n"
    script += "cd /Users/" + params['user'] + "/\n"
    script += "su " + params['user'] + " << EOSU\n"
    script += ('if [ -d "' + params['targetDir'] + '" ]; then\n\tcd ' + 
        params['targetDir'] + '\n')
    script += ('else\n\tmkdir -p' + params['targetDir']  + '\n\tcd ' + 
        params['targetDir'] + '\nfi\n')
    script += 'curl -O ' + params['fileURL'] + '\n'
    script += 'unzip files.zip\n'
    script += 'rm files.zip\n'
    script += "exit\nEOSU"
    return script

def getInt(prompt, default):
    val = None
    while True:
        try:
            val = int(input(prompt + " [" + str(default) + "] ") or default)
        except ValueError:
            print("Not an integer value; please try again.")
        if val: return val

def getFilename(num = None):
    prompt = "Enter name of file " + (str(num) if num else "") + ": "
    while True:
        fname = input(prompt)
        if fname == '':
            print("Please enter something")
            continue
        if os.path.exists(fname):
            print("Found " + fname)
            return fname
        else:
            print("Could not locate " + fname + ".")

def processFiles(files):
    print("Zipping files...")
    os.mkdir("tmp")
    for fname in files:
        shutil.copy(fname, "tmp/")
    try:
        subprocess.call(['zip', 'rj', 'files.zip', 'tmp'])
    except Exception:
        print("Error zipping, cleaning up and exiting")
        shutil.rmtree("tmp/")
        sys.exit(1)

    shutil.rmtree("tmp/")
    print("Zipped files, uploading...")
    try:
        fileURL = subprocess.check_output(['curl', '--upload-file', 
            './files.zip', 'https://transfer.sh/files.zip'])
    except Exception:
        print("Error uploading files; exiting")
        sys.exit(1)
    fileURL = str(fileURL)[2:-1]
    print("Uploaded files to " + fileURL)
    return fileURL

def updateParam(key, prompt, params):
    if type(params[key]) is int:
        params[key] = getInt(prompt, params[key])
    else:
        params[key] = input(prompt + " [" + params[key] + "] ") or params[key]

def interactiveUpdate(params):
    print("Let's move some files.")
    numFiles = getInt("How many files do you want to transfer?", 1)
    files = []
    for i in range(numFiles):
        files.append(getFilename(i+1))
    updateParam('targetDir', "Directory to put files in:", params)
    updateParam('user', "User to send files to:", params)
    updateParam('admin', "User to ssh as:", params)
    updateParam('hosts', "Hostname format:", params)
    updateParam('from', "First host index:", params)
    updateParam('to', "Last host index:", params)
    params['fileURL'] = processFiles(files)

def sendFiles(params):
    numLen = params['hosts'].count("#")
    hostname = params['hosts'].split("#")
    hosts = []
    script = generateScript(params)
    print("Script: ")
    print(script)
    encodedScript = base64.b64encode(script.encode())
    #cmd = '"echo ' + encodedScript + ' | base64 -D | sudo bash"'
    for i in range(params['from'], params['to'] + 1):
        hosts.append(hostname[0] + ("0"*(numLen-len(str(i)))) + str(i) + 
                hostname[1])
    failed = []
    for host in hosts:
        print("Connecting to host: " + host)
        try:
            subprocess.check_output(['ping', '-c', '1', host])
            subprocess.check_output(['ssh', '-t', host, cmd])
        except:
            print("Could not connect to host " + host)
            failed.append(host)



def main():
    if len(sys.argv) == 1:
        params = getDefaults()
        interactiveUpdate(params)
    else:
        print("Only interactive mode available right now")
        sys.exit(1)
        #params = processArguments(docopt(__doc__))

if __name__ == "__main__":
    main()
