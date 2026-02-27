#!/usr/bin/env python3
import os
import re
import sys

# Define regex patterns for potential PII items
patterns = {
    "Email": re.compile(r"[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+"),
    "SSN": re.compile(r"\b\d{3}-\d{2}-\d{4}\b"),
    "Phone": re.compile(r"\b(?:\+?1[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b")
}

def scan_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            contents = f.read()
    except Exception as e:
        return []
    findings = []
    for label, pattern in patterns.items():
        for match in pattern.finditer(contents):
            findings.append((label, match.group()))
    return findings

def main():
    for root, dirs, files in os.walk('.'):
        for name in files:
            # Skip this script file
            if name == 'pii_scanner.py':
                continue
            filepath = os.path.join(root, name)
            findings = scan_file(filepath)
            if findings:
                print(f"Potential PII in {filepath}:")
                for label, value in findings:
                    print(f"  {label}: {value}")
                print()

if __name__ == '__main__':
    main()
