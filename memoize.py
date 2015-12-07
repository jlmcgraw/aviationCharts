#!/usr/bin/python

import sys
import os
import os.path
import re
import md5
import tempfile
import cPickle
from getopt import getopt
import subprocess
import argparse
__author__ = 'nixCraft'
 

opt_use_modtime = False
#Directories to monitor
opt_dirs = ['.']
#Directories to ignore
ignore_dirs = []

def set_use_modtime(use):
    opt_use_modtime = use

def md5sum(fname):
    try: 
        data = file(fname).read()
    except: 
        data = None

    if data == None: 
        return 'bad'
    else: 
        return md5.new(data).hexdigest()

def modtime(fname):
    try: 
        return os.path.getmtime(fname)
    except: 
        return 'bad'

def files_up_to_date(files):
    for (fname, md5, mtime) in files:
        if opt_use_modtime:
            if modtime(fname) <> mtime: 
                print 'MEMOIZE File modtime changed: ', fname
                return False
        else:
            if md5sum(fname) <> md5:
                print 'MEMOIZE File md5 changed: ', fname
                return False
    return True

def is_relevant(fname):
    path1 = os.path.abspath(fname)
    
    #Do we want to ignore this directory and its subdirectories?
    for d in ignore_dirs:
        path2 = os.path.abspath(d)
        if path1.startswith(path2): 
            #print 'Ignoring: ', path1
            return False
        
    #Do we want to specifically include this directory and its subdirectories?    
    for d in opt_dirs:
        path2 = os.path.abspath(d)
        if path1.startswith(path2):
            #print 'Including: ', path1
            return True
        
    #Default is to ignore the file
    return False

def generate_deps(cmd):
    #print 'Memoize running: ', cmd

    outfile = tempfile.mktemp()
    
    #Escape single quotes
    #This is a fix for one file with a ' in the name (O'Hare), not sure if
    #it's generally a good idea
    cmdreplaced=cmd.replace("\'", "\\\'")

    #Run the command under strace to capture which files the command uses
    os.system("strace -f -o %s -e trace=open,stat64,exit_group %s" % (outfile, cmdreplaced))
    
    #using subprocess
    #subprocess.call("strace -f -o %s -e trace=open,stat64,exit_group %s" % (outfile, cmd), shell=False)
    
    #or try with raw string
    #os.system(r'strace -f -o %s -e trace=open,stat64,exit_group %s' % (outfile, cmd))
    
    #Read the strace output and remove the tempfile
    output = file(outfile).readlines()
    os.remove(outfile)

    status = 0
    files = []
    files_dict = {}
    for line in output:
        match1 = re.match(r'.*open\("(.*)", .*', line)
        match2 = re.match(r'.*stat64\("(.*)", .*', line)

        if match1:
            match = match1
        else:
            match = match2

        if match:
            #Get the name of the open'd or stat64'd file
            fname = os.path.normpath(match.group(1))
            if (is_relevant(fname) and os.path.isfile(fname) and not files_dict.has_key(fname)):
                #Add this file's MD5 and datestamp to our dictionary
                files.append((fname, md5sum(fname), modtime(fname)))
                files_dict[fname] = True

        #Get the exit code from strace output if it exists
        match = re.match(r'.*exit_group\((.*)\).*', line)
        if match:
                #Use that for our return code
                status = int(match.group(1))

    return (status, files)

def read_deps(depsname):
    try: 
        f = file(depsname, 'rb')
    except:
        f = None

    if f:
        deps = cPickle.load(f)
        f.close()
        return deps
    else:
        return {}

def write_deps(depsname, deps):
    f = file(depsname, 'wb')
    cPickle.dump(deps, f)
    f.close()
    
def memoize_with_deps(depsname, deps, cmd):
    #Get the files for this command, no_deps_for_this_command being a default if no key exists
    files = deps.get(cmd, [('no_deps_for_this_command', '', '')])
    
    #print 'Files used:', files
    #Check the status of all of this command's files
    #If they aren't up to date...
    if not files_up_to_date(files):
        #Run the command and collect list of files that it opens
        (status, files) = generate_deps(cmd)
        
        #If the command was successful..
        if status == 0:
            #All the files list to the dictionary
            deps[cmd] = files
        elif deps.has_key(cmd):
            #Delete the key if the command was unsuccessful
            del deps[cmd]
        
        #Write out the dictionary of opened files for this command
        write_deps(depsname, deps)
        return status
    else:
        print 'MEMOIZE Up to date:', cmd
        return 0


def memoize(cmd):
    default_depsname = '.deps'
    default_deps = read_deps(default_depsname)
    return memoize_with_deps(default_depsname, default_deps, cmd)

def usage():
    print ' -------------------------------------------------------------------------'
    print ' memoize'
    print ' -h help'
    print ' -t use modtime instead of default md5 to detect changes'
    print ' -d Additional directories to monitor'
    print ' -i Directories to ignore'
    print ' -------------------------------------------------------------------------'
    sys.exit(' ')
    
if __name__ == '__main__':
    ##Need to figure out how to use argparse
    #parser = argparse.ArgumentParser(description='memoize any program or command')
    #parser.add_argument('-t','--timestamps',  action='store_true', help='Use timestamps instead of MD5',required=False)
    #parser.add_argument('-d','--directory', help='Monitor this directory and its subdirectories', required=False)
    #parser.add_argument('-i','--ignore', help='Ignore this directory and its subdirectories', required=False)
    #parser.add_argument('cmd')
    #args = parser.parse_args()
    ##The command to memoize
    #if not cmd:
        #print ("Need a command to memoize")
        #sys.exit(2)
    #### show values ##
    ##print ("cmd: %s" % args.cmd )
    ##sys.exit(2)
    
    #Old style getopts
    try:
        (opts, cmd) = getopt(sys.argv[1:], 'h:td:i:')
    except getopt.GetoptError as err:
        # print help information and exit:
        print str(err) # will print something like "option -a not recognized"
        usage()
        sys.exit(2)
   
    #The command to memoize
    if not cmd:
        print ("Need a command to memoize")
        sys.exit(2)
    
    #Add a space to beginning of cmd
    cmd = ' '.join(cmd)
    
    for (opt, value) in opts:
        if opt == '-t': 
            opt_use_modtime = True
        elif opt == '-d': 
            opt_dirs.append(value)
        elif opt == '-i': 
            ignore_dirs.append(value)
        else:
            assert False, "unhandled option"
            
    status = memoize(cmd)
    sys.exit(status)
