import os
import shutil
import sys
import subprocess
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
        # "Compatibility Patches",
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

    # 6) Run localization make.py script
    localization_script = script_dir / "localization" / "make.py"
    if localization_script.exists():
        setup_logging("Running localization script...")
        try:
            subprocess.run([sys.executable, str(localization_script)], check=True)
            setup_logging("Localization script completed successfully")
        except subprocess.CalledProcessError as e:
            setup_logging(f"Error running localization script: {str(e)}")
            raise

    # 7) Remove .w3strings files from build/mod_hoodsSwitchableCloak/content
    content_dir = build_dir / "mod_hoodsSwitchableCloak" / "content"
    if content_dir.exists():
        for w3strings_file in content_dir.rglob("*.w3strings"):
            w3strings_file.unlink()
            setup_logging(f"Removed .w3strings file: {w3strings_file.relative_to(content_dir)}")

    # 8) Copy .w3strings files from localization/out to build/mod_hoodsSwitchableCloak/content
    localization_out = script_dir / "localization" / "out"
    if localization_out.exists():
        for w3strings_file in localization_out.glob("*.w3strings"):
            dst_file = content_dir / w3strings_file.name
            shutil.copy2(w3strings_file, dst_file)
            setup_logging(f"Copied .w3strings file: {w3strings_file.name}")
    else:
        setup_logging("Warning: Localization output directory not found")

    print("\n[BUILD] Done! Build process completed successfully.")
    input()

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        setup_logging(f"Error: {str(e)}")
        input("\nPress Enter to exit...")  # Keeps console window open if double-clicked