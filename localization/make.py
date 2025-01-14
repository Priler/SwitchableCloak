import os
import shutil
import subprocess
import glob
import sys
import time

def print_status(message):
    """Print status message with timestamp"""
    print(f"[{time.strftime('%H:%M:%S')}] {message}")

def cleanup_out_directory(out_dir):
    """Clean up the out directory by removing all existing files"""
    if os.path.exists(out_dir):
        for file in os.listdir(out_dir):
            file_path = os.path.join(out_dir, file)
            try:
                if os.path.isfile(file_path):
                    os.remove(file_path)
                    print_status(f"Removed old file: {file_path}")
            except OSError as e:
                print_status(f"Error removing file {file_path}: {str(e)}")

def cleanup_working_directory():
    """Clean up .ws and .w3strings files in the current directory"""
    patterns = ['*.ws', '*.w3strings']
    for pattern in patterns:
        for file_path in glob.glob(pattern):
            try:
                os.remove(file_path)
                print_status(f"Removed file: {file_path}")
            except OSError as e:
                print_status(f"Error removing file {file_path}: {str(e)}")

def main():
    # Get the directory where the script is located
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)
    print_status(f"Working directory: {script_dir}")

    # Create or clean output directory
    out_dir = 'out'
    os.makedirs(out_dir, exist_ok=True)
    print_status("Cleaning output directory...")
    cleanup_out_directory(out_dir)

    # Read the ID space from file
    try:
        with open('id-space.txt', 'r') as f:
            id_space = int(f.read().strip())
            print_status(f"Read ID space: {id_space}")
    except FileNotFoundError:
        print_status("Error: id-space.txt not found")
        return
    except ValueError:
        print_status("Error: Invalid number in id-space.txt")
        return

    # Execute w3strings commands
    commands = [
        f'w3strings.exe -e en --id-space {id_space}',
        f'w3strings.exe -e ru --id-space {id_space}'
    ]

    for cmd in commands:
        print_status(f"Executing: {cmd}")
        try:
            subprocess.run(cmd, shell=True, check=True)
        except subprocess.CalledProcessError as e:
            print_status(f"Error executing command: {cmd}")
            print_status(f"Error details: {str(e)}")
            return

    # List of all files to be placed in out directory
    target_files = [
        'ar.w3strings', 'br.w3strings', 'cn.w3strings', 'cz.w3strings',
        'de.w3strings', 'es.w3strings', 'esmx.w3strings', 'fr.w3strings',
        'hu.w3strings', 'it.w3strings', 'jp.w3strings', 'kr.w3strings',
        'pl.w3strings', 'tr.w3strings', 'zh.w3strings'
    ]

    # Add the original en and ru files to be moved
    source_files = ['en.w3strings', 'ru.w3strings']

    # First, check if source files exist
    print_status("Checking for source files...")
    if not all(os.path.exists(f) for f in source_files):
        print_status("Error: One or more source files (en.w3strings, ru.w3strings) not found")
        return

    # Move the original en and ru files to out directory
    print_status("Moving source files to output directory...")
    for source in source_files:
        target_path = os.path.join(out_dir, source.replace('w3strings', 'w3strings'))
        try:
            shutil.copy2(source, target_path)
            print_status(f"Copied {source} to {target_path}")
        except IOError as e:
            print_status(f"Error copying {source} to out directory: {str(e)}")
            return

    # Create copies of en.w3strings for other languages
    print_status("Creating language copies...")
    source_file = 'en.w3strings'
    for target in target_files:
        try:
            target_path = os.path.join(out_dir, target)
            shutil.copy2(source_file, target_path)
            print_status(f"Created {target}")
        except IOError as e:
            print_status(f"Error copying to {target}: {str(e)}")

    # Final cleanup of working directory
    print_status("Performing final cleanup...")
    cleanup_working_directory()

    print_status("Script completed successfully!")

if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        print_status(f"Unexpected error occurred: {str(e)}")
    finally:
        # Keep the window open
        print("\nPress Enter to exit...")
        input()