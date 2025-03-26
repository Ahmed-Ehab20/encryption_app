#!/usr/bin/env python3
"""Test script for dictionary-attack.py."""

import sys
import os
import subprocess
import json

def main():
    """Run dictionary-attack.py with example text."""
    # Test examples
    examples = [
        {
            "name": "Example 1 (Python Key)",
            "ciphertext": "lcejczt rh tm ftaklh gtvm.",
            "expected_key": "python",
            "expected_plaintext": "welcome to my secret text."
        },
        {
            "name": "Example 2 (Hello Key)",
            "ciphertext": "Altd hlbe tg lrncmwxpo kpxs evl ztrsuicp qptspf.",
            "expected_key": "hello", 
            "expected_plaintext": "This text is encrypted with the vigenere cipher."
        }
    ]
    
    # Get specific example from command line if provided
    example_index = 0
    if len(sys.argv) > 1 and sys.argv[1].isdigit():
        example_index = int(sys.argv[1]) - 1
        if example_index < 0 or example_index >= len(examples):
            example_index = 0
    
    # Use custom ciphertext if provided instead of an example index
    custom_text = None
    if len(sys.argv) > 1 and not sys.argv[1].isdigit():
        custom_text = sys.argv[1]
        
    if custom_text:
        # Run with custom text
        run_dictionary_attack(custom_text)
    else:
        # Run with selected example
        example = examples[example_index]
        print(f"\nTesting {example['name']}")
        print(f"Ciphertext: {example['ciphertext']}")
        print(f"Expected Key: {example['expected_key']}")
        print(f"Expected Plaintext: {example['expected_plaintext']}")
        run_dictionary_attack(example['ciphertext'])


def run_dictionary_attack(text):
    """Run the dictionary attack on the given text."""
    # Call dictionary-attack.py with the text
    try:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        attack_script = os.path.join(script_dir, "dictionary-attack.py")
        
        # Run the script
        print(f"\nRunning dictionary attack on: {text}")
        process = subprocess.run(
            ["python", attack_script, text],
            capture_output=True,
            text=True,
            check=True
        )
        
        # Process the output
        if process.stdout:
            try:
                results = json.loads(process.stdout)
                print("\nResults found:")
                print("==============")
                
                for i, result in enumerate(results, 1):
                    print(f"\nResult {i}:")
                    print(f"  Key: {result['key']}")
                    print(f"  Score: {result['score']}%")
                    print(f"  Valid Word Ratio: {result['validWordRatio']}")
                    print(f"  Decrypted: {result['decrypted']}")
                    
                # Check for special keys
                for special_key in ["python", "hello"]:
                    found = any(r['key'] == special_key for r in results)
                    if found:
                        print(f"\n✓ Dictionary attack successfully found the '{special_key}' key!")
                
            except json.JSONDecodeError:
                print("Error parsing JSON output:")
                print(process.stdout)
        else:
            print("No output received from dictionary attack")
            
        if process.stderr:
            print("\nErrors/Warnings:")
            print(process.stderr)
            
    except subprocess.CalledProcessError as e:
        print(f"Error running dictionary attack: {e}")
        if e.stdout:
            print(f"Output: {e.stdout}")
        if e.stderr:
            print(f"Error: {e.stderr}")
    except Exception as e:
        print(f"Unexpected error: {e}")

if __name__ == "__main__":
    main() 