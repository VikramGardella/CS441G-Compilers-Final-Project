#!/bin/bash
################################################################
# Testing script for cs441 complier project (zp language)
#
# AUTHOR
#   CS 441 course CS-UK 
#
# REVISION HISTORY
#   DEC.15.2010 (BJG) Initial Version
#   DEC.01.2011 (JWJ) Adjustements
#   DEC.04.2012 (NFM) Modify to use the interpreter (calc3a.exe)
#                      if no compiler was found.
#                     Test for expected stderr differently.
#                      Tests that are expected to produce error
#                       messages should now have a *_expected.err
#                       file instead of _expected.out .
#                     Handle "questionable" results.
#                      I.e., where the output is correct, but there
#                       are error messages.
#                     Use unified (-u) diffs.
#                     Swap the direction of diffs (so - lines are
#                      "missing", + are "extra").
#                     Indent and color diff output.
#                     Remove color codes from the main program.
#                     Report number and list of failed tests.
#   NOV.25.2015 (JWJ) Numerous minor adjustements
#   NOV.29.2017 (JWJ) Numerous minor adjustements for Z+ project
#
# DESCRIPTION
# This script should be in the directory where zp2pstack or zp2pstack
# is located.
# The first variable 'testdir' (default directory 'tests-interpreter',
# if no directory provided as argument to 'test-interpreter.sh') is where the test files are
# located, this script finds all .cal files within that
# directory and executes them and checks either their output or
# their error messages against an expected output file. The
# expected output file should have the same name as the test
# case, but with ".cal" replaced with ".cal_expected.out" (to
# test the output of the interpreted program) or "_expected.err"
# (to test the stderr output of the compiler). These
# expected outputs are generated by the user as they are used
# to make sure that the tests match the expected output.
################################################################

testdir=${1:-instructorTESTS}

# Execute a particular test.  Should print the results of execution
# to stdout, and any error messages from the compiler to stderrr.
execute () {
  local testfile="$1";

  # Run the compiler if we have it.
  if [ -x ./compiler ] && [ -x ./pstack/api ]; then
    ./compiler  "$testfile" calc_out.apm  >&2 &&
    ./pstack/api calc_out
  # Otherwise, run the intepreter.
  else
    #./zp2pstack.exe < "$testfile"
    ./pass2i < "$testfile"
  fi
}

# Functions to print colour codes. tput interfaces with the terminfo library.
plain () { tput sgr0; }     # Reset to default foreground/background, no bold.
bold ()  { tput bold; }     # Turn on bold, do not change colors.
red ()   { tput setaf 1; }  # Red foreground.
green () { tput setaf 2; }  # Green foreground.
brown () { tput setaf 3; }  # Brown (dark yellow) foreground.
ltred ()   { bold; red; }   # Bold red.
ltgreen () { bold; green; } # Bold green.
yellow ()  { bold; brown; } # Bold brown = yellow.

# Display a unified diff indented three spaces, with additions in green
# and deletions in red.
showdiff () {
  local difffile="$1"
  sed -e "s/^+.*/$(green)&$(plain)/ ;
          s/^-.*/$(red)&$(plain)/ ;
          s/^/   /" "$difffile"
}

# Variables for the next four functions: count of good, bad, and
# questionable tests, and lists of names of bad and questionable tests.
numgood=0
numbad=0
numquestionable=0
bads=()
questionables=()

# Mark that a test succeeded, failed, or had a questionable result.
# Each of these functions takes the test name as its first argument.
# questionable() takes an optional additional message as its second
# argument.
success() {
  local testname="$1" # unused
  echo "  --> $(ltgreen)Success!$(plain)"
  let ++numgood
}
failure() {
  local testname="$1"
  echo "  --> $(ltred)Failure:$(plain)"
  let ++numbad
  bads+=("$testname")
}
questionable() {
  local testname="$1"
  local msg="$2"
  echo "  --> $(brown)${msg:-Questionable}:$(plain)"
  let ++numquestionable
  questionables+=("$testname")
}
# Summarize number of good/bad/questionable test results, and list again the
# tests with bad or questionable results.
summarize() {
  echo -n "$(ltgreen)$numgood good$(plain), "
  echo -n "$(ltred)$numbad bad$(plain), "
  echo    "$(brown)$numquestionable questionable$(plain)"

  if (( numbad > 0 )); then
    echo -n " --> Failed tests:$(ltred)"
    printf " %s" "${bads[@]}"
    echo "$(plain)"
  fi

  if (( numquestionable > 0 )); then
    echo -n " --> Possibly failed tests:$(brown)"
    printf " %s" "${questionables[@]}"
    echo "$(plain)"
  fi
}


## MAIN SCRIPT

bold
echo "Remember that if you've changed anything in the compiler"
echo "code then you need to recompile!"
plain

# For each .zp file in the test directory
for f in $testdir/*.zp
do
  # Find the test name (test-#)
  base=${f%.zp}
  testname=${base##*/}
  # Build the expected file name
  expected=${base}.zp_expected.out
  expected_err=${base}.zp_expected.err

  echo "--> Executing $testname..."
  execute "$f" > zp2pstack.out 2> zp2pstack.err

  # Check diff's return value
  if [ -r "$expected_err" ]; then
   echo " --> Checking for expected errors/messages..."
     if diff -u "$expected_err" zp2pstack.err > zp2pstack.err.diff; then
       success "$testname"
     else
       failure "$testname"
       echo "  --> Diff results:"
       showdiff zp2pstack.err.diff
     fi
   fi
   #else
if [ -r "$expected" ]; then
    echo " --> Checking output..."
    if diff -u "$expected" zp2pstack.out > zp2pstack.out.diff; then
      # Output was correct but there may have been extra errors.
      if [ -s zp2pstack.err ]; then
        questionable "$testname" "Correct but with compiler/error messages"
      fi
     fi
    else
      failure "$testname"
      echo "  --> Diff results:"
      # Indent the diff results and error messages
      showdiff zp2pstack.out.diff
   fi

    # Print error messages if there were any.
    if [ -s zp2pstack.err ]; then
      echo "  --> Compiler/Error messages:"
      sed -e 's/^/   /' zp2pstack.err
    fi

  echo
done

# Remove temporaries
echo "--> Removing temporary files..."
rm -f zp2pstack.out zp2pstack.err zp2pstack.out.diff zp2pstack.err.diff

echo
echo -n "--> Testing has finished: "
summarize

