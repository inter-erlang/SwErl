#!/bin/bash

# Define the directory containing the source files
directory="Sources"
# Define the Tests directory
tests_directory="Tests"

# Count lines that start with ///
count_lines_starting_with_triple_slash=$(find "$directory" -type f -name "*.swift" -exec grep -h '^///' {} + | wc -l)

# Count all non-blank lines that do not start with // (excluding lines that start with /// as well) in the Sources directory
count_non_blank_non_double_slash_sources=$(find "$directory" -type f -name "*.swift" -exec grep -hEv '^(//|$)' {} + | wc -l)

# Count all non-blank lines that do not start with // or /// in the Tests directory
count_non_blank_non_double_slash_tests=$(find "$tests_directory" -type f -name "*.swift" -exec grep -hEv '^(///|//|$)' {} + | wc -l)

# Print the results
echo "Number of lines of documentation: $count_lines_starting_with_triple_slash"
echo "Number of lines of code in Sources': $count_non_blank_non_double_slash_sources"
echo "Number of lines of code in Tests': $count_non_blank_non_double_slash_tests"
