#!/usr/bin/python3
# -*- coding: utf-8 -*-

"""memoize a command
Originally from https://github.com/kgaughan/memoize.py with some additions:
    updated to python3
    use sha256 instead of md5
    don't load the whole file to be hashed at once
    also track renames of temporary files
    properly handle commands with spaces/special characters in them    
    follow pylint
    verbosity
    use argparse
    All of this is haphazard because I don't really know python
TODO
    no pylint warnings
"""

import sys
import os
import os.path
import shlex
import re
import hashlib
import tempfile
import pickle
import subprocess
import argparse

__author__ = 'jlmcgraw@gmail.com'

# Should we use modtime as the check for a file being changed (default is hash)

opt_use_modtime = False

# Directories to monitor

opt_dirs = []

# Directories to ignore

ignore_dirs = []

def hash_file(fname):
    """ Return the hash of a file """
    BLOCKSIZE = 65536

    #Which type of hash to use

    hasher = hashlib.sha256()
    try:
        with open(fname, 'rb') as file_to_hash:
            buf = file_to_hash.read(BLOCKSIZE)
            while len(buf) > 0:
                hasher.update(buf)
                buf = file_to_hash.read(BLOCKSIZE)
        return hasher.hexdigest()
    except Exception:
        return None




def modtime(fname):
    """ Return modtime of a given file"""
    try:
        return os.path.getmtime(fname)
    except Exception:
        return 'bad_modtime'



def files_up_to_date(files):
    """ Check the up_to_date status of all files used by this command """
    
    if files == None:
        #print('No files yet')
        return False
    for (fname, hash_digest, mtime) in files:
        if opt_use_modtime:
            if modtime(fname) != mtime:
                #print ('MEMOIZE File modtime changed: ', fname)
                return False
        else:
            if hash_file(fname) != hash_digest:
                #print ('MEMOIZE File hash changed: ', fname)
                return False
    return True




def is_relevant(fname):
    """ Do we want to consider this file as relevant?"""
    path1 = os.path.abspath(fname)

    # Do we want to ignore this directory and its subdirectories?

    if ignore_dirs:
        for ignorable_directory in ignore_dirs:
            path2 = os.path.abspath(ignorable_directory)
            if path1.startswith(path2):

                # print 'Ignoring: ', path1

                return False

    # Do we want to specifically include this directory and its subdirectories?

    for additional_directory in opt_dirs:
        path2 = os.path.abspath(additional_directory)
        if path1.startswith(path2):

            # print 'Including: ', path1

            return True

    # Default is to ignore the file

    return False


def generate_deps(cmd):
    """ Gather dependencies for a command and store their hash and modtime """
    #print ('Memoize running: ', cmd)

    strace_output_filename = tempfile.mktemp()

    # print("strace output saved in ",strace_output_filename)

    wholecmd = \
        'strace -f -o %s -e trace=open,rename,stat64,exit_group %s' \
        % (strace_output_filename, cmd)

    # print(wholecmd)
    subprocess.call(wholecmd, shell=True)


    # Read the strace output and remove the tempfile

    output = open(strace_output_filename).readlines()
    os.remove(strace_output_filename)

    status = 0
    files = []
    files_dict = {}
    for line in output:
        match1 = re.match(r'.*open\("(.*)", .*', line)
        match2 = re.match(r'.*stat64\("(.*)", .*', line)
        match3 = re.match(r'.*rename\(".*", "(.*)"', line)

        if match1:
            match = match1
        elif match2:
            match = match2
        elif match3:
            match = match3
        else:
            match = None

        if match:

            # Get the name of the destination file

            fname = os.path.normpath(match.group(1))

            # print("Matched ",fname)

            if is_relevant(fname) and os.path.isfile(fname) and fname \
                not in files_dict:
                #print ('Is relevant: ', fname)

                # Add this file's MD5 and datestamp to our dictionary
                # and mark that we've seen it already
                files.append((fname, hash_file(fname), modtime(fname)))
                files_dict[fname] = True

        # Get the exit code from strace output if it exists

        match = re.match(r'.*exit_group\((.*)\).*', line)
        if match:

                # Use that for our return code

            status = int(match.group(1))

    return (status, files)


def read_deps(depsname):
    """ Unpickle the dependencies dictionary """
    try:
        pickle_file = open(depsname, 'rb')
    except Exception:
        pickle_file = None

    if pickle_file:
        deps = pickle.load(pickle_file)
        pickle_file.close()
        return deps
    else:
        return {}


def write_deps(depsname, deps):
    """ Pickle the dependencies dictionary to a file """
    pickle_file = open(depsname, 'wb')
    pickle.dump(deps, pickle_file)
    pickle_file.close()


def memoize_with_deps(depsname, deps, cmd):
    """ Run a command if it has no existing dependencies or if they're out of 
    date. Save the captured dependencies
    """
    
    # Get the files used by this command from our stored dictionary

    files = deps.get(cmd)

    if args.verbose:
        print ('Files used:', files)

    # Check the status of all of this command's files

    if files and files_up_to_date(files):
        if args.verbose:
            print ('Up to date:', cmd)
        return 0
    else:

         # Run the command and collect list of files that it opens

        (status, files) = generate_deps(cmd)

        # If the command was successful..

        if status == 0:

            # Add the files list to the dictionary

            deps[cmd] = files
            
        elif cmd in deps:

            # Delete the key if the command was unsuccessful

            del deps[cmd]

        # Write out the dictionary of opened files for this command

        write_deps(depsname, deps)
        return status


if __name__ == '__main__':
    
    #Parse the command line options
    
    parser = argparse.ArgumentParser(description='memoize any program or command')
    parser.add_argument('-t'
                        , '--timestamps'
                        , action='store_true'
                        , help='Use timestamps instead of hash to determine if a file has changed'
                        , required=False)
    parser.add_argument('-d'
                        , '--directory'
                        , action='append'
                        , default=['.']
                        , metavar='DIRECTORY'
                        , help='Monitor this directory and its subdirectories'
                        , required=False
                        )
    parser.add_argument('-i'
                        , '--ignore'
                        , action='append'
                        , metavar='DIRECTORY'
                        , help='Ignore this directory and its subdirectories'
                        , required=False
                        )
    parser.add_argument('-v'
                        ,'--verbose'
                        , help='More output'
                        , action='store_true'
                        , required=False)
    parser.add_argument('-f'
                        , '--filename'
                        , default='.deps3'
                        , help='Filename to store dependency information in'
                        , required=False)
    parser.add_argument("command"
                        , nargs=argparse.REMAINDER
                        , help='The command to memoize')
    args = parser.parse_args()


    # Sort the individual elements of the command.  
    # Good idea or not?: Consider using this as the key
    # so the command could be rearranged without being considered out of date
    
    command_sorted = sorted(args.command)

    
    # Quote all the individual items in command and join them with a space
    # into a string
    command_string = ' '.join(shlex.quote(element) for element in args.command)
    
    if args.verbose:
        print('Command: ', args.command)
        print('Command sorted: ', command_sorted)
        print('Command string: ', command_string)
        print('Ignoring these directory trees: ', args.ignore)
        print('Monitoring these directory trees: ', args.directory)
        print('Using timestamps: ', args.timestamps)
        print('Dependencies file: ', args.filename)
        

    opt_use_modtime = args.timestamps
    opt_dirs = args.directory
    ignore_dirs = args.ignore
    
    default_deps = read_deps(args.filename)
    memoize_status = memoize_with_deps(args.filename, default_deps, command_string)

    sys.exit(memoize_status)

