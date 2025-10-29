#!/bin/bash

# Script to process tax column in CSV file
# Converts valid decimals (0-1 with max 2 decimal places) to percentages
# Replaces non-numeric values with N/A
# Replaces numeric but invalid values with invalid_value

INPUT_FILE="${1:-data.csv}"
OUTPUT_FILE="${2:-processed.csv}"

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found!"
    exit 1
fi

echo "Processing tax column in $INPUT_FILE..."
echo "Output will be saved to $OUTPUT_FILE"
echo ""

# Save header
head -n 1 "$INPUT_FILE" > "$OUTPUT_FILE"

# Process data rows using awk
tail -n +2 "$INPUT_FILE" | awk -F',' 'BEGIN {
    OFS = ","
    valid_count = 0
    invalid_numeric_count = 0
    non_numeric_count = 0
}
{
    # Store original tax value
    original_tax = $3

    # Remove spaces
    gsub(/^[ \t]+|[ \t]+$/, "", $3)
    tax = $3

    # Process based on content
    if (tax == "") {
        # Empty field
        $3 = "N/A"
        non_numeric_count++
    }
    else if (tax !~ /^-?[0-9]*\.?[0-9]+$/ && tax !~ /^-?[0-9]+\.?$/) {
        # Not a number
        $3 = "N/A"
        non_numeric_count++
    }
    else if (tax ~ /^(0(\.[0-9]{1,2})?|1(\.0{1,2})?)$/) {
        # Valid tax (0-1 with max 2 decimals)
        if (tax ~ /^1(\.0{1,2})?$/) {
            $3 = "100%"
        }
        else if (tax ~ /^0(\.0{1,2})?$/) {
            $3 = "0%"
        }
        else {
            percentage = tax * 100
            $3 = sprintf("%.0f%%", percentage)
        }
        valid_count++
    }
    else {
        # Numeric but invalid
        $3 = "invalid_value"
        invalid_numeric_count++
    }

    print $0
}
END {
    print "\n=== Processing Summary ===" > "/dev/stderr"
    print "Total rows processed: " NR > "/dev/stderr"
    print "Valid tax values converted to %: " valid_count > "/dev/stderr"
    print "Invalid numeric values → invalid_value: " invalid_numeric_count > "/dev/stderr"
    print "Non-numeric values → N/A: " non_numeric_count > "/dev/stderr"
}' >> "$OUTPUT_FILE"

echo ""
echo "Processing complete!"
echo ""
echo "Sample of processed data (first 10 rows):"
head -n 11 "$OUTPUT_FILE" | column -t -s ','