import os
import shutil
import sys
from pathlib import Path

def get_script_directory():
    """Get the directory where the script is located, works with both double-click and command line."""
    if getattr(sys, 'frozen', False):
        # Running as executable
        return Path(sys.executable).parent
    else:
        # Running as script
        return Path(__file__).parent

def setup_logging(message):
    """Print a formatted log message."""
    print(f"[BUILD] {message}")

def main():
    # Get the script's directory
    script_dir = get_script_directory()
    setup_logging(f"Working directory: {script_dir}")

    # Define build directory path
    build_dir = script_dir / "build"

    # 1) Create build folder if it doesn't exist
    build_dir.mkdir(exist_ok=True)
    setup_logging("Created build directory")

    # 2) Remove all files/folders inside build directory
    if build_dir.exists():
        for item in build_dir.iterdir():
            if item.is_file():
                item.unlink()
                setup_logging(f"Removed file: {item.name}")
            elif item.is_dir():
                shutil.rmtree(item)
                setup_logging(f"Removed directory: {item.name}")

    # 3) Copy specified files
    files_to_copy = [
        "HowToInstall.txt",
        "SwitchableCloak.input.settings"
    ]
    
    for file in files_to_copy:
        src = script_dir / file
        dst = build_dir / file
        if src.exists():
            shutil.copy2(src, dst)
            setup_logging(f"Copied file: {file}")
        else:
            setup_logging(f"Warning: Source file not found: {file}")

    # 4) Copy specified folders
    folders_to_copy = [
        "bin",
        "Compatibility Patches",
        "mod_hoodsSwitchableCloak"
    ]
    
    for folder in folders_to_copy:
        src = script_dir / folder
        dst = build_dir / folder
        if src.exists():
            shutil.copytree(src, dst, dirs_exist_ok=True)
            setup_logging(f"Copied directory: {folder}")
        else:
            setup_logging(f"Warning: Source directory not found: {folder}")

    # 5) Copy contents of scripts folder to specific destination
    scripts_src = script_dir / "scripts"
    scripts_dst = build_dir / "mod_hoodsSwitchableCloak" / "content" / "scripts"
    
    if scripts_src.exists():
        scripts_dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(scripts_src, scripts_dst, dirs_exist_ok=True)
        setup_logging("Copied scripts directory contents to target location")
    else:
        setup_logging("Warning: Scripts directory not found")

    print("\n[BUILD] Done! Build process completed successfully.")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        setup_logging(f"Error: {str(e)}")
        input("\nPress Enter to exit...")  # Keeps console window open if double-clicked
